import '../db/database_helper.dart';
import '../models/plant.dart';

/// 植物数据仓储 — 隔离底层存储（SQLite），为 P3 接入云端（Supabase）预留同步接口。
///
/// 当前内部走 [DatabaseHelper]；将来接 Supabase 时，只需在此处增加远程同步逻辑
/// （上传 serverId / syncStatus=pending，拉取后写回本地并标记 synced），
/// 业务层（[AppStore]）无需改动。
class PlantRepository {
  final DatabaseHelper _db = DatabaseHelper();

  /// 首次启动插入示例数据（仅当库为空）
  Future<void> seedIfEmpty() => _db.seedSampleData();

  /// 获取全部植物
  Future<List<Plant>> getAll() async {
    final rows = await _db.getAllPlants();
    return rows.map(Plant.fromMap).toList();
  }

  Future<void> insert(Plant plant) => _db.insertPlant(plant);
  Future<void> update(Plant plant) => _db.updatePlant(plant);
  Future<void> delete(String id) => _db.deletePlant(id);
}
