import 'dart:convert';
import 'package:flutter/material.dart' show Color, Colors, IconData, Icons;

/// 植物标签（可自定义文字 + 颜色，最多 3 个）
class PlantTag {
  final String text;
  final int color; // ARGB int，存到数据库/JSON

  const PlantTag({required this.text, required this.color});

  factory PlantTag.fromJson(Map<String, dynamic> json) => PlantTag(
        text: json['text'] as String,
        color: (json['color'] as int?) ?? const Color(0xFFD97706).value,
      );

  Map<String, dynamic> toJson() => {'text': text, 'color': color};

  Color get materialColor => Color(color);
}

/// 植物数据模型
class Plant {
  final String id;
  final String name;
  final String scientificName;
  final String? imagePath; // 本地图片路径（用户拍照/选图），null 时用占位插画
  final String healthStatus;
  final int wateringFrequency;
  final DateTime lastWatered;
  final DateTime nextWatering;
  // 施肥周期
  final int fertilizingFrequency;
  final DateTime lastFertilized;
  final DateTime nextFertilizing;
  // 修剪周期
  final int pruningFrequency;
  final DateTime lastPruned;
  final DateTime nextPruning;
  final String lightRequirement;
  final String temperatureRange;
  final String humidityRange;
  final int careDays;
  final int points;
  // === 植物标签（陪伴感） ===
  final List<PlantTag> tags;
  // === 云同步预埋字段（P3 真实社交 / 云同步用，本地阶段恒为默认值） ===
  final String? serverId; // 云端 ID（Supabase row id），本地为空
  final String
      syncStatus; // 'local' 仅本地 | 'synced' 已同步 | 'pending' 待上传 | 'conflict' 冲突
  final String? ownerId; // 所属用户 ID，本地为空
  final DateTime updatedAt; // 最后更新时间（用于增量同步）

