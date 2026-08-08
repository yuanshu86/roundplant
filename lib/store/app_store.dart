import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/plant.dart';
import '../db/database_helper.dart';
import '../repository/plant_repository.dart';
import '../repository/diary_repository.dart';
import '../services/notification_service.dart';

/// 全局状态管理 — 管理植物列表、任务列表、日记列表、SQLite 持久化
class AppStore extends ChangeNotifier {
  final _db = DatabaseHelper();
  final _plantRepo = PlantRepository();
  final _diaryRepo = DiaryRepository();
  static const _uuid = Uuid();

  List<Plant> _plants = [];
  List<CareTask> _tasks = [];
  List<DiaryEntry> _diaries = [];
  bool _initialized = false;
  bool _isLoading = true;

  List<Plant> get plants => List.of(_plants);
  List<CareTask> get tasks => List.of(_tasks);
  List<DiaryEntry> get diaries => List.of(_diaries);
  bool get isLoading => _isLoading;

  /// 需要浇水的植物数量
  int get wateringCount =>
      _plants.where((p) => p.daysUntilWatering <= 0).length;

  /// 需要任意养护（浇水/施肥/修剪）的植物数量
  int get dueCareCount =>
      _plants.where((p) =>
          p.daysUntilWatering <= 0 ||
          p.daysUntilFertilizing <= 0 ||
          p.daysUntilPruning <= 0).length;

  /// 今日已完成任务数
  int get completedTaskCount =>
      _tasks.where((t) => t.isCompleted).length;

  /// 总积分
  int get totalPoints =>
      _plants.fold(0, (sum, p) => sum + p.points);

  /// 养护植物总数
  int get totalPlants => _plants.length;

  /// 最长连续养护天数
  int get maxCareDays =>
      _plants.fold(0, (max, p) => p.careDays > max ? p.careDays : max);

  /// 初始化 — 从 SQLite 异步加载
  Future<void> init() async {
    if (_initialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 首次启动插入示例数据
      await _plantRepo.seedIfEmpty();
      // 加载植物列表
      _plants = await _plantRepo.getAll();
      // 加载日记列表
      await _loadDiaries();
      // 确保今日任务已生成
      await _ensureTodayTasks();
      // 加载今日任务
      await _loadTodayTasks();
      // 注册本地养护提醒（非侵入：每天仅一条温和提醒）
      try {
        await NotificationService.scheduleDailyReminder(dueCareCount);
      } catch (e) {
        debugPrint('schedule reminder error: $e');
      }
    } catch (e) {
      debugPrint('AppStore init error: $e');
    }

    _isLoading = false;
    _initialized = true;
    notifyListeners();
  }

  /// 为到期但未生成今日任务的植物，按类型（浇水/施肥/修剪）创建任务
  Future<void> _ensureTodayTasks() async {
    for (final plant in _plants) {
      if (plant.daysUntilWatering <= 0 &&
          !await _db.hasTodayTaskOfType(plant.id, 'watering')) {
        await _db.insertTask(
          plantId: plant.id,
          taskType: 'watering',
          title: '给${plant.name}浇水',
          scheduledDate: DateTime.now(),
        );
      }
      if (plant.daysUntilFertilizing <= 0 &&
          !await _db.hasTodayTaskOfType(plant.id, 'fertilizing')) {
        await _db.insertTask(
          plantId: plant.id,
          taskType: 'fertilizing',
          title: '给${plant.name}施肥',
          scheduledDate: DateTime.now(),
        );
      }
      if (plant.daysUntilPruning <= 0 &&
          !await _db.hasTodayTaskOfType(plant.id, 'pruning')) {
        await _db.insertTask(
          plantId: plant.id,
          taskType: 'pruning',
          title: '给${plant.name}修剪',
          scheduledDate: DateTime.now(),
        );
      }
    }
  }

  /// 从数据库加载今日任务
  Future<void> _loadTodayTasks() async {
    final rows = await _db.getTodayTasks();
    _tasks = rows
        .map((row) => CareTask(
              id: row['id'] as String,
              plantId: row['plant_id'] as String,
              plantName: row['plant_name'] as String,
              taskType: row['task_type'] as String,
              title: row['title'] as String,
              scheduledDate: DateTime.parse(row['scheduled_date'] as String),
              isCompleted: (row['is_completed'] as int) == 1,
            ))
        .toList();
  }

