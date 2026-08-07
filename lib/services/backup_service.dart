import 'dart:io';
import 'package:file_picker/file_picker.dart';
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

    // 1. Close active DB connection
    await _dbHelper.closeAndReset();

    // 2. Overwrite target DB file
    final targetDbPath = await _dbHelper.getDbPath();
    final targetFile = File(targetDbPath);

    await sourceFile.copy(targetFile.path);

    // 3. Re-open database
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
