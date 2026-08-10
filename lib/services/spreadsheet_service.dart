import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/obat_model.dart';
import '../services/obat_service.dart';
import '../services/kategori_service.dart';
import '../utils/app_constants.dart';

String _normalizeHeaderValue(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

bool _looksLikeHeaderRow(List<String> values) {
  if (values.isEmpty) return false;

  final nonEmptyValues = values.where((value) => value.trim().isNotEmpty).toList();
  if (nonEmptyValues.length < 2) return false;

  final joined = nonEmptyValues.join(' ').trim();
  if (joined.isEmpty) return false;

  final normalized = _normalizeHeaderValue(joined);
  final keywordHits = <String>[
    'kode',
    'nama',
    'harga',
    'stok',
    'deskripsi',
    'keterangan',
    'catatan',
    'barang',
    'produk',
    'beli',
    'jual',
    'min',
    'minimal',
  ].where((keyword) => normalized.contains(keyword)).length;

  return keywordHits >= 2;
}

Map<String, int> detectColumnMapping(
  Iterable<Iterable<dynamic>> rows, {
  bool fallbackToFirstRow = false,
}) {
  final rowList = rows.toList();
  if (rowList.isEmpty) return {};

  int headerIndex = -1;
  for (int index = 0; index < rowList.length; index++) {
    final row = rowList[index].toList();
    if (row.every((cell) => _stringifyCell(cell).isEmpty)) {
      continue;
    }

    final normalizedValues = row
        .map((cell) => _normalizeHeaderValue(_stringifyCell(cell)))
        .toList();

    if (_looksLikeHeaderRow(normalizedValues)) {
      headerIndex = index;
      break;
    }
  }

  if (headerIndex >= 0) {
    final headerRow = rowList[headerIndex].toList();
    final mapping = <String, int>{};

    for (int colIndex = 0; colIndex < headerRow.length; colIndex++) {
      final header = _normalizeHeaderValue(_stringifyCell(headerRow[colIndex]));
      if (header.isEmpty) continue;

      if (header.contains('kode') || header.contains('code')) {
        mapping['kode'] = colIndex;
      } else if (header.contains('nama') || header.contains('barang') || header.contains('produk')) {
        mapping['nama'] = colIndex;
      } else if (header.contains('harga beli') || header.contains('purchase') || header.contains('beli')) {
        mapping['hargaBeli'] = colIndex;
      } else if (header.contains('harga jual') || header.contains('selling') || header.contains('jual')) {
        mapping['hargaJual'] = colIndex;
      } else if (header.contains('stok') || header.contains('qty') || header.contains('quantity') || header.contains('jumlah')) {
        if (!mapping.containsKey('stok') && !header.contains('minimal')) {
          mapping['stok'] = colIndex;
        } else if (header.contains('minimal') || header.contains('min')) {
          mapping['stokMinimal'] = colIndex;
        }
      } else if (header.contains('deskripsi') || header.contains('keterangan') || header.contains('catatan') || header.contains('ket')) {
        mapping['deskripsi'] = colIndex;
      }
    }

    if (!mapping.containsKey('stokMinimal')) {
      mapping['stokMinimal'] = mapping['stok'] ?? 8;
    }

    return mapping;
  }

  if (fallbackToFirstRow) {
    final firstNonEmptyIndex = rowList.indexWhere(
      (row) => row.any((cell) => _stringifyCell(cell).isNotEmpty),
    );

    if (firstNonEmptyIndex >= 0) {
      return {
        'kode': 0,
        'nama': 1,
        'hargaBeli': 2,
        'hargaJual': 3,
        'stok': 4,
        'stokMinimal': 5,
        'deskripsi': 6,
      };
    }
  }

  return {};
}

int findHeaderRowIndex(Iterable<Iterable<dynamic>> rows) {
  final rowList = rows.toList();
  for (int index = 0; index < rowList.length; index++) {
    final row = rowList[index].toList();
    if (row.every((cell) => _stringifyCell(cell).isEmpty)) continue;

    final normalizedValues = row
        .map((cell) => _normalizeHeaderValue(_stringifyCell(cell)))
        .toList();

    if (_looksLikeHeaderRow(normalizedValues)) {
      return index;
    }
  }

  return -1;
}

String _stringifyCell(dynamic cell) {
  if (cell == null) return '';
  if (cell is String) return cell.trim();
  if (cell is num) return cell.toString();
  if (cell is bool) return cell.toString();
  if (cell is DateTime) return cell.toIso8601String();
  return cell.toString().trim();
}

/// Hasil detail dari proses import Excel
class ImportResult {
  final int inserted;
  final int updated;
  final int skipped;
  final List<String> errors;

  const ImportResult({
    this.inserted = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = const [],
  });

  int get total => inserted + updated;
  bool get hasErrors => errors.isNotEmpty;
}

class SpreadsheetService {
  final ObatService _obatService = ObatService();
  final KategoriService _kategoriService = KategoriService();

  // ──────────────────────────────────────────────
  // SHARED PREFERENCES
  // ──────────────────────────────────────────────

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

  // ──────────────────────────────────────────────
  // FILE PICKER — IMPORT
  // ──────────────────────────────────────────────

  /// Membuka dialog pemilihan file Excel dari komputer pengguna.
  /// Mengembalikan path file yang dipilih, atau null jika dibatalkan.
  Future<String?> pickSpreadsheetFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Excel Data Obat (.xlsx)',
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.single.path;
    }
    return null;
  }

  // ──────────────────────────────────────────────
  // EXPORT — Ekspor Data Obat ke Excel
  // ──────────────────────────────────────────────

  /// Mengekspor seluruh data obat dari database ke file Excel (.xlsx).
  /// Menampilkan dialog untuk memilih lokasi penyimpanan.
  /// Mengembalikan path file yang disimpan, atau null jika dibatalkan/gagal.
  Future<String?> exportDatabaseToSpreadsheet() async {
    final obatList = await _obatService.getAll();

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Data Obat Apotek'];
    excel.setDefaultSheet('Data Obat Apotek');

    // Header row — urutan ini HARUS konsisten dengan importSpreadsheetToDb
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

    final nowStr = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final defaultFileName = 'FirdanFarma_DataObat_$nowStr.xlsx';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Ekspor Data Obat ke Excel — Pilih Lokasi Penyimpanan',
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

  // ──────────────────────────────────────────────
  // EXPORT — Download Template Excel Kosong
  // ──────────────────────────────────────────────

  /// Mengekspor template Excel kosong dengan header yang benar.
  /// User bisa mengisi data berdasarkan template ini lalu re-import.
  Future<String?> downloadTemplateExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Data Obat Apotek'];
    excel.setDefaultSheet('Data Obat Apotek');

    // Header row
    sheet.appendRow([
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
    ]);

    // Contoh baris
    sheet.appendRow([
      TextCellValue('(kosongkan, otomatis)'),
      TextCellValue('OBT-001'),
      TextCellValue('Contoh Nama Obat'),
      TextCellValue('Analgesik & Antiinflamasi'),
      TextCellValue('PT Contoh Supplier'),
      DoubleCellValue(5000),
      DoubleCellValue(8000),
      IntCellValue(100),
      IntCellValue(10),
      TextCellValue('Deskripsi opsional'),
    ]);

    const saveName = 'Template_Import_DataObat_FirdanFarma.xlsx';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Template Excel — Pilih Lokasi',
      fileName: saveName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (savePath != null) {
      var bytes = excel.save();
      if (bytes != null) {
        File(savePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        return savePath;
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────
  // IMPORT — Impor Data Obat dari Excel
  // ──────────────────────────────────────────────

  /// Mengimpor data obat dari file Excel ke database.
  /// Mendukung deteksi header secara dinamis (tidak bergantung posisi kolom fix).
  /// Mengembalikan [ImportResult] yang berisi detail jumlah berhasil/gagal.
  Future<ImportResult> importSpreadsheetToDb(String filePath) async {
    int inserted = 0;
    int updated = 0;
    int skipped = 0;
    final errors = <String>[];

    try {
      final bytes = await File(filePath).readAsBytes();
      var excel = Excel.decodeBytes(bytes);

      final categories = await _kategoriService.getAll();
      int defaultKategoriId = categories.isNotEmpty ? categories.first.id! : 1;

      // Iterasi semua sheet dalam file Excel
      for (var tableName in excel.tables.keys) {
        var sheet = excel.tables[tableName];
        if (sheet == null || sheet.rows.isEmpty) continue;

        final headerMap = detectColumnMapping(sheet.rows, fallbackToFirstRow: true);
        debugPrint('[SpreadsheetService] Header ditemukan: $headerMap');

        final int? idxKode = headerMap['kode'];
        final int? idxNama = headerMap['nama'];
        final int? idxHBeli = headerMap['hargaBeli'];
        final int? idxHJual = headerMap['hargaJual'];
        final int? idxStok = headerMap['stok'];
        final int? idxMinStr = headerMap['stokMinimal'];
        final int? idxDesk = headerMap['deskripsi'];

        final int colKode = idxKode ?? 0;
        final int colNama = idxNama ?? 1;
        final int colHBeli = idxHBeli ?? 2;
        final int colHJual = idxHJual ?? 3;
        final int colStok = idxStok ?? 4;
        final int colMinStr = idxMinStr ?? 5;
        final int colDesk = idxDesk ?? 6;

        debugPrint('[SpreadsheetService] Mapping kolom => Kode:$colKode, Nama:$colNama, HargaBeli:$colHBeli, HargaJual:$colHJual, Stok:$colStok');

        final startRowIndex = findHeaderRowIndex(sheet.rows) + 1;
        int rowNum = 0;
        for (int rowIndex = startRowIndex; rowIndex < sheet.rows.length; rowIndex++) {
          final row = sheet.rows[rowIndex];
          rowNum++;

          // Baris kosong total → lewati
          if (row.every((c) => _cellToString(c).isEmpty)) {
            skipped++;
            continue;
          }

          try {
            // Ambil nilai kolom dengan aman
            String kode = _safeCellAt(row, colKode);
            String nama = _safeCellAt(row, colNama);

            if (nama.isEmpty) {
              skipped++;
              debugPrint('[SpreadsheetService] Baris $rowNum dilewati: nama kosong');
              continue;
            }

            // Auto-generate kode jika kosong
            if (kode.isEmpty) {
              kode = 'OBT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
            }

            final double hargaBeli  = _safeDouble(row, colHBeli);
            final double hargaJual  = _safeDouble(row, colHJual);
            final int stokTersedia  = _safeInt(row, colStok);
            final int stokMinimal   = _safeInt(row, colMinStr, defaultVal: 5);
            final String deskripsi  = _safeCellAt(row, colDesk);

            // Cek apakah obat dengan kode ini sudah ada
            final existing = await _obatService.getByKode(kode);
            if (existing != null) {
              // UPDATE — perbarui data yang sudah ada, aktifkan kembali jika nonaktif
              await _obatService.update(
                existing.copyWith(
                  nama: nama,
                  hargaBeli: hargaBeli > 0 ? hargaBeli : existing.hargaBeli,
                  hargaJual: hargaJual > 0 ? hargaJual : existing.hargaJual,
                  stokTersedia: stokTersedia,
                  stokMinimal: stokMinimal > 0 ? stokMinimal : existing.stokMinimal,
                  deskripsi: deskripsi.isNotEmpty ? deskripsi : existing.deskripsi,
                  isActive: true,
                ),
              );
              updated++;
            } else {
              // INSERT — tambahkan obat baru
              await _obatService.insert(
                Obat(
                  nama: nama,
                  kodeObat: kode,
                  kategoriId: defaultKategoriId,
                  hargaBeli: hargaBeli,
                  hargaJual: hargaJual,
                  stokTersedia: stokTersedia,
                  stokMinimal: stokMinimal > 0 ? stokMinimal : 5,
                  deskripsi: deskripsi.isNotEmpty ? deskripsi : null,
                  createdAt: DateTime.now().toIso8601String(),
                ),
              );
              inserted++;
            }
          } catch (rowError) {
            errors.add('Baris $rowNum: ${rowError.toString()}');
            debugPrint('[SpreadsheetService] Error baris $rowNum: $rowError');
            skipped++;
          }
        }
      }
    } catch (e) {
      errors.add('Gagal membaca file: ${e.toString()}');
      debugPrint('[SpreadsheetService] Fatal error import: $e');
    }

    return ImportResult(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }

  // ──────────────────────────────────────────────
  // HELPERS — Parsing Cell yang Aman & Robust
  // ──────────────────────────────────────────────

  /// Konversi cell Excel ke String, menangani semua tipe CellValue.
  /// Catatan: di excel ^4.x, TextCellValue.value bertipe TextSpan,
  /// sehingga kita pakai toString() yang universal untuk semua tipe.
  String _cellToString(dynamic cell) {
    if (cell == null) return '';

    if (cell is Data) {
      final v = cell.value;
      if (v == null) return '';
      if (v is IntCellValue) return v.value.toString();
      if (v is DoubleCellValue) return v.value.toString();
      if (v is BoolCellValue) return v.value.toString();
      return v.toString().trim();
    }

    if (cell is String) return cell.trim();
    if (cell is num) return cell.toString();
    if (cell is bool) return cell.toString();
    if (cell is DateTime) return cell.toIso8601String();
    return cell.toString().trim();
  }

  /// Ambil nilai string dari kolom tertentu pada sebuah baris, aman jika kolom tidak ada.
  String _safeCellAt(List<dynamic> row, int colIndex) {
    if (colIndex < 0 || colIndex >= row.length) return '';
    return _cellToString(row[colIndex]);
  }

  /// Parse double dari kolom tertentu, aman terhadap format apapun.
  double _safeDouble(List<dynamic> row, int colIndex, {double defaultVal = 0}) {
    final raw = _safeCellAt(row, colIndex);
    if (raw.isEmpty) return defaultVal;
    final cleaned = raw.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(cleaned) ?? double.tryParse(raw) ?? defaultVal;
  }

  /// Parse int dari kolom tertentu, aman terhadap format apapun.
  int _safeInt(List<dynamic> row, int colIndex, {int defaultVal = 0}) {
    final raw = _safeCellAt(row, colIndex);
    if (raw.isEmpty) return defaultVal;
    final cleaned = raw.replaceAll('.', '').replaceAll(',', '').trim();
    return int.tryParse(cleaned) ??
        double.tryParse(cleaned)?.toInt() ??
        int.tryParse(raw.split('.').first) ??
        defaultVal;
  }
}
