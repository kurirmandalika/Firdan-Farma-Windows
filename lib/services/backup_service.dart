import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String?> exportDatabase() async {
    final currentDbPath = await _dbHelper.getDbPath();
    final dbFile = File(currentDbPath);

    if (!await dbFile.exists()) {
      throw Exception('File database tidak ditemukan!');
    }

    final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final defaultFileName = 'firdan_farma_backup_$nowStr.db';

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan File Backup Database Apotek',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite'],
    );

    if (outputPath != null) {
      await dbFile.copy(outputPath);
      return outputPath;
    }
    return null;
  }

  Future<bool> importDatabase(String sourceFilePath) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw Exception('File backup yang dipilih tidak dapat dibaca!');
    }

    // 1. Validate SQLite database file structure before doing anything
    Database? tempDb;
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      tempDb = await databaseFactory.openDatabase(
        sourceFilePath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final tables = await tempDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      final requiredTables = {'obat', 'transaksi', 'stok', 'detail_transaksi'};

      if (!requiredTables.every((t) => tableNames.contains(t))) {
        throw Exception('Skema database tidak sesuai! Tabel utama apotek tidak ditemukan.');
      }
    } catch (e) {
      throw Exception('File backup tidak valid atau rusak:\n$e');
    } finally {
      await tempDb?.close();
    }

    // 2. Create automatic safety backup of current active database
    final targetDbPath = await _dbHelper.getDbPath();
    final targetFile = File(targetDbPath);
    if (await targetFile.exists()) {
      final timeStr = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final autoBackupPath = p.join(targetFile.parent.path, 'backup_auto_before_restore_$timeStr.db');
      await targetFile.copy(autoBackupPath);
    }

    // 3. Close active DB connection
    await _dbHelper.closeAndReset();

    // 4. Overwrite target DB file
    await sourceFile.copy(targetFile.path);

    // 5. Re-open database
    await _dbHelper.database;
    return true;
  }

  Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Backup Database (.db)',
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite'],
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.single.path;
    }
    return null;
  }
}