  Plant({
    required this.id,
    required this.name,
    required this.scientificName,
    this.imagePath,
    required this.healthStatus,
    required this.wateringFrequency,
    required this.lastWatered,
    required this.nextWatering,
    this.fertilizingFrequency = 14,
    required this.lastFertilized,
    required this.nextFertilizing,
    this.pruningFrequency = 30,
    required this.lastPruned,
    required this.nextPruning,
    required this.lightRequirement,
    required this.temperatureRange,
    required this.humidityRange,
    this.careDays = 1,
    this.points = 0,
    this.tags = const [],
    this.serverId,
    this.syncStatus = 'local',
    this.ownerId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// 完整 copyWith — 支持编辑所有字段
  Plant copyWith({
    String? name,
    String? scientificName,
    String? imagePath,
    String? healthStatus,
    int? wateringFrequency,
    DateTime? lastWatered,
    DateTime? nextWatering,
    int? fertilizingFrequency,
    DateTime? lastFertilized,
    DateTime? nextFertilizing,
    int? pruningFrequency,
    DateTime? lastPruned,
    DateTime? nextPruning,
    String? lightRequirement,
    String? temperatureRange,
    String? humidityRange,
    int? careDays,
    int? points,
    List<PlantTag>? tags,
    String? serverId,
    String? syncStatus,
    String? ownerId,
    DateTime? updatedAt,
  }) {
    return Plant(
      id: id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      imagePath: imagePath ?? this.imagePath,
      healthStatus: healthStatus ?? this.healthStatus,
      wateringFrequency: wateringFrequency ?? this.wateringFrequency,
      lastWatered: lastWatered ?? this.lastWatered,
      nextWatering: nextWatering ?? this.nextWatering,
      fertilizingFrequency: fertilizingFrequency ?? this.fertilizingFrequency,
      lastFertilized: lastFertilized ?? this.lastFertilized,
      nextFertilizing: nextFertilizing ?? this.nextFertilizing,
      pruningFrequency: pruningFrequency ?? this.pruningFrequency,
      lastPruned: lastPruned ?? this.lastPruned,
      nextPruning: nextPruning ?? this.nextPruning,
      lightRequirement: lightRequirement ?? this.lightRequirement,
      temperatureRange: temperatureRange ?? this.temperatureRange,
      humidityRange: humidityRange ?? this.humidityRange,
      careDays: careDays ?? this.careDays,
      points: points ?? this.points,
      tags: tags ?? this.tags,
      serverId: serverId ?? this.serverId,
      syncStatus: syncStatus ?? this.syncStatus,
      ownerId: ownerId ?? this.ownerId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // === 数据库映射 (snake_case 列名) ===
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'scientific_name': scientificName,
        'image_path': imagePath,
        'health_status': healthStatus,
        'watering_frequency': wateringFrequency,
        'light_requirement': lightRequirement,
        'temperature_range': temperatureRange,
        'humidity_range': humidityRange,
        'care_days': careDays,
        'points': points,
        'tags': jsonEncode(tags.map((t) => t.toJson()).toList()),
        'server_id': serverId,
        'sync_status': syncStatus,
        'owner_id': ownerId,
        'updated_at': updatedAt.toIso8601String(),
        'last_watered': lastWatered.toIso8601String(),
        'next_watering': nextWatering.toIso8601String(),
        'fertilizing_frequency': fertilizingFrequency,
        'last_fertilized': lastFertilized.toIso8601String(),
        'next_fertilizing': nextFertilizing.toIso8601String(),
        'pruning_frequency': pruningFrequency,
        'last_pruned': lastPruned.toIso8601String(),
        'next_pruning': nextPruning.toIso8601String(),
      };

  factory Plant.fromMap(Map<String, dynamic> map) => Plant(
        id: map['id'] as String,
        name: map['name'] as String,
        scientificName: map['scientific_name'] as String? ?? '',
        imagePath: map['image_path'] as String?,
        healthStatus: map['health_status'] as String? ?? '健康',
        wateringFrequency: (map['watering_frequency'] as int?) ?? 7,
        lightRequirement: map['light_requirement'] as String? ?? '明亮散射光',
        temperatureRange: map['temperature_range'] as String? ?? '18-28°C',
        humidityRange: map['humidity_range'] as String? ?? '50-70%',
        careDays: (map['care_days'] as int?) ?? 1,
        points: (map['points'] as int?) ?? 0,
        tags: _tagsFromRaw(map['tags']),
        serverId: map['server_id'] as String?,
        syncStatus: (map['sync_status'] as String?) ?? 'local',
        ownerId: map['owner_id'] as String?,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : DateTime.now(),
        lastWatered: map['last_watered'] != null
            ? DateTime.parse(map['last_watered'] as String)
            : DateTime.now(),
        nextWatering: map['next_watering'] != null
            ? DateTime.parse(map['next_watering'] as String)
            : DateTime.now().add(const Duration(days: 7)),
        fertilizingFrequency: (map['fertilizing_frequency'] as int?) ?? 14,
        lastFertilized: map['last_fertilized'] != null
            ? DateTime.parse(map['last_fertilized'] as String)
            : DateTime.now(),
        nextFertilizing: map['next_fertilizing'] != null
            ? DateTime.parse(map['next_fertilizing'] as String)
            : DateTime.now().add(const Duration(days: 14)),
        pruningFrequency: (map['pruning_frequency'] as int?) ?? 30,
        lastPruned: map['last_pruned'] != null
            ? DateTime.parse(map['last_pruned'] as String)
            : DateTime.now(),
        nextPruning: map['next_pruning'] != null
            ? DateTime.parse(map['next_pruning'] as String)
            : DateTime.now().add(const Duration(days: 30)),
      );

  // === JSON 序列化 (兼容旧代码 / 导出用) ===
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'scientificName': scientificName,
        'imagePath': imagePath,
        'healthStatus': healthStatus,
        'wateringFrequency': wateringFrequency,
        'lastWatered': lastWatered.toIso8601String(),
        'nextWatering': nextWatering.toIso8601String(),
        'fertilizingFrequency': fertilizingFrequency,
        'lastFertilized': lastFertilized.toIso8601String(),
        'nextFertilizing': nextFertilizing.toIso8601String(),
        'pruningFrequency': pruningFrequency,
        'lastPruned': lastPruned.toIso8601String(),
        'nextPruning': nextPruning.toIso8601String(),
        'lightRequirement': lightRequirement,
        'temperatureRange': temperatureRange,
        'humidityRange': humidityRange,
        'careDays': careDays,
        'points': points,
        'tags': tags.map((t) => t.toJson()).toList(),
        'serverId': serverId,
        'syncStatus': syncStatus,
        'ownerId': ownerId,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Plant.fromJson(Map<String, dynamic> json) => Plant(
        id: json['id'] as String,
        name: json['name'] as String,
        scientificName: json['scientificName'] as String,
        imagePath: json['imagePath'] as String?,
        healthStatus: json['healthStatus'] as String,
        wateringFrequency: json['wateringFrequency'] as int,
        lastWatered: DateTime.parse(json['lastWatered'] as String),
        nextWatering: DateTime.parse(json['nextWatering'] as String),
        fertilizingFrequency: (json['fertilizingFrequency'] as int?) ?? 14,
        lastFertilized: DateTime.parse(json['lastFertilized'] as String),
        nextFertilizing: DateTime.parse(json['nextFertilizing'] as String),
        pruningFrequency: (json['pruningFrequency'] as int?) ?? 30,
        lastPruned: DateTime.parse(json['lastPruned'] as String),
        nextPruning: DateTime.parse(json['nextPruning'] as String),
        lightRequirement: json['lightRequirement'] as String,
        temperatureRange: json['temperatureRange'] as String,
        humidityRange: json['humidityRange'] as String,
        careDays: json['careDays'] as int? ?? 1,
        points: json['points'] as int? ?? 0,
        tags: _tagsFromJson(json['tags']),
        serverId: json['serverId'] as String?,
        syncStatus: json['syncStatus'] as String? ?? 'local',
        ownerId: json['ownerId'] as String?,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  // === 业务逻辑 ===
  bool get needsWateringToday {
    final today = DateTime.now();
    return nextWatering.year == today.year &&
        nextWatering.month == today.month &&
        nextWatering.day == today.day;
  }

  /// 距下次浇水天数（<=0 表示该浇了）
  int get daysUntilWatering => nextWatering.difference(DateTime.now()).inDays;

  /// 距下次施肥天数（<=0 表示该施肥了）
  int get daysUntilFertilizing =>
      nextFertilizing.difference(DateTime.now()).inDays;

  /// 距下次修剪天数（<=0 表示该修剪了）
  int get daysUntilPruning => nextPruning.difference(DateTime.now()).inDays;

  bool get needsFertilizing => daysUntilFertilizing <= 0;
  bool get needsPruning => daysUntilPruning <= 0;

  // === 标签解析辅助 ===
  static List<PlantTag> _tagsFromRaw(dynamic raw) {
    if (raw == null || raw == '') return [];
    try {
      final list = jsonDecode(raw.toString()) as List;
      return list
          .map((e) => PlantTag.fromJson(e as Map<String, dynamic>))
          .take(3)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<PlantTag> _tagsFromJson(dynamic json) {
    if (json == null) return [];
    try {
      final list = json as List;
      return list
          .map((e) => PlantTag.fromJson(e as Map<String, dynamic>))
          .take(3)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 首次启动种子数据
  static List<Plant> samplePlants = [
    Plant(
      id: 'sample-1',
      name: '龟背竹',
      scientificName: 'Monstera deliciosa',
      healthStatus: '健康',
      wateringFrequency: 7,
      lastWatered: DateTime.now().subtract(const Duration(days: 7)),
      nextWatering: DateTime.now(),
      fertilizingFrequency: 14,
      lastFertilized: DateTime.now().subtract(const Duration(days: 10)),
      nextFertilizing: DateTime.now().add(const Duration(days: 4)),
      pruningFrequency: 30,
      lastPruned: DateTime.now().subtract(const Duration(days: 20)),
      nextPruning: DateTime.now().add(const Duration(days: 10)),
      lightRequirement: '明亮散射光',
      temperatureRange: '18-30°C',
      humidityRange: '60-80%',
      careDays: 28,
      points: 156,
      tags: [const PlantTag(text: '开心', color: 0xFFD97706)],
    ),
    Plant(
      id: 'sample-2',
      name: '白桃星美人',
      scientificName: 'Pachyphytum oviferum',
      healthStatus: '健康',
      wateringFrequency: 14,
      lastWatered: DateTime.now().subtract(const Duration(days: 12)),
      nextWatering: DateTime.now().add(const Duration(days: 2)),
      fertilizingFrequency: 30,
      lastFertilized: DateTime.now().subtract(const Duration(days: 15)),
      nextFertilizing: DateTime.now().add(const Duration(days: 15)),
      pruningFrequency: 60,
      lastPruned: DateTime.now().subtract(const Duration(days: 40)),
      nextPruning: DateTime.now().add(const Duration(days: 20)),
      lightRequirement: '充足阳光',
      temperatureRange: '15-28°C',
      humidityRange: '30-50%',
      careDays: 15,
      points: 89,
    ),
    Plant(
      id: 'sample-3',
      name: '绿萝',
      scientificName: 'Epipremnum aureum',
      healthStatus: '需关注',
      wateringFrequency: 5,
      lastWatered: DateTime.now().subtract(const Duration(days: 6)),
      nextWatering: DateTime.now().subtract(const Duration(days: 1)),
      fertilizingFrequency: 14,
      lastFertilized: DateTime.now().subtract(const Duration(days: 15)),
      nextFertilizing: DateTime.now().subtract(const Duration(days: 1)),
      pruningFrequency: 30,
      lastPruned: DateTime.now().subtract(const Duration(days: 10)),
      nextPruning: DateTime.now().add(const Duration(days: 20)),
      lightRequirement: '弱光耐受',
      temperatureRange: '15-30°C',
      humidityRange: '50-70%',
      careDays: 42,
      points: 203,
      tags: [
        const PlantTag(text: '注意', color: 0xFFEF4444),
        const PlantTag(text: '新手', color: 0xFF3B82F6),
      ],
    ),
    Plant(
      id: 'sample-4',
      name: '琴叶榕',
      scientificName: 'Ficus lyrata',
      healthStatus: '健康',
      wateringFrequency: 10,
      lastWatered: DateTime.now().subtract(const Duration(days: 10)),
      nextWatering: DateTime.now(),
      fertilizingFrequency: 14,
      lastFertilized: DateTime.now().subtract(const Duration(days: 8)),
      nextFertilizing: DateTime.now().add(const Duration(days: 6)),
      pruningFrequency: 30,
      lastPruned: DateTime.now().subtract(const Duration(days: 15)),
      nextPruning: DateTime.now().add(const Duration(days: 15)),
      lightRequirement: '明亮散射光',
      temperatureRange: '18-28°C',
      humidityRange: '50-65%',
      careDays: 19,
      points: 67,
    ),
  ];

  static String encodeList(List<Plant> plants) =>
      jsonEncode(plants.map((p) => p.toJson()).toList());

  static List<Plant> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => Plant.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// 浇水记录模型
class WateringRecord {
  final String id;
  final String plantId;
  final DateTime wateredAt;

  WateringRecord({
    required this.id,
    required this.plantId,
    required this.wateredAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'plant_id': plantId,
        'watered_at': wateredAt.toIso8601String(),
      };

  factory WateringRecord.fromMap(Map<String, dynamic> map) => WateringRecord(
        id: map['id'] as String,
        plantId: map['plant_id'] as String,
        wateredAt: DateTime.parse(map['watered_at'] as String),
      );
}

/// 生长日记模型
class DiaryEntry {
  final String id;
  final String plantId;
  final String imagePath; // 主图（封面）
  final List<String> extraImagePaths; // 附加图，一次记录可存多张
  final String? note;
  final DateTime createdAt;
  // === 云同步预埋字段 ===
  final String? serverId;
  final String syncStatus;
  final String? ownerId;
  final DateTime updatedAt;

  DiaryEntry({
    required this.id,
    required this.plantId,
    required this.imagePath,
    this.extraImagePaths = const [],
    this.note,
    required this.createdAt,
    this.serverId,
    this.syncStatus = 'local',
    this.ownerId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// 所有图片路径（主图 + 附加图）
  List<String> get allImagePaths =>
      imagePath.isNotEmpty ? [imagePath, ...extraImagePaths] : extraImagePaths;

  Map<String, dynamic> toMap() => {
        'id': id,
        'plant_id': plantId,
        'image_path': imagePath,
        'extra_image_paths': jsonEncode(extraImagePaths),
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'server_id': serverId,
        'sync_status': syncStatus,
        'owner_id': ownerId,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    final extraRaw = map['extra_image_paths'] as String?;
    List<String> extraPaths = [];
    if (extraRaw != null && extraRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(extraRaw) as List?;
        if (decoded != null) {
          extraPaths = decoded.cast<String>();
        }
      } catch (_) {
        extraPaths = [];
      }
    }
    return DiaryEntry(
      id: map['id'] as String,
      plantId: map['plant_id'] as String,
      imagePath: (map['image_path'] as String?) ?? '',
      extraImagePaths: extraPaths,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      serverId: map['server_id'] as String?,
      syncStatus: (map['sync_status'] as String?) ?? 'local',
      ownerId: map['owner_id'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}

/// 养护任务模型
class CareTask {
  final String id;
  final String plantId;
  final String plantName;
  final String taskType;
  final String title;
  final DateTime scheduledDate;
  bool isCompleted;

  CareTask({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.taskType,
    required this.title,
    required this.scheduledDate,
    this.isCompleted = false,
  });

  IconData get icon => switch (taskType) {
        'watering' => Icons.water_drop,
        'fertilizing' => Icons.grain,
        'pruning' => Icons.content_cut,
        _ => Icons.eco,
      };

  /// 从植物列表生成今日浇水任务（用于任务自动生成，非持久化）
  static List<CareTask> fromPlants(List<Plant> plants) {
    final today = DateTime.now();
    return plants
        .where((p) => p.daysUntilWatering <= 0)
        .map((p) => CareTask(
              id: 'task_${p.id}',
              plantId: p.id,
              plantName: p.name,
              taskType: 'watering',
              title: '给${p.name}浇水',
              scheduledDate: today,
              isCompleted: false,
            ))
        .toList();
  }
}

/// 植友的公开植物卡片
class FriendPlant {
  final String name;
  final String scientificName;
  final String healthStatus;
  final int careDays;
  final String lightReq;

  FriendPlant({
    required this.name,
    required this.scientificName,
    required this.healthStatus,
    required this.careDays,
    required this.lightReq,
  });
}

/// 附近植友模型
class NearbyUser {
  final String id;
  final String name;
  final int avatarColor;
  final String plantIcon;
  final double distance;
  final String tag;
  final List<FriendPlant> plants;
  final String serverId; // 对应 Supabase profiles.id，用于「打招呼」的 receiver_id
  final String? avatarUrl; // 头像图片 URL（未设置用 plantIcon 立体 fallback）

  NearbyUser({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.plantIcon,
    required this.distance,
    required this.tag,
    this.plants = const [],
    this.serverId = '',
    this.avatarUrl,
  });

  static List<NearbyUser> sampleUsers = [
    NearbyUser(
      id: 'u1',
      name: '小绿',
      avatarColor: 0xFF059669,
      plantIcon: 'leaf',
      distance: 280,
      tag: '多肉爱好者',
      plants: [
        FriendPlant(
            name: '桃蛋',
            scientificName: 'Graptopetalum amethystinum',
            healthStatus: '健康',
            careDays: 89,
            lightReq: '充足阳光'),
        FriendPlant(
            name: '熊童子',
            scientificName: 'Cotyledon tomentosa',
            healthStatus: '健康',
            careDays: 67,
            lightReq: '充足阳光'),
        FriendPlant(
            name: '生石花',
            scientificName: 'Lithops',
            healthStatus: '需关注',
            careDays: 45,
            lightReq: '充足阳光'),
      ],
    ),
    NearbyUser(
      id: 'u2',
      name: '花间',
      avatarColor: 0xFFD97706,
      plantIcon: 'flower',
      distance: 520,
      tag: '蕨类专精',
      plants: [
        FriendPlant(
            name: '波士顿蕨',
            scientificName: 'Nephrolepis exaltata',
            healthStatus: '健康',
            careDays: 120,
            lightReq: '明亮散射光'),
        FriendPlant(
            name: '铁线蕨',
            scientificName: 'Adiantum capillus-veneris',
            healthStatus: '健康',
            careDays: 95,
            lightReq: '半阴环境'),
      ],
    ),
    NearbyUser(
      id: 'u3',
      name: '新芽',
      avatarColor: 0xFF0D9488,
      plantIcon: 'sprout',
      distance: 850,
      tag: '苔藓玩家',
      plants: [
        FriendPlant(
            name: '白发藓',
            scientificName: 'Leucobryum glaucum',
            healthStatus: '健康',
            careDays: 156,
            lightReq: '弱光耐受'),
        FriendPlant(
            name: '大灰藓',
            scientificName: 'Hypnum plumaeforme',
            healthStatus: '健康',
            careDays: 112,
            lightReq: '弱光耐受'),
        FriendPlant(
            name: '万年藓',
            scientificName: 'Climacium dendroides',
            healthStatus: '需关注',
            careDays: 78,
            lightReq: '半阴环境'),
      ],
    ),
    NearbyUser(
      id: 'u4',
      name: '绿手指',
      avatarColor: 0xFF7C3AED,
      plantIcon: 'seedling',
      distance: 1200,
      tag: '香草达人',
      plants: [
        FriendPlant(
            name: '迷迭香',
            scientificName: 'Rosmarinus officinalis',
            healthStatus: '健康',
            careDays: 201,
            lightReq: '充足阳光'),
        FriendPlant(
            name: '薄荷',
            scientificName: 'Mentha',
            healthStatus: '健康',
            careDays: 188,
            lightReq: '明亮散射光'),
      ],
    ),
    NearbyUser(
      id: 'u5',
      name: '窗台有风',
      avatarColor: 0xFFDC2626,
      plantIcon: 'rose',
      distance: 1800,
      tag: '阳台花园',
      plants: [
        FriendPlant(
            name: '月季',
            scientificName: 'Rosa chinensis',
            healthStatus: '健康',
            careDays: 310,
            lightReq: '充足阳光'),
        FriendPlant(
            name: '绣球',
            scientificName: 'Hydrangea macrophylla',
            healthStatus: '健康',
            careDays: 245,
            lightReq: '半阴环境'),
        FriendPlant(
            name: '茉莉',
            scientificName: 'Jasminum sambac',
            healthStatus: '需关注',
            careDays: 178,
            lightReq: '充足阳光'),
      ],
    ),
  ];

  /// 由 Supabase `nearby_users` RPC 返回结果构造（真数据）。
  factory NearbyUser.fromNearby(Map<String, dynamic> m) {
    return NearbyUser(
      id: (m['id'] as String?) ?? '',
      serverId: (m['id'] as String?) ?? '',
      name: (m['nickname'] as String?)?.isNotEmpty == true
          ? m['nickname'] as String
          : '植友',
      avatarColor: _parseColor(m['avatar_color'] as String?),
      plantIcon: (m['plant_icon'] as String?) ?? 'leaf',
      distance: (m['distance_m'] as num?)?.toDouble() ?? 0,
      tag: (m['tag'] as String?)?.isNotEmpty == true
          ? m['tag'] as String
          : '养花爱好者',
      avatarUrl: (m['avatar_url'] as String?)?.isNotEmpty == true
          ? m['avatar_url'] as String
          : null,
    );
  }

  /// 解析十六进制颜色（如 '#059669'）→ int；失败回退默认绿。
  static int _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return 0xFF059669;
    final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return v == null ? 0xFF059669 : (v | 0xFF000000);
  }
}