  /// 从数据库加载全部日记（JOIN 植物名）
  Future<void> _loadDiaries() async {
    final rows = await _diaryRepo.getAllJoined();
    _diaries = rows.map(DiaryEntry.fromMap).toList();
    _diaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 日记总数
  int get diaryCount => _diaries.length;

  /// 获取某植物的日记列表
  List<DiaryEntry> getDiariesForPlant(String plantId) =>
      _diaries.where((d) => d.plantId == plantId).toList();

  /// 新增日记 — 同步内存 + 异步写库
  void addDiary({
    required String plantId,
    required String imagePath,
    List<String>? extraImagePaths,
    String? note,
  }) {
    final diary = DiaryEntry(
      id: _uuid.v4(),
      plantId: plantId,
      imagePath: imagePath,
      extraImagePaths: extraImagePaths ?? const [],
      note: note,
      createdAt: DateTime.now(),
    );
    _diaries.insert(0, diary);
    notifyListeners();

    () async {
      try {
        await _diaryRepo.insert(diary);
      } catch (e) {
        debugPrint('addDiary persist error: $e');
      }
    }();
  }

  /// 获取指定植物
  Plant? getPlant(String id) {
    for (final p in _plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// 浇水 — 更新植物 + 记录浇水历史 + 标记任务完成
  void waterPlant(String plantId) {
    final idx = _plants.indexWhere((p) => p.id == plantId);
    if (idx == -1) return;

    final now = DateTime.now();
    _plants[idx] = _plants[idx].copyWith(
      lastWatered: now,
      nextWatering: now.add(Duration(days: _plants[idx].wateringFrequency)),
      healthStatus: '健康',
      careDays: _plants[idx].careDays + 1,
      points: _plants[idx].points + 5,
    );
    final updatedPlant = _plants[idx];

    // 标记对应任务完成
    final taskIdx =
        _tasks.indexWhere((t) => t.plantId == plantId && !t.isCompleted);
    String? taskId;
    if (taskIdx != -1) {
      _tasks[taskIdx].isCompleted = true;
      taskId = _tasks[taskIdx].id;
    }

    notifyListeners();

    // 异步持久化 (fire-and-forget，UI 已即时更新)
    () async {
      try {
        await _plantRepo.update(updatedPlant);
        await _db.insertWateringRecord(plantId, now);
        if (taskId != null) await _db.completeTask(taskId);
        // 自动添加浇水日记
        final diary = DiaryEntry(
          id: _uuid.v4(),
          plantId: plantId,
          imagePath: '',
          note: '给${updatedPlant.name}浇了水',
          createdAt: now,
        );
        await _diaryRepo.insert(diary);
        _diaries.insert(0, diary);
        notifyListeners();
      } catch (e) {
        debugPrint('waterPlant persist error: $e');
      }
    }();
  }

  /// 切换任务完成状态（仅完成，不可取消 — 养护操作不可撤销）
  void toggleTask(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final task = _tasks[idx];
    if (task.isCompleted) return; // 已完成，不可取消

    _applyCare(task.plantId, task.taskType, taskId);
  }

  /// 详情页快捷完成某类养护（可能暂无对应任务）
  void markCare(String plantId, String taskType) {
    _applyCare(plantId, taskType, null);
  }

  /// 统一的养护完成逻辑：更新植物周期 → 标记/创建任务 → 写日记
  void _applyCare(String plantId, String taskType, String? taskId) {
    final pIdx = _plants.indexWhere((p) => p.id == plantId);
    if (pIdx == -1) return;

    final now = DateTime.now();
    final (updated, action) = _applyCareUpdate(_plants[pIdx], taskType, now);
    _plants[pIdx] = updated;

    // 标记对应类型的今日任务完成
    final tIdx = _tasks.indexWhere(
        (t) => t.plantId == plantId && t.taskType == taskType && !t.isCompleted);
    if (tIdx != -1) _tasks[tIdx].isCompleted = true;

    notifyListeners();

    () async {
      try {
        await _plantRepo.update(updated);
        if (taskType == 'watering') {
          await _db.insertWateringRecord(plantId, now);
        }
        if (taskId != null) {
          await _db.completeTask(taskId);
        } else if (tIdx != -1) {
          await _db.completeTask(_tasks[tIdx].id);
        }
        // 自动添加养护日记
        final diary = DiaryEntry(
          id: _uuid.v4(),
          plantId: plantId,
          imagePath: '',
          note: action,
          createdAt: now,
        );
        await _diaryRepo.insert(diary);
        _diaries.insert(0, diary);
        notifyListeners();
      } catch (e) {
        debugPrint('_applyCare persist error: $e');
      }
    }();
  }

  /// 计算某类养护完成后的植物新状态与日记文案
  (Plant, String) _applyCareUpdate(Plant plant, String taskType, DateTime now) {
    switch (taskType) {
      case 'fertilizing':
        return (
          plant.copyWith(
            lastFertilized: now,
            nextFertilizing: now.add(Duration(days: plant.fertilizingFrequency)),
            healthStatus: '健康',
            careDays: plant.careDays + 1,
            points: plant.points + 5,
          ),
          '给${plant.name}施了肥'
        );
      case 'pruning':
        return (
          plant.copyWith(
            lastPruned: now,
            nextPruning: now.add(Duration(days: plant.pruningFrequency)),
            healthStatus: '健康',
            careDays: plant.careDays + 1,
            points: plant.points + 5,
          ),
          '给${plant.name}修剪了'
        );
      default: // watering
        return (
          plant.copyWith(
            lastWatered: now,
            nextWatering: now.add(Duration(days: plant.wateringFrequency)),
            healthStatus: '健康',
            careDays: plant.careDays + 1,
            points: plant.points + 5,
          ),
          '给${plant.name}浇了水'
        );
    }
  }

  /// 添加新植物
  void addPlant(Plant plant) {
    _plants.add(plant);
    notifyListeners();

    () async {
      try {
        await _plantRepo.insert(plant);
        await _ensureTodayTasks();
        await _loadTodayTasks();
        notifyListeners();
      } catch (e) {
        debugPrint('addPlant persist error: $e');
      }
    }();
  }

  /// 更新植物信息（编辑）
  void updatePlant(Plant plant) {
    final idx = _plants.indexWhere((p) => p.id == plant.id);
    if (idx == -1) return;
    _plants[idx] = plant;
    notifyListeners();

    () async {
      try {
        await _plantRepo.update(plant);
        await _loadTodayTasks();
        notifyListeners();
      } catch (e) {
        debugPrint('updatePlant persist error: $e');
      }
    }();
  }

  /// 删除植物
  void removePlant(String id) {
    _plants.removeWhere((p) => p.id == id);
    _tasks.removeWhere((t) => t.plantId == id);
    _diaries.removeWhere((d) => d.plantId == id);
    notifyListeners();

    () async {
      try {
        await _plantRepo.delete(id);
      } catch (e) {
        debugPrint('removePlant persist error: $e');
      }
    }();
  }
}
