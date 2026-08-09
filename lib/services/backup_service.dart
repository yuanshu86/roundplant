import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../db/database_helper.dart';

/// 纯离线数据备份服务
/// - 备份：复制 SQLite 数据库到应用内 backups 目录（带时间戳）
///   并尝试导出到手机外部存储（需授权），方便用户拷贝到电脑
/// - 恢复：关闭数据库连接 -> 用备份覆盖 -> 重新打开并刷新内存
class BackupFile {
  final String path;
  final String name;
  final DateTime time;
  const BackupFile({
    required this.path,
    required this.name,
    required this.time,
  });
}

class BackupService {
  static const String _backupDirName = 'backups';
  static const String _externalDirName = '圆形植物备份';

  /// 执行一次备份
  /// 返回 (应用内备份路径, 是否成功导出到外部存储)
  static Future<(String, bool)> backup() async {
    final db = DatabaseHelper();
    final src = File(await db.dbFilePath);
    if (!await src.exists()) {
      throw Exception('数据库文件不存在，无法备份');
    }

    // 1) 应用内备份目录
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docsDir.path, _backupDirName));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    final ts = _timestamp();
    final destName = 'circle_plant_$ts.db';
    final dest = File(p.join(backupDir.path, destName));
    await src.copy(dest.path);

    // 2) 尝试导出到外部存储（用户可在文件管理器 / 电脑拿到）
    bool exportedExternal = false;
    try {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          final extDir = Directory(p.join(external.path, _externalDirName));
          if (!await extDir.exists()) await extDir.create(recursive: true);
          await src.copy(p.join(extDir.path, destName));
          exportedExternal = true;
        }
      }
    } catch (e) {
      debugPrint('导出到外部存储失败（不影响应用内备份）: $e');
    }

    return (dest.path, exportedExternal);
  }

  /// 列出应用内所有备份（按时间倒序，最新在前）
  static Future<List<BackupFile>> listBackups() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docsDir.path, _backupDirName));
    if (!await backupDir.exists()) return [];
    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    return files.map((f) {
      final stat = f.statSync();
      return BackupFile(
        path: f.path,
        name: p.basename(f.path),
        time: stat.modified,
      );
    }).toList();
  }

  /// 从指定备份恢复
  static Future<void> restore(String backupPath) async {
    final db = DatabaseHelper();
    await db.closeDb();
    final src = File(backupPath);
    if (!await src.exists()) {
      throw Exception('备份文件不存在');
    }
    final dest = File(await db.dbFilePath);
    if (!await dest.parent.exists()) {
      await dest.parent.create(recursive: true);
    }
    await src.copy(dest.path);
    // 重新打开（database getter 会在下次访问时自动重建连接）
    await db.database;
  }

  static String _timestamp() {
    final t = DateTime.now();
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${t.year}${pad(t.month)}${pad(t.day)}_${pad(t.hour)}${pad(t.minute)}';
  }
}
