import '../db/database_helper.dart';
import '../models/plant.dart';

/// 生长日记数据仓储 — 隔离底层存储，预留云端同步接口。
///
/// 与 [PlantRepository] 同理：本地阶段走 [DatabaseHelper]，
/// P3 真实社交/云同步时在此处补齐远程同步逻辑即可。
class DiaryRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// 获取全部日记（JOIN 植物名），按时间倒序
  Future<List<Map<String, dynamic>>> getAllJoined() => _db.getAllDiaries();

  Future<void> insert(DiaryEntry entry) => _db.insertDiary(entry);

  Future<List<DiaryEntry>> getForPlant(String plantId) =>
      _db.getDiaries(plantId);
}
