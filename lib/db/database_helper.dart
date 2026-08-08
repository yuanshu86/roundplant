import 'dart:io' show Platform;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../models/plant.dart';

/// SQLite 数据库管理单例
/// - Android/iOS: 原生 sqflite
/// - Windows/macOS/Linux: sqflite_common_ffi（桌面调试用）
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;
  static const _dbName = 'circle_plant.db';
  static const _dbVersion = 3;
  static const _uuid = Uuid();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    // 桌面平台初始化 ffi
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, _dbName);

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 植物表
    await db.execute('''
      CREATE TABLE plants (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        scientific_name TEXT DEFAULT '',
        image_path TEXT,
        health_status TEXT DEFAULT '健康',
        watering_frequency INTEGER DEFAULT 7,
        light_requirement TEXT DEFAULT '明亮散射光',
        temperature_range TEXT DEFAULT '18-28°C',
        humidity_range TEXT DEFAULT '50-70%',
        care_days INTEGER DEFAULT 1,
        points INTEGER DEFAULT 0,
        last_watered TEXT,
        next_watering TEXT,
        fertilizing_frequency INTEGER DEFAULT 14,
        last_fertilized TEXT,
        next_fertilizing TEXT,
        pruning_frequency INTEGER DEFAULT 30,
        last_pruned TEXT,
        next_pruning TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 浇水记录表
    await db.execute('''
      CREATE TABLE watering_records (
        id TEXT PRIMARY KEY,
        plant_id TEXT NOT NULL,
        watered_at TEXT NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
      )
    ''');

    // 生长日记表
    await db.execute('''
      CREATE TABLE diary_entries (
        id TEXT PRIMARY KEY,
        plant_id TEXT NOT NULL,
        image_path TEXT NOT NULL,
        extra_image_paths TEXT DEFAULT '[]',
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
      )
    ''');

    // 任务表
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        plant_id TEXT NOT NULL,
        task_type TEXT NOT NULL,
        title TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        completed_at TEXT,
        FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
      )
    ''');

    // 用户设置表
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // ===================== Plants CRUD =====================

  Future<List<Map<String, dynamic>>> getAllPlants() async {
    final db = await database;
    return await db.query('plants', orderBy: 'created_at ASC');
  }

  Future<void> insertPlant(Plant plant) async {
    final db = await database;
    await db.insert('plants', plant.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePlant(Plant plant) async {
    final db = await database;
    await db.update('plants', plant.toMap(),
        where: 'id = ?', whereArgs: [plant.id]);
  }

  Future<void> deletePlant(String id) async {
    final db = await database;
    // 手动级联删除（SQLite 默认不启用外键约束）
    await db.delete('watering_records', where: 'plant_id = ?', whereArgs: [id]);
    await db.delete('diary_entries', where: 'plant_id = ?', whereArgs: [id]);
    await db.delete('tasks', where: 'plant_id = ?', whereArgs: [id]);
    await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== Watering Records =====================

  Future<void> insertWateringRecord(String plantId, DateTime wateredAt) async {
    final db = await database;
    await db.insert('watering_records', {
      'id': _uuid.v4(),
      'plant_id': plantId,
      'watered_at': wateredAt.toIso8601String(),
    });
  }

  Future<List<WateringRecord>> getWateringRecords(String plantId) async {
    final db = await database;
    final rows = await db.query('watering_records',
        where: 'plant_id = ?',
        whereArgs: [plantId],
        orderBy: 'watered_at DESC');
    return rows.map(WateringRecord.fromMap).toList();
  }

  // ===================== Diary =====================

  Future<void> insertDiary(DiaryEntry entry) async {
    final db = await database;
    await db.insert('diary_entries', entry.toMap());
  }

  Future<List<DiaryEntry>> getDiaries(String plantId) async {
    final db = await database;
    final rows = await db.query('diary_entries',
        where: 'plant_id = ?',
        whereArgs: [plantId],
        orderBy: 'created_at DESC');
    return rows.map(DiaryEntry.fromMap).toList();
  }

  /// 获取全部日记（JOIN 植物名），按时间倒序
  Future<List<Map<String, dynamic>>> getAllDiaries() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT d.*, p.name AS plant_name
      FROM diary_entries d
      INNER JOIN plants p ON d.plant_id = p.id
      ORDER BY d.created_at DESC
    ''');
  }

  /// 获取日记总数
  Future<int> getDiaryCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM diary_entries'));
    return count ?? 0;
  }

  // ===================== Tasks =====================

  /// 今日日期字符串 (YYYY-MM-DD)，本地时区
  static String todayStr() {
    final t = DateTime.now();
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  /// 获取今日任务 (join 植物名)
  Future<List<Map<String, dynamic>>> getTodayTasks() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, p.name AS plant_name
      FROM tasks t
      INNER JOIN plants p ON t.plant_id = p.id
      WHERE date(t.scheduled_date) = date(?)
      ORDER BY t.is_completed ASC, t.scheduled_date ASC
    ''', [todayStr()]);
  }

  /// 获取某植物今日是否已有浇水任务
  Future<bool> hasTodayTask(String plantId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT id FROM tasks WHERE plant_id = ? AND date(scheduled_date) = date(?) AND is_completed = 0',
      [plantId, todayStr()],
    );
    return rows.isNotEmpty;
  }

  /// 获取某植物今日是否已有指定类型的养护任务（watering/fertilizing/pruning）
  Future<bool> hasTodayTaskOfType(String plantId, String taskType) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT id FROM tasks WHERE plant_id = ? AND task_type = ? AND date(scheduled_date) = date(?) AND is_completed = 0',
      [plantId, taskType, todayStr()],
    );
    return rows.isNotEmpty;
  }

  /// 数据库版本迁移
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE plants ADD COLUMN fertilizing_frequency INTEGER DEFAULT 14');
      await db.execute('ALTER TABLE plants ADD COLUMN last_fertilized TEXT');
      await db.execute('ALTER TABLE plants ADD COLUMN next_fertilizing TEXT');
      await db.execute(
          'ALTER TABLE plants ADD COLUMN pruning_frequency INTEGER DEFAULT 30');
      await db.execute('ALTER TABLE plants ADD COLUMN last_pruned TEXT');
      await db.execute('ALTER TABLE plants ADD COLUMN next_pruning TEXT');

      // 为旧数据补齐施肥/修剪的日期（基于浇水频率做合理估算）
      final rows = await db.query('plants');
      for (final row in rows) {
        final id = row['id'] as String;
        final lf = row['last_fertilized'] as String? ??
            DateTime.now().toIso8601String();
        final lp =
            row['last_pruned'] as String? ?? DateTime.now().toIso8601String();
        await db.update(
          'plants',
          {
            'fertilizing_frequency': 14,
            'last_fertilized': lf,
            'next_fertilizing':
                DateTime.parse(lf).add(const Duration(days: 14)).toIso8601String(),
            'pruning_frequency': 30,
            'last_pruned': lp,
            'next_pruning':
                DateTime.parse(lp).add(const Duration(days: 30)).toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE diary_entries ADD COLUMN extra_image_paths TEXT DEFAULT \'[]\'');
    }
  }

  Future<void> insertTask({
    required String plantId,
    required String taskType,
    required String title,
    required DateTime scheduledDate,
  }) async {
    final db = await database;
    await db.insert('tasks', {
      'id': _uuid.v4(),
      'plant_id': plantId,
      'task_type': taskType,
      'title': title,
      'scheduled_date': scheduledDate.toIso8601String(),
      'is_completed': 0,
    });
  }

  Future<void> completeTask(String taskId) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // ===================== User Settings =====================

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows =
        await db.query('user_settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('user_settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ===================== 种子数据 =====================

  Future<bool> isSeeded() async {
    final db = await database;
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM plants'));
    return (count ?? 0) > 0;
  }

  /// 首次启动插入示例植物
  Future<void> seedSampleData() async {
    if (await isSeeded()) return;
    for (final plant in Plant.samplePlants) {
      await insertPlant(plant);
    }
  }
}
