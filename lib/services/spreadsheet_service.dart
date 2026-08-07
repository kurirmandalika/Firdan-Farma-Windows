import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/obat_model.dart';
import '../services/obat_service.dart';
import '../services/kategori_service.dart';
import '../utils/app_constants.dart';

class SpreadsheetService {
  final ObatService _obatService = ObatService();
  final KategoriService _kategoriService = KategoriService();

  Future<String?> getConnectedSpreadsheetPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefsSpreadsheetPathKey);
  }

  Future<void> setConnectedSpreadsheetPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(AppConstants.prefsSpreadsheetPathKey);
    } else {
      await prefs.setString(AppConstants.prefsSpreadsheetPathKey, path);
    }
  }

  Future<String?> pickSpreadsheetFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Excel Data Obat (.xlsx)',
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        await setConnectedSpreadsheetPath(path);
      }
      return path;
    }
    return null;
  }

  Future<String?> exportDatabaseToSpreadsheet() async {
    final obatList = await _obatService.getAll();

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Data Obat Apotek'];
    excel.setDefaultSheet('Data Obat Apotek');

    // Header row
    List<CellValue> headers = [
      TextCellValue('ID'),
      TextCellValue('Kode Obat'),
      TextCellValue('Nama Obat'),
      TextCellValue('Kategori'),
      TextCellValue('Supplier'),
      TextCellValue('Harga Beli'),
      TextCellValue('Harga Jual'),
      TextCellValue('Stok Tersedia'),
      TextCellValue('Stok Minimal'),
      TextCellValue('Deskripsi'),
    ];
    sheetObject.appendRow(headers);

    for (var obat in obatList) {
      sheetObject.appendRow([
        IntCellValue(obat.id ?? 0),
        TextCellValue(obat.kodeObat),
        TextCellValue(obat.nama),
        TextCellValue(obat.namaKategori ?? 'Umum'),
        TextCellValue(obat.namaSupplier ?? '-'),
        DoubleCellValue(obat.hargaBeli),
        DoubleCellValue(obat.hargaJual),
        IntCellValue(obat.stokTersedia),
        IntCellValue(obat.stokMinimal),
        TextCellValue(obat.deskripsi ?? ''),
      ]);
    }

    final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final defaultFileName = 'FirdanFarma_DataObat_$nowStr.xlsx';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Ekspor Data Obat ke Excel',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (savePath != null) {
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(savePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        await setConnectedSpreadsheetPath(savePath);
        return savePath;
      }
    }
    return null;
  }

  Future<int> importSpreadsheetToDb(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    int count = 0;

    final categories = await _kategoriService.getAll();
    int defaultKategoriId = categories.isNotEmpty ? categories.first.id! : 1;

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;

      bool isFirstRow = true;
      for (var row in sheet.rows) {
        if (isFirstRow) {
          isFirstRow = false;
          continue; // Skip header row
        }

        if (row.length < 3) continue;

        String? kode = row[1]?.value?.toString().trim();
        String? nama = row[2]?.value?.toString().trim();

        if (nama == null || nama.isEmpty) continue;
        if (kode == null || kode.isEmpty) {
          kode = 'OBT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        }

        double hargaBeli = double.tryParse(row[5]?.value?.toString() ?? '0') ?? 0;
        double hargaJual = double.tryParse(row[6]?.value?.toString() ?? '0') ?? 0;
        int stokTersedia = int.tryParse(row[7]?.value?.toString() ?? '0') ?? 0;
        int stokMinimal = int.tryParse(row[8]?.value?.toString() ?? '5') ?? 5;
        String? deskripsi = row.length > 9 ? row[9]?.value?.toString() : '';

        // Check if code exists
        final existing = await _obatService.getByKode(kode);
        if (existing != null) {
          // Update
          await _obatService.update(existing.copyWith(
            nama: nama,
            hargaBeli: hargaBeli > 0 ? hargaBeli : existing.hargaBeli,
            hargaJual: hargaJual > 0 ? hargaJual : existing.hargaJual,
            stokTersedia: stokTersedia,
            stokMinimal: stokMinimal,
            deskripsi: deskripsi ?? existing.deskripsi,
          ));
        } else {
          // Insert
          await _obatService.insert(Obat(
            nama: nama,
            kodeObat: kode,
            kategoriId: defaultKategoriId,
            hargaBeli: hargaBeli,
            hargaJual: hargaJual,
            stokTersedia: stokTersedia,
            stokMinimal: stokMinimal,
            deskripsi: deskripsi,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
        count++;
      }
    }
    return count;
  }
}
