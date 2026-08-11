import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';
import 'package:firdan_farma_windows/data/services/obat_service.dart';
import 'package:firdan_farma_windows/data/services/kategori_service.dart';
import 'package:firdan_farma_windows/core/constants/app_constants.dart';

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

  Future<String?> pickSpreadsheetFile() async {
    // Hanya .xlsx yang didukung package excel (bukan .xls format lama)
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pilih File Excel Data Obat (.xlsx)',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null && result.files.isNotEmpty) {
      return result.files.single.path;
    }
    return null;
  }

  // ──────────────────────────────────────────────
  // EXPORT — Ekspor Data Obat ke Excel
  // ──────────────────────────────────────────────

  Future<String?> exportDatabaseToSpreadsheet() async {
    final obatList = await _obatService.getAll();

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Data Obat Apotek'];
    excel.setDefaultSheet('Data Obat Apotek');

    sheetObject.appendRow([
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
      final fileBytes = excel.save();
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

  Future<String?> downloadTemplateExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Data Obat Apotek'];
    excel.setDefaultSheet('Data Obat Apotek');

    sheet.appendRow([
      TextCellValue('Kode Obat'),
      TextCellValue('Nama Obat'),
      TextCellValue('Harga Beli'),
      TextCellValue('Harga Jual'),
      TextCellValue('Stok Tersedia'),
      TextCellValue('Stok Minimal'),
      TextCellValue('Satuan'),
      TextCellValue('Deskripsi'),
    ]);

    sheet.appendRow([
      TextCellValue('OBT-001'),
      TextCellValue('Contoh Nama Obat'),
      DoubleCellValue(5000),
      DoubleCellValue(8000),
      IntCellValue(100),
      IntCellValue(10),
      TextCellValue('Strip'),
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
      final bytes = excel.save();
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
  // IMPORT — Universal Excel Reader
  // ──────────────────────────────────────────────
  // ✅ Membaca format Excel APAPUN milik pemilik apotek (.xlsx)
  // ✅ Deteksi kolom otomatis dari nama header (bahasa Indonesia/Inggris)
  // ✅ Jika header tidak dikenali, tebak berdasarkan posisi kolom
  // ✅ Tidak ada null crash — semua path aman (catch Object)
  // ──────────────────────────────────────────────

  Future<ImportResult> importSpreadsheetToDb(String filePath) async {
    int inserted = 0;
    int updated = 0;
    int skipped = 0;
    final errors = <String>[];

    try {
      // ── 1. Validasi ekstensi — .xls tidak didukung package excel ──
      final ext = filePath.split('.').last.toLowerCase();
      if (ext == 'xls') {
        return ImportResult(
          errors: [
            'Format .xls (Excel 97-2003) tidak didukung.\n'
                'Langkah perbaikan:\n'
                '1. Buka file di Microsoft Excel atau LibreOffice Calc\n'
                '2. Klik File → Simpan Sebagai (Save As)\n'
                '3. Pilih format "Excel Workbook (.xlsx)"\n'
                '4. Import ulang file .xlsx yang baru disimpan.',
          ],
        );
      }

      // ── 2. Baca file dengan aman ──
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(errors: ['File tidak ditemukan: $filePath']);
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return ImportResult(errors: ['File kosong atau tidak valid.']);
      }

      // ── 3. Parse Excel — tangkap SEMUA error termasuk null-check internal ──
      Excel excel;
      try {
        excel = _decodeExcel(bytes);
      } on Object catch (decodeErr) {
        // Package excel bisa crash dengan null check operator pada file non-standard
        debugPrint('[Import] Decode error: $decodeErr');
        return ImportResult(
          errors: [
            'Gagal membaca struktur file Excel.\n'
                'Kemungkinan penyebab:\n'
                '• File bukan format .xlsx murni (mungkin .xls, .csv, atau file rusak)\n'
                '• File dibuat oleh software yang tidak kompatibel (Google Sheets export, WPS, dsb)\n\n'
                'Solusi: Buka di Microsoft Excel → Simpan Sebagai → Excel Workbook (.xlsx) → import ulang.\n\n'
                'Detail: ${decodeErr.toString()}',
          ],
        );
      }

      // ── 2. Kategori default (null-safe) ──
      int defaultKategoriId = 1;
      try {
        final cats = await _kategoriService.getAll();
        if (cats.isNotEmpty) {
          defaultKategoriId = cats.first.id ?? 1;
        }
      } catch (_) {}

      // ── 4. Iterasi setiap sheet ──
      if (excel.tables.isEmpty) {
        return ImportResult(
          errors: ['File Excel tidak memiliki sheet/lembar data.'],
        );
      }

      for (final tableName in excel.tables.keys) {
        Sheet? sheet;
        try {
          sheet = excel.tables[tableName];
        } on Object catch (e) {
          errors.add('Sheet "$tableName" tidak bisa diakses: $e');
          continue;
        }

        if (sheet == null || sheet.rows.isEmpty) continue;

        // Kumpulkan baris yang tidak kosong total
        List<List<Data?>> allRows;
        try {
          allRows = sheet.rows
              .where((row) => row.any((c) => _cellStr(c).isNotEmpty))
              .toList();
        } on Object catch (e) {
          errors.add('Sheet "$tableName" gagal dibaca: $e');
          continue;
        }

        if (allRows.isEmpty) continue;

        debugPrint(
          '[Import] Sheet "$tableName": ${allRows.length} baris non-kosong',
        );

        // ── 5. Deteksi baris header ──
        // Cari baris pertama (maks 10 baris) yang berisi setidaknya 1 cell teks non-numerik
        final stringRows = allRows.map(_rowToStrings).toList();
        final detected = _detectColumnMappingFromRows(stringRows);
        final headerIdx = detected.headerIndex;
        final headerFound = detected.headerFound;
        final mapping = detected.mapping;

        debugPrint(
          '[Import] Header di baris '
          '${headerFound ? headerIdx + 1 : "(tidak terdeteksi)"}: '
          '${detected.headerLabels.isEmpty ? "(kosong)" : detected.headerLabels.join(", ")}',
        );
        debugPrint(
          '[Import] Mapping => Nama:${mapping.nama}, Kode:${mapping.kode}, '
          'HJual:${mapping.hargaJual}, HBeli:${mapping.hargaBeli}, '
          'Stok:${mapping.stok}, StokMin:${mapping.stokMinimal}',
        );

        // ── 6. Mapping kolom dengan keyword yang diperluas ──
        // Kolom WAJIB: Nama Obat
        var colNama = mapping.nama;

        // ── 7. Fallback posisional jika kolom nama masih tidak ditemukan ──
        colNama = mapping.nama;
        if (colNama < 0) {
          if (mapping.nama >= 0 && !headerFound && allRows.isNotEmpty) {
            // Tidak ada header sama sekali — cari kolom pertama yang isi teks
            for (int ci = 0; ci < (allRows.first.length); ci++) {
              final samples = _gatherColSample(allRows, ci, 5);
              if (samples.any((v) => v.isNotEmpty && !_isNumericStr(v))) {
                colNama = ci;
                break;
              }
            }
          }

          if (colNama < 0) {
            errors.add(
              'Sheet "$tableName": Tidak bisa mendeteksi kolom Nama Obat.\n'
              'Header yang terbaca: ${detected.headerLabels.isEmpty ? "(tidak ada header teks)" : detected.headerLabels.join(", ")}\n'
              'Pastikan ada kolom nama barang/obat, atau gunakan urutan umum: Kode, Nama, Harga Beli, Harga Jual, Stok.',
            );
            continue;
          }
        }

        // ── 8. Proses setiap baris data ──
        int rowNum = 0;
        for (int ri = 0; ri < allRows.length; ri++) {
          rowNum++;
          if (headerFound && ri <= headerIdx) continue; // Lewati baris header

          List<Data?> row;
          try {
            row = allRows[ri];
          } on Object catch (_) {
            skipped++;
            continue;
          }

          if (row.every((c) => _cellStr(c).isEmpty)) continue; // baris kosong
          final rowText = ri < stringRows.length
              ? stringRows[ri]
              : _rowToStrings(row);
          if (_looksLikeHeaderRow(rowText) ||
              _isSummaryRow(rowText, mapping.nama)) {
            skipped++;
            continue;
          }

          try {
            // Nama — wajib ada
            final nama = _str(row, mapping.nama);
            if (nama.isEmpty) {
              skipped++;
              continue;
            }

            // Kode — auto generate jika tidak ada
            String kode = mapping.kode >= 0 ? _str(row, mapping.kode) : '';
            if (kode.isEmpty || kode == '0') {
              kode = _makeKode(nama, rowNum);
            }

            // Harga jual
            var hargaJual = mapping.hargaJual >= 0
                ? _dbl(row, mapping.hargaJual)
                : 0.0;

            // Harga beli (estimasi 70% dari harga jual jika tidak ada)
            var hargaBeli = mapping.hargaBeli >= 0
                ? _dbl(row, mapping.hargaBeli)
                : (hargaJual > 0 ? hargaJual * 0.7 : 0.0);
            if (hargaJual <= 0 && hargaBeli > 0) {
              hargaJual = hargaBeli;
            }
            if (hargaBeli <= 0 && hargaJual > 0) {
              hargaBeli = hargaJual * 0.7;
            }

            // Stok
            final stok = mapping.stok >= 0 ? _int(row, mapping.stok) : 0;
            final stokMin = mapping.stokMinimal >= 0
                ? _int(row, mapping.stokMinimal, def: 5)
                : 5;

            // Deskripsi / satuan
            String desk = mapping.deskripsi >= 0
                ? _str(row, mapping.deskripsi)
                : '';
            if (desk.isEmpty && mapping.satuan >= 0) {
              desk = _str(row, mapping.satuan);
            }

            // Cek existing
            final existing = await _obatService.getByKode(kode);
            if (existing != null) {
              await _obatService.update(
                existing.copyWith(
                  nama: nama,
                  hargaBeli: hargaBeli > 0 ? hargaBeli : existing.hargaBeli,
                  hargaJual: hargaJual > 0 ? hargaJual : existing.hargaJual,
                  stokTersedia: mapping.stok >= 0
                      ? stok
                      : existing.stokTersedia,
                  stokMinimal: mapping.stokMinimal >= 0 && stokMin > 0
                      ? stokMin
                      : existing.stokMinimal,
                  deskripsi: desk.isNotEmpty ? desk : existing.deskripsi,
                  isActive: true,
                ),
              );
              updated++;
            } else {
              await _obatService.insert(
                Obat(
                  nama: nama,
                  kodeObat: kode,
                  kategoriId: defaultKategoriId,
                  hargaBeli: hargaBeli,
                  hargaJual: hargaJual,
                  stokTersedia: stok,
                  stokMinimal: stokMin > 0 ? stokMin : 5,
                  deskripsi: desk.isNotEmpty ? desk : null,
                  createdAt: DateTime.now().toIso8601String(),
                ),
              );
              inserted++;
            }
          } on Object catch (rowErr) {
            final msg = 'Baris $rowNum: ${rowErr.toString()}';
            errors.add(msg);
            debugPrint('[Import] Error $msg');
            skipped++;
          }
        }
      }
    } on Object catch (e, st) {
      debugPrint('[Import] Fatal: $e\n$st');
      errors.add('Gagal memproses file: ${e.toString()}');
    }

    return ImportResult(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }

  // ──────────────────────────────────────────────
  // HELPERS — Cell Parsing (excel ^4.x safe)
  // ──────────────────────────────────────────────

  /// Ekstrak teks dari cell — null-safe total, catch Object.
  /// TextCellValue.value di excel ^4.x adalah TextSpan milik package excel
  /// (bukan Flutter). TextSpan.toString() sudah null-safe secara internal.
  Excel _decodeExcel(List<int> bytes) {
    try {
      return Excel.decodeBytes(bytes);
    } on Object catch (firstError) {
      final repairedBytes = _repairXlsxStylesForExcelParser(bytes);
      if (repairedBytes == null) {
        rethrow;
      }

      debugPrint(
        '[Import] Decode awal gagal, mencoba ulang dengan styles.xml yang dinormalisasi: $firstError',
      );

      try {
        return Excel.decodeBytes(repairedBytes);
      } on Object catch (retryError) {
        throw Exception(
          'Excel parser gagal setelah normalisasi styles.xml. '
          'Error awal: $firstError. Error setelah normalisasi: $retryError',
        );
      }
    }
  }

  List<int>? _repairXlsxStylesForExcelParser(List<int> bytes) {
    try {
      final sourceArchive = ZipDecoder().decodeBytes(bytes, verify: false);
      final repairedArchive = Archive();
      var changed = false;

      for (final file in sourceArchive.files) {
        if (!file.isFile) {
          final directory = ArchiveFile(file.name, 0, null)..isFile = false;
          repairedArchive.addFile(directory);
          continue;
        }

        final content = file.content;
        final fileBytes = content is List<int> ? content : <int>[];

        if (file.name == 'xl/styles.xml') {
          final originalXml = utf8.decode(fileBytes, allowMalformed: true);
          final normalizedXml = sanitizeExcelStylesXml(originalXml);
          final normalizedBytes = utf8.encode(normalizedXml);
          changed = changed || normalizedXml != originalXml;
          repairedArchive.addFile(
            ArchiveFile(file.name, normalizedBytes.length, normalizedBytes),
          );
        } else {
          repairedArchive.addFile(
            ArchiveFile(file.name, fileBytes.length, fileBytes),
          );
        }
      }

      if (!changed) return null;
      return ZipEncoder().encode(repairedArchive);
    } on Object catch (e) {
      debugPrint('[Import] Gagal normalisasi styles.xml: $e');
      return null;
    }
  }

  String _cellStr(Data? cell) {
    if (cell == null) return '';
    CellValue? v;
    try {
      v = cell.value;
    } on Object catch (_) {
      return '';
    }
    if (v == null) return '';
    try {
      if (v is IntCellValue) return v.value.toString();
      if (v is DoubleCellValue) {
        final d = v.value;
        if (d.isNaN || d.isInfinite) return '';
        // Hindari scientific notation untuk angka bulat
        if (d == d.truncateToDouble()) return d.truncate().toString();
        return d.toString();
      }
      if (v is BoolCellValue) return v.value ? '1' : '0';
      if (v is TextCellValue) {
        // toString() dari TextSpan excel sudah null-safe
        return v.value.toString().trim();
      }
      if (v is DateCellValue) {
        return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
      }
      if (v is DateTimeCellValue) {
        return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
      }
      if (v is FormulaCellValue) {
        return v.formula.trim();
      }
      // Fallback umum
      return v.toString().trim();
    } on Object catch (_) {
      return '';
    }
  }

  /// Ambil string dari kolom di baris tertentu — null-safe.
  String _str(List<Data?> row, int col) {
    if (col < 0 || col >= row.length) return '';
    try {
      return _cellStr(row[col]);
    } on Object catch (_) {
      return '';
    }
  }

  List<String> _rowToStrings(List<Data?> row) {
    return List.generate(row.length, (index) => _cellStr(row[index]).trim());
  }

  /// Ambil double dari kolom, mendukung format numerik Indonesia & standar.
  double _dbl(List<Data?> row, int col, {double def = 0.0}) {
    if (col < 0 || col >= row.length) return def;
    final cell = row[col];
    if (cell == null) return def;
    CellValue? v;
    try {
      v = cell.value;
    } on Object catch (_) {
      return def;
    }
    if (v == null) return def;
    try {
      if (v is DoubleCellValue) return v.value.isNaN ? def : v.value;
      if (v is IntCellValue) return v.value.toDouble();
    } on Object catch (_) {}
    final raw = _cellStr(cell);
    if (raw.isEmpty) return def;
    // Coba as-is
    final parsed = _parseFlexibleNumber(raw);
    if (parsed != null) return parsed;
    // Format Indonesia: "1.000.000,50" → hapus titik, ganti koma
    final cleaned = raw
        .replaceAll(RegExp(r'[^\d,\-]'), '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned) ?? def;
  }

  /// Ambil int dari kolom.
  int _int(List<Data?> row, int col, {int def = 0}) {
    final d = _dbl(row, col, def: def.toDouble());
    return (d.isNaN || d.isInfinite) ? def : d.truncate();
  }

  /// Cari indeks kolom dari header map — exact match, lalu partial match.
  /// Kumpulkan sample nilai dari kolom tertentu (untuk inferensi tanpa header).
  List<String> _gatherColSample(List<List<Data?>> rows, int col, int maxRows) {
    final result = <String>[];
    for (int ri = 0; ri < rows.length && ri < maxRows; ri++) {
      if (col < rows[ri].length) {
        try {
          final v = _cellStr(rows[ri][col]);
          if (v.isNotEmpty) result.add(v);
        } on Object catch (_) {}
      }
    }
    return result;
  }

  /// Inferensi kolom nama obat — kolom teks dengan total panjang terbanyak.
  // ignore: unused_element
  int _inferNamaCol(List<List<Data?>> rows, int skipUntil) {
    final scores = <int, int>{};
    for (
      int ri = skipUntil + 1;
      ri < rows.length && ri < skipUntil + 20;
      ri++
    ) {
      for (int ci = 0; ci < rows[ri].length; ci++) {
        final val = _cellStr(rows[ri][ci]);
        if (val.isNotEmpty && !_isNumericStr(val)) {
          scores[ci] = (scores[ci] ?? 0) + val.length;
        }
      }
    }
    if (scores.isEmpty) return -1;
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Inferensi kolom harga — kolom numerik dengan nilai rata-rata tertinggi (> 100).
  // ignore: unused_element
  int _inferHargaCol(List<List<Data?>> rows, int skipUntil) {
    final scores = <int, double>{};
    for (
      int ri = skipUntil + 1;
      ri < rows.length && ri < skipUntil + 20;
      ri++
    ) {
      for (int ci = 0; ci < rows[ri].length; ci++) {
        final val = _cellStr(rows[ri][ci]);
        final n = double.tryParse(val.replaceAll('.', '').replaceAll(',', '.'));
        if (n != null && n > 100) {
          scores[ci] = (scores[ci] ?? 0) + n;
        }
      }
    }
    if (scores.isEmpty) return -1;
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Generate kode obat dari nama + nomor baris.
  String _makeKode(String nama, int rowNum) {
    final words = nama.trim().toUpperCase().split(RegExp(r'\s+'));
    String prefix = '';
    for (int i = 0; i < words.length && i < 3; i++) {
      if (words[i].isNotEmpty) prefix += words[i][0];
    }
    if (prefix.isEmpty) prefix = 'OBT';
    return '$prefix-${rowNum.toString().padLeft(4, '0')}';
  }

  /// Cek apakah string adalah angka murni.
  bool _isNumericStr(String s) {
    return _parseFlexibleNumber(s) != null;
  }
}

class _ColumnMapping {
  final int kode;
  final int nama;
  final int hargaBeli;
  final int hargaJual;
  final int stok;
  final int stokMinimal;
  final int satuan;
  final int deskripsi;

  const _ColumnMapping({
    this.kode = -1,
    this.nama = -1,
    this.hargaBeli = -1,
    this.hargaJual = -1,
    this.stok = -1,
    this.stokMinimal = -1,
    this.satuan = -1,
    this.deskripsi = -1,
  });

  Set<int> get usedColumns {
    return {
      kode,
      nama,
      hargaBeli,
      hargaJual,
      stok,
      stokMinimal,
      satuan,
      deskripsi,
    }.where((index) => index >= 0).toSet();
  }

  Map<String, int> toPublicMap() {
    return {
      'kode': kode,
      'nama': nama,
      'hargaBeli': hargaBeli,
      'hargaJual': hargaJual,
      'stok': stok,
      'stokMinimal': stokMinimal,
      'deskripsi': deskripsi,
    };
  }

  _ColumnMapping copyWith({
    int? kode,
    int? nama,
    int? hargaBeli,
    int? hargaJual,
    int? stok,
    int? stokMinimal,
    int? satuan,
    int? deskripsi,
  }) {
    return _ColumnMapping(
      kode: kode ?? this.kode,
      nama: nama ?? this.nama,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      hargaJual: hargaJual ?? this.hargaJual,
      stok: stok ?? this.stok,
      stokMinimal: stokMinimal ?? this.stokMinimal,
      satuan: satuan ?? this.satuan,
      deskripsi: deskripsi ?? this.deskripsi,
    );
  }
}

class _ColumnDetection {
  final int headerIndex;
  final bool headerFound;
  final List<String> headerLabels;
  final _ColumnMapping mapping;

  const _ColumnDetection({
    required this.headerIndex,
    required this.headerFound,
    required this.headerLabels,
    required this.mapping,
  });
}

class _HeaderCandidate {
  final int index;
  final int score;
  final int recognizedFields;
  final List<String> labels;
  final _ColumnMapping mapping;

  const _HeaderCandidate({
    required this.index,
    required this.score,
    required this.recognizedFields,
    required this.labels,
    required this.mapping,
  });

  bool get isUsable {
    if (labels.where((value) => value.trim().isNotEmpty).length < 2) {
      return false;
    }
    if (recognizedFields < 2) return false;
    return mapping.nama >= 0 || recognizedFields >= 3;
  }
}

class _ColumnProfile {
  final int index;
  int nonEmpty = 0;
  int textLike = 0;
  int numericLike = 0;
  int integerLike = 0;
  int moneyLike = 0;
  int codeLike = 0;
  int totalTextLength = 0;
  final List<double> numbers = [];
  final List<double> moneyNumbers = [];

  _ColumnProfile(this.index);

  void add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;

    nonEmpty++;
    if (_looksLikeCodeValue(value)) codeLike++;

    final number = _parseFlexibleNumber(value);
    if (number == null) {
      textLike++;
      totalTextLength += value.length;
      return;
    }

    numericLike++;
    numbers.add(number);
    if ((number - number.round()).abs() < 0.0001) {
      integerLike++;
    }
    if (number >= 100 && number <= 100000000 && !_looksLikeDateValue(value)) {
      moneyLike++;
      moneyNumbers.add(number);
    }
  }

  double get medianNumber => _median(numbers);
  double get medianMoney => _median(moneyNumbers);
}

enum _ImportField {
  kode,
  nama,
  hargaBeli,
  hargaJual,
  stokMinimal,
  stok,
  satuan,
  deskripsi,
}

_ColumnDetection _detectColumnMappingFromRows(
  List<List<String>> rows, {
  bool fallbackToFirstRow = false,
}) {
  final header = _findBestHeader(rows);
  if (header != null) {
    final completed = _inferMappingFromData(
      rows,
      startIndex: header.index + 1,
      fixed: header.mapping,
    );
    return _ColumnDetection(
      headerIndex: header.index,
      headerFound: true,
      headerLabels: header.labels,
      mapping: completed,
    );
  }

  if (fallbackToFirstRow) {
    return const _ColumnDetection(
      headerIndex: 0,
      headerFound: false,
      headerLabels: [],
      mapping: _ColumnMapping(
        kode: 0,
        nama: 1,
        hargaBeli: 2,
        hargaJual: 3,
        stok: 4,
        stokMinimal: 5,
        deskripsi: 6,
      ),
    );
  }

  final inferred = _inferMappingFromData(rows);
  if (inferred.nama >= 0) {
    return _ColumnDetection(
      headerIndex: -1,
      headerFound: false,
      headerLabels: const [],
      mapping: inferred,
    );
  }

  return _ColumnDetection(
    headerIndex: -1,
    headerFound: false,
    headerLabels: const [],
    mapping: const _ColumnMapping(),
  );
}

_HeaderCandidate? _findBestHeader(List<List<String>> rows) {
  _HeaderCandidate? best;
  final maxRows = rows.length < 15 ? rows.length : 15;

  for (var ri = 0; ri < maxRows; ri++) {
    final candidate = _scoreHeaderRow(rows[ri], ri);
    if (candidate == null || !candidate.isUsable) continue;
    if (best == null ||
        candidate.score > best.score ||
        (candidate.score == best.score &&
            candidate.recognizedFields > best.recognizedFields)) {
      best = candidate;
    }
  }

  return best;
}

_HeaderCandidate? _scoreHeaderRow(List<String> row, int rowIndex) {
  final labels = row.map((value) => value.trim()).toList();
  final nonEmpty = labels.where((value) => value.isNotEmpty).length;
  if (nonEmpty < 2) return null;

  final assigned = <int>{};
  final fieldScores = <_ImportField, int>{};
  var mapping = const _ColumnMapping();

  for (final field in _ImportField.values) {
    var bestIndex = -1;
    var bestScore = 0;

    for (var ci = 0; ci < labels.length; ci++) {
      if (assigned.contains(ci)) continue;
      final score = _scoreHeaderForField(labels[ci], field);
      if (score > bestScore) {
        bestScore = score;
        bestIndex = ci;
      }
    }

    if (bestIndex < 0 || bestScore < 5) continue;
    assigned.add(bestIndex);
    fieldScores[field] = bestScore;

    switch (field) {
      case _ImportField.kode:
        mapping = mapping.copyWith(kode: bestIndex);
        break;
      case _ImportField.nama:
        mapping = mapping.copyWith(nama: bestIndex);
        break;
      case _ImportField.hargaBeli:
        mapping = mapping.copyWith(hargaBeli: bestIndex);
        break;
      case _ImportField.hargaJual:
        mapping = mapping.copyWith(hargaJual: bestIndex);
        break;
      case _ImportField.stokMinimal:
        mapping = mapping.copyWith(stokMinimal: bestIndex);
        break;
      case _ImportField.stok:
        mapping = mapping.copyWith(stok: bestIndex);
        break;
      case _ImportField.satuan:
        mapping = mapping.copyWith(satuan: bestIndex);
        break;
      case _ImportField.deskripsi:
        mapping = mapping.copyWith(deskripsi: bestIndex);
        break;
    }
  }

  if (fieldScores.isEmpty) return null;
  final score = fieldScores.values.fold<int>(0, (sum, value) => sum + value);
  return _HeaderCandidate(
    index: rowIndex,
    score: score + nonEmpty,
    recognizedFields: fieldScores.length,
    labels: labels.where((value) => value.isNotEmpty).toList(),
    mapping: mapping,
  );
}

int _scoreHeaderForField(String raw, _ImportField field) {
  final header = _normalizeHeader(raw);
  if (header.isEmpty || _isSummaryLabel(header)) return 0;

  switch (field) {
    case _ImportField.kode:
      if (_containsAny(header, ['kode obat', 'kode barang', 'kode produk'])) {
        return 16;
      }
      if (_containsAny(header, ['barcode', 'sku', 'plu', 'item code'])) {
        return 14;
      }
      if (_containsWord(header, 'kode') || _containsWord(header, 'code')) {
        return 12;
      }
      if (_containsAny(header, ['nomor urut', 'no urut']) ||
          header == 'no' ||
          header == 'nomor') {
        return 0;
      }
      return 0;

    case _ImportField.nama:
      if (_containsAny(header, [
        'nama obat',
        'nama barang',
        'nama produk',
        'drug name',
        'medicine name',
        'item name',
        'product name',
      ])) {
        return 18;
      }
      if (_containsWord(header, 'nama') || _containsWord(header, 'name')) {
        return 14;
      }
      if (header == 'obat' ||
          header == 'produk' ||
          header == 'product' ||
          header == 'item' ||
          header == 'barang' ||
          header == 'medicine' ||
          header == 'drug') {
        return 9;
      }
      return 0;

    case _ImportField.hargaBeli:
      if (_containsAny(header, ['jual', 'ecer', 'retail', 'sell', 'selling'])) {
        return 0;
      }
      if (_containsAny(header, [
        'harga beli',
        'h beli',
        'harga modal',
        'harga pokok',
        'purchase price',
        'buy price',
      ])) {
        return 18;
      }
      if (_containsAny(header, ['modal', 'hpp', 'cost', 'purchase', 'buy'])) {
        return 15;
      }
      return 0;

    case _ImportField.hargaJual:
      if (_containsAny(header, ['beli', 'modal', 'hpp', 'cost', 'purchase'])) {
        return 0;
      }
      if (_containsAny(header, [
        'harga jual',
        'h jual',
        'harga eceran',
        'harga ecer',
        'selling price',
        'sell price',
        'retail price',
      ])) {
        return 18;
      }
      if (_containsAny(header, ['jual', 'eceran', 'ecer', 'retail', 'sell'])) {
        return 15;
      }
      if (header == 'harga' ||
          header == 'price' ||
          header == 'harga rp' ||
          header == 'harga satuan' ||
          header == 'unit price') {
        return 10;
      }
      return 0;

    case _ImportField.stokMinimal:
      if (_containsAny(header, [
        'stok minimal',
        'stok minimum',
        'minimum stock',
        'min stock',
        'stok min',
        'safety stock',
        'reorder point',
        'batas minimal',
      ])) {
        return 18;
      }
      if (_containsAny(header, ['minimum', 'minimal', 'reorder'])) {
        return 12;
      }
      if (header == 'min') return 10;
      return 0;

    case _ImportField.stok:
      if (_containsAny(header, ['minimal', 'minimum', 'reorder', 'safety'])) {
        return 0;
      }
      if (_containsAny(header, [
        'stok tersedia',
        'stok saat ini',
        'jumlah stok',
        'sisa stok',
        'current stock',
        'stock on hand',
        'on hand',
      ])) {
        return 18;
      }
      if (_containsAny(header, [
        'stok',
        'stock',
        'qty',
        'quantity',
        'jumlah',
        'jml',
        'sisa',
        'saldo',
        'persediaan',
        'available',
      ])) {
        return 12;
      }
      return 0;

    case _ImportField.satuan:
      if (_containsAny(header, [
        'satuan',
        'unit',
        'kemasan',
        'packaging',
        'jenis satuan',
      ])) {
        return 12;
      }
      if (header == 'pack') return 10;
      return 0;

    case _ImportField.deskripsi:
      if (_containsAny(header, [
        'deskripsi',
        'description',
        'keterangan',
        'catatan',
        'notes',
        'indikasi',
        'detail',
        'info',
      ])) {
        return 12;
      }
      if (header == 'ket' || header == 'note') return 10;
      return 0;
  }
}

_ColumnMapping _inferMappingFromData(
  List<List<String>> rows, {
  int startIndex = 0,
  _ColumnMapping fixed = const _ColumnMapping(),
}) {
  final profiles = _buildColumnProfiles(rows, startIndex: startIndex);
  final used = fixed.usedColumns;

  var kode = fixed.kode;
  var nama = fixed.nama;
  var hargaBeli = fixed.hargaBeli;
  var hargaJual = fixed.hargaJual;
  var stok = fixed.stok;
  var stokMinimal = fixed.stokMinimal;
  var satuan = fixed.satuan;
  var deskripsi = fixed.deskripsi;

  if (kode < 0) {
    kode = _pickCodeColumn(profiles, used);
    if (kode >= 0) used.add(kode);
  }

  if (nama < 0) {
    nama = _pickNameColumn(profiles, used);
    if (nama >= 0) used.add(nama);
  }

  if (hargaBeli >= 0) used.add(hargaBeli);
  if (hargaJual >= 0) used.add(hargaJual);
  final pricePick = _pickPriceColumns(
    profiles,
    used,
    hargaBeli: hargaBeli,
    hargaJual: hargaJual,
  );
  hargaBeli = pricePick.hargaBeli;
  hargaJual = pricePick.hargaJual;
  if (hargaBeli >= 0) used.add(hargaBeli);
  if (hargaJual >= 0) used.add(hargaJual);

  if (stokMinimal >= 0) used.add(stokMinimal);
  if (stok >= 0) used.add(stok);
  if (stok < 0) {
    stok = _pickStockColumn(profiles, used);
    if (stok >= 0) used.add(stok);
  }
  if (stokMinimal < 0) {
    stokMinimal = _pickStockMinimalColumn(profiles, used, stokColumn: stok);
    if (stokMinimal >= 0) used.add(stokMinimal);
  }

  if (satuan < 0) satuan = _pickTextColumnBySamples(profiles, used);
  if (satuan >= 0) used.add(satuan);
  if (deskripsi < 0) deskripsi = _pickDescriptionColumn(profiles, used);

  return _ColumnMapping(
    kode: kode,
    nama: nama,
    hargaBeli: hargaBeli,
    hargaJual: hargaJual,
    stok: stok,
    stokMinimal: stokMinimal,
    satuan: satuan,
    deskripsi: deskripsi,
  );
}

Map<int, _ColumnProfile> _buildColumnProfiles(
  List<List<String>> rows, {
  int startIndex = 0,
}) {
  final profiles = <int, _ColumnProfile>{};
  final safeStart = startIndex < 0 ? 0 : startIndex;
  final end = rows.length < safeStart + 60 ? rows.length : safeStart + 60;

  for (var ri = safeStart; ri < end; ri++) {
    final row = rows[ri];
    if (_looksLikeHeaderRow(row)) continue;
    for (var ci = 0; ci < row.length; ci++) {
      profiles.putIfAbsent(ci, () => _ColumnProfile(ci)).add(row[ci]);
    }
  }
  return profiles;
}

int _pickCodeColumn(Map<int, _ColumnProfile> profiles, Set<int> used) {
  var bestIndex = -1;
  var bestScore = 0;
  for (final profile in profiles.values) {
    if (used.contains(profile.index) || profile.nonEmpty == 0) continue;
    final serialPenalty = _looksLikeSerialColumn(profile) ? 30 : 0;
    final score =
        (profile.codeLike * 20) +
        (profile.textLike * 2) -
        (profile.numericLike * 3) -
        serialPenalty;
    if (profile.codeLike > 0 && score > bestScore) {
      bestScore = score;
      bestIndex = profile.index;
    }
  }
  return bestScore >= 12 ? bestIndex : -1;
}

int _pickNameColumn(Map<int, _ColumnProfile> profiles, Set<int> used) {
  var bestIndex = -1;
  var bestScore = 0;
  for (final profile in profiles.values) {
    if (used.contains(profile.index) || profile.textLike == 0) continue;
    final codePenalty = profile.codeLike * 18;
    final score =
        (profile.textLike * 24) +
        profile.totalTextLength -
        (profile.numericLike * 20) -
        codePenalty;
    if (score > bestScore) {
      bestScore = score;
      bestIndex = profile.index;
    }
  }
  return bestScore > 0 ? bestIndex : -1;
}

_ColumnMapping _pickPriceColumns(
  Map<int, _ColumnProfile> profiles,
  Set<int> used, {
  required int hargaBeli,
  required int hargaJual,
}) {
  final candidates =
      profiles.values.where((profile) {
        if (used.contains(profile.index)) return false;
        if (profile.moneyLike == 0) return false;
        if (_looksLikeSerialColumn(profile)) return false;
        if (profile.codeLike > profile.moneyLike) return false;
        return true;
      }).toList()..sort((a, b) {
        final byMedian = b.medianMoney.compareTo(a.medianMoney);
        if (byMedian != 0) return byMedian;
        return b.moneyLike.compareTo(a.moneyLike);
      });

  var buy = hargaBeli;
  var sell = hargaJual;
  if (sell < 0 && candidates.isNotEmpty) {
    sell = candidates.removeAt(0).index;
  }

  if (buy < 0 && candidates.isNotEmpty) {
    final sellMedian = profiles[sell]?.medianMoney ?? 0;
    for (final candidate in candidates) {
      final median = candidate.medianMoney;
      final reasonablePair =
          sellMedian <= 0 ||
          (median <= sellMedian * 1.15 && sellMedian / median <= 10);
      if (reasonablePair) {
        buy = candidate.index;
        break;
      }
    }
  }

  return _ColumnMapping(hargaBeli: buy, hargaJual: sell);
}

int _pickStockColumn(Map<int, _ColumnProfile> profiles, Set<int> used) {
  var bestIndex = -1;
  var bestScore = -999999;
  for (final profile in profiles.values) {
    if (used.contains(profile.index) || profile.numericLike == 0) continue;
    if (_looksLikeSerialColumn(profile)) continue;
    if (profile.integerLike < (profile.numericLike * 0.7)) continue;
    final median = profile.medianNumber;
    if (median < 0 || median > 100000) continue;
    final score =
        (profile.integerLike * 16) -
        (profile.moneyLike * 5) -
        (median > 1000 ? 30 : 0) +
        (median > 0 ? median.clamp(0, 1000).round() ~/ 20 : 0);
    if (score > bestScore) {
      bestScore = score;
      bestIndex = profile.index;
    }
  }
  return bestScore > 0 ? bestIndex : -1;
}

int _pickStockMinimalColumn(
  Map<int, _ColumnProfile> profiles,
  Set<int> used, {
  required int stokColumn,
}) {
  final stockMedian = profiles[stokColumn]?.medianNumber;
  var bestIndex = -1;
  var bestScore = -999999;
  for (final profile in profiles.values) {
    if (used.contains(profile.index) || profile.numericLike == 0) continue;
    if (_looksLikeSerialColumn(profile)) continue;
    if (profile.integerLike < (profile.numericLike * 0.7)) continue;
    final median = profile.medianNumber;
    if (median < 0 || median > 100000) continue;
    if (stockMedian != null && stockMedian > 0 && median > stockMedian) {
      continue;
    }
    final score =
        (profile.integerLike * 12) -
        (profile.moneyLike * 8) -
        median.clamp(0, 1000).round();
    if (score > bestScore) {
      bestScore = score;
      bestIndex = profile.index;
    }
  }
  return bestScore > 0 ? bestIndex : -1;
}

int _pickTextColumnBySamples(Map<int, _ColumnProfile> profiles, Set<int> used) {
  var bestIndex = -1;
  var bestScore = 0;
  for (final profile in profiles.values) {
    if (used.contains(profile.index) || profile.textLike == 0) continue;
    final score = profile.textLike * 8 - profile.totalTextLength;
    if (score > bestScore) {
      bestScore = score;
      bestIndex = profile.index;
    }
  }
  return bestScore > 0 ? bestIndex : -1;
}

int _pickDescriptionColumn(Map<int, _ColumnProfile> profiles, Set<int> used) {
  var bestIndex = -1;
  var bestScore = 0;
  for (final profile in profiles.values) {
    if (used.contains(profile.index) || profile.textLike == 0) continue;
    final score = profile.totalTextLength + profile.textLike * 4;
    if (score > bestScore) {
      bestScore = score;
      bestIndex = profile.index;
    }
  }
  return bestScore > 0 ? bestIndex : -1;
}

bool _looksLikeHeaderRow(List<String> row) {
  final candidate = _scoreHeaderRow(row, 0);
  return candidate != null && candidate.isUsable && candidate.score >= 18;
}

bool _isSummaryRow(List<String> row, int namaColumn) {
  if (namaColumn < 0 || namaColumn >= row.length) return false;
  return _isSummaryLabel(_normalizeHeader(row[namaColumn]));
}

bool _isSummaryLabel(String value) {
  return value == 'total' ||
      value == 'subtotal' ||
      value == 'grand total' ||
      value == 'jumlah total' ||
      value == 'total keseluruhan';
}

String _normalizeHeader(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-/\\]+'), ' ')
      .replaceAll(RegExp(r'[\(\)\[\]\{\}:;,.]+'), ' ')
      .replaceAll(RegExp(r'\brp\b'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _containsAny(String value, List<String> needles) {
  return needles.any((needle) => value.contains(needle));
}

bool _containsWord(String value, String word) {
  return RegExp('(^|\\s)${RegExp.escape(word)}(\\s|\$)').hasMatch(value);
}

bool _looksLikeSerialColumn(_ColumnProfile profile) {
  if (profile.numbers.length < 3) return false;
  if (profile.integerLike < profile.numbers.length * 0.9) return false;
  var sequential = 0;
  for (var i = 0; i < profile.numbers.length; i++) {
    if (profile.numbers[i].round() == i + 1) sequential++;
  }
  if (sequential >= profile.numbers.length * 0.7) return true;
  return profile.index == 0 &&
      profile.medianNumber <= profile.numbers.length + 5 &&
      profile.numbers.every((value) => value >= 0 && value <= 999);
}

bool _looksLikeCodeValue(String raw) {
  final value = raw.trim();
  if (value.isEmpty || _looksLikeDateValue(value)) return false;
  final compact = value.replaceAll(RegExp(r'\s+'), '');
  if (RegExp(r'^\d+$').hasMatch(compact)) return compact.length >= 6;
  final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(compact);
  final hasDigit = RegExp(r'\d').hasMatch(compact);
  if (hasLetter && hasDigit && !value.contains(' ') && compact.length <= 32) {
    return true;
  }
  return RegExp(r'^[a-zA-Z0-9]+[-_/][a-zA-Z0-9]+').hasMatch(compact) &&
      compact.length <= 32;
}

bool _looksLikeDateValue(String raw) {
  final value = raw.trim();
  return RegExp(r'^\d{4}[-/]\d{1,2}[-/]\d{1,2}$').hasMatch(value) ||
      RegExp(r'^\d{1,2}[-/]\d{1,2}[-/]\d{2,4}$').hasMatch(value);
}

double? _parseFlexibleNumber(String raw) {
  var value = raw.trim();
  if (value.isEmpty || _looksLikeDateValue(value)) return null;

  value = value
      .toLowerCase()
      .replaceAll(RegExp(r'^(rp|idr|usd)\.?\s*'), '')
      .replaceAll(RegExp(r'\s*(rp|idr|usd)\.?$'), '')
      .replaceAll(r'$', '')
      .trim();

  if (RegExp(r'[a-zA-Z]').hasMatch(value)) return null;

  var cleaned = value.replaceAll(RegExp(r'[^0-9,.\-]'), '');
  if (cleaned.isEmpty || cleaned == '-') return null;

  final isNegative = cleaned.startsWith('-');
  cleaned = cleaned.replaceAll('-', '').replaceAll(RegExp(r'[,.]+$'), '');
  if (cleaned.isEmpty) return null;

  String normalized;
  final dotCount = '.'.allMatches(cleaned).length;
  final commaCount = ','.allMatches(cleaned).length;

  if (dotCount > 0 && commaCount > 0) {
    final lastDot = cleaned.lastIndexOf('.');
    final lastComma = cleaned.lastIndexOf(',');
    final decimalSeparator = lastDot > lastComma ? '.' : ',';
    final thousandSeparator = decimalSeparator == '.' ? ',' : '.';
    normalized = cleaned
        .replaceAll(thousandSeparator, '')
        .replaceAll(decimalSeparator, '.');
  } else if (dotCount > 0 || commaCount > 0) {
    final separator = dotCount > 0 ? '.' : ',';
    final count = dotCount > 0 ? dotCount : commaCount;
    if (count > 1) {
      normalized = cleaned.replaceAll(separator, '');
    } else {
      final index = cleaned.indexOf(separator);
      final digitsAfter = cleaned.length - index - 1;
      if (digitsAfter == 0) {
        normalized = cleaned.replaceAll(separator, '');
      } else if (digitsAfter == 3) {
        normalized = cleaned.replaceAll(separator, '');
      } else if (digitsAfter <= 2) {
        normalized = cleaned.replaceAll(separator, '.');
      } else {
        normalized = cleaned.replaceAll(separator, '');
      }
    }
  } else {
    normalized = cleaned;
  }

  final parsed = double.tryParse('${isNegative ? "-" : ""}$normalized');
  if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
  return parsed;
}

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  return (sorted[middle - 1] + sorted[middle]) / 2;
}

// ──────────────────────────────────────────────────────────────────────────────
// PUBLIC HELPER — digunakan oleh unit test
// Mendeteksi mapping kolom dari list baris (List<List<dynamic>>)
// Mengembalikan Map dengan key: 'kode','nama','hargaBeli','hargaJual','stok',
//   'stokMinimal','deskripsi' → nilai int (indeks kolom, atau -1 jika tidak ada)
// ──────────────────────────────────────────────────────────────────────────────
String sanitizeExcelStylesXml(String xml) {
  final numFmtTagPattern = RegExp(
    r'<numFmt\b[^>]*/>|<numFmt\b[\s\S]*?</numFmt>',
    caseSensitive: false,
  );
  final numFmtIdPattern = RegExp(
    'numFmtId\\s*=\\s*([\'"])(\\d+)\\1',
    caseSensitive: false,
  );

  final usedIds = <int>{};
  for (final match in numFmtTagPattern.allMatches(xml)) {
    final idMatch = numFmtIdPattern.firstMatch(match.group(0)!);
    final id = int.tryParse(idMatch?.group(2) ?? '');
    if (id != null && id >= 164) {
      usedIds.add(id);
    }
  }

  var nextCustomId = 164;
  int allocateCustomId() {
    while (usedIds.contains(nextCustomId)) {
      nextCustomId++;
    }
    usedIds.add(nextCustomId);
    return nextCustomId++;
  }

  final remappedIds = <int, int>{};
  final rewrittenXml = xml.replaceAllMapped(numFmtTagPattern, (match) {
    final tag = match.group(0)!;
    final idMatch = numFmtIdPattern.firstMatch(tag);
    final oldId = int.tryParse(idMatch?.group(2) ?? '');
    if (oldId == null || oldId >= 164) return tag;

    final newId = remappedIds.putIfAbsent(oldId, allocateCustomId);
    return tag.replaceAllMapped(numFmtIdPattern, (idMatch) {
      final quote = idMatch.group(1)!;
      return 'numFmtId=$quote$newId$quote';
    });
  });

  if (remappedIds.isEmpty) return xml;

  var normalizedXml = rewrittenXml;
  for (final entry in remappedIds.entries) {
    final referencePattern = RegExp(
      'numFmtId\\s*=\\s*([\'"])${entry.key}\\1',
      caseSensitive: false,
    );
    normalizedXml = normalizedXml.replaceAllMapped(referencePattern, (match) {
      final quote = match.group(1)!;
      return 'numFmtId=$quote${entry.value}$quote';
    });
  }

  return normalizedXml;
}

Map<String, int> detectColumnMapping(
  List<List<dynamic>> rows, {
  bool fallbackToFirstRow = false,
}) {
  final stringRows = rows
      .map((row) => row.map((value) => value?.toString().trim() ?? '').toList())
      .toList();
  final mapped = _detectColumnMappingFromRows(
    stringRows,
    fallbackToFirstRow: fallbackToFirstRow,
  ).mapping.toPublicMap();
  if (mapped.isNotEmpty) return mapped;

  bool isNum(String s) {
    final c = s.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(c) != null;
  }

  // ── Cari baris header (teks, maks 5 baris) ──
  int headerIdx = -1;
  Map<String, int> headerMap = {};

  for (int ri = 0; ri < rows.length && ri < 5; ri++) {
    final row = rows[ri];
    final candidate = <String, int>{};
    bool hasText = false;
    for (int ci = 0; ci < row.length; ci++) {
      final val = row[ci]?.toString().trim() ?? '';
      if (val.isEmpty) continue;
      candidate[val.toLowerCase()] = ci;
      if (!isNum(val)) hasText = true;
    }
    // Butuh minimal 2 cell agar tidak salah ambil baris judul tunggal
    if (hasText && candidate.length >= 2) {
      headerIdx = ri;
      headerMap = candidate;
      break;
    }
  }

  // ── Fungsi cari indeks dari header map ──
  int? findCol(List<String> keys) {
    for (final k in keys) {
      if (headerMap.containsKey(k)) return headerMap[k];
    }
    for (final entry in headerMap.entries) {
      for (final k in keys) {
        if (entry.key.contains(k) || k.contains(entry.key)) return entry.value;
      }
    }
    return null;
  }

  if (headerIdx >= 0) {
    // ── Header ditemukan — petakan ke indeks kolom ──
    final mapped = {
      'kode':
          findCol(['kode obat', 'kode', 'code', 'sku', 'kode barang']) ?? -1,
      'nama':
          findCol(['nama obat', 'nama barang', 'nama', 'name', 'obat']) ?? -1,
      'hargaBeli':
          findCol([
            'harga beli (rp)',
            'harga beli',
            'hargabeli',
            'modal',
            'cost',
          ]) ??
          -1,
      'hargaJual':
          findCol([
            'harga jual (rp)',
            'harga jual',
            'hargajual',
            'harga',
            'price',
          ]) ??
          -1,
      'stok':
          findCol([
            'stok saat ini',
            'stok tersedia',
            'stok',
            'stock',
            'qty',
            'jumlah',
          ]) ??
          -1,
      'stokMinimal':
          findCol(['stok min', 'stok minimal', 'minimal', 'minimum', 'min']) ??
          -1,
      'deskripsi':
          findCol([
            'keterangan',
            'deskripsi',
            'description',
            'catatan',
            'note',
          ]) ??
          -1,
    };

    // Jika tidak ada satu pun kolom yang dikenali, header ini mungkin baris data biasa.
    // Gunakan fallback posisional jika diminta.
    final anyRecognized = mapped.values.any((v) => v >= 0);
    if (anyRecognized) return mapped;
    // Jika tidak ada yang cocok dan fallback diminta → lanjut ke bawah
  }

  if (fallbackToFirstRow) {
    // ── Fallback posisional ──
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

  // Tidak terdeteksi sama sekali
  return {
    'kode': -1,
    'nama': -1,
    'hargaBeli': -1,
    'hargaJual': -1,
    'stok': -1,
    'stokMinimal': -1,
    'deskripsi': -1,
  };
}
