import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';
import 'package:firdan_farma_windows/data/services/obat_service.dart';
import 'package:firdan_farma_windows/data/services/spreadsheet_service.dart';

void main() {
  group('Spreadsheet import column detection', () {
    test('menormalkan custom numFmtId Excel yang berada di bawah 164', () {
      const stylesXml = '''
<styleSheet>
  <numFmts count="2">
    <numFmt numFmtId="42" formatCode="_-* #,##0_-"/>
    <numFmt numFmtId="164" formatCode="dd/mm/yyyy"/>
  </numFmts>
  <cellXfs count="1">
    <xf numFmtId="42" fontId="0" fillId="0" borderId="0"/>
  </cellXfs>
</styleSheet>
''';

      final normalized = sanitizeExcelStylesXml(stylesXml);

      expect(normalized, isNot(contains('numFmtId="42"')));
      expect(normalized, contains('numFmtId="165"'));
      expect(normalized, contains('numFmtId="164"'));
    });

    test(
      'mendeteksi header dari Excel yang tidak sama persis dengan template',
      () {
        final rows = <List<dynamic>>[
          ['Daftar Stok Obat Apotek'],
          [
            'Kode Barang',
            'Nama Barang',
            'Harga Beli (Rp)',
            'Harga Jual (Rp)',
            'Stok Saat Ini',
            'Stok Min',
            'Keterangan',
          ],
          ['OBT-001', 'Paracetamol', 5000, 8000, 25, 10, 'Obat umum'],
        ];

        final mapping = detectColumnMapping(rows);

        expect(mapping['kode'], 0);
        expect(mapping['nama'], 1);
        expect(mapping['hargaBeli'], 2);
        expect(mapping['hargaJual'], 3);
        expect(mapping['stok'], 4);
        expect(mapping['stokMinimal'], 5);
        expect(mapping['deskripsi'], 6);
      },
    );

    test('fallback ke baris pertama saat header tidak terdeteksi', () {
      final rows = <List<dynamic>>[
        ['OBT-001', 'Paracetamol', 5000, 8000, 20],
      ];

      final mapping = detectColumnMapping(rows, fallbackToFirstRow: true);

      expect(mapping['kode'], 0);
      expect(mapping['nama'], 1);
      expect(mapping['hargaBeli'], 2);
      expect(mapping['hargaJual'], 3);
      expect(mapping['stok'], 4);
      expect(mapping['stokMinimal'], 5);
      expect(mapping['deskripsi'], 6);
    });

    test('melewati baris judul dan tidak menganggap kolom No sebagai kode', () {
      final rows = <List<dynamic>>[
        ['Daftar Stok Obat Apotek'],
        ['Periode Agustus 2026'],
        ['No', 'Nama Barang', 'Harga Modal', 'Harga Eceran', 'Stok Akhir'],
        [1, 'Paracetamol 500mg', 5000, 8000, 25],
        [2, 'Amoxicillin 500mg', 6500, 10000, 9],
      ];

      final mapping = detectColumnMapping(rows);

      expect(mapping['kode'], -1);
      expect(mapping['nama'], 1);
      expect(mapping['hargaBeli'], 2);
      expect(mapping['hargaJual'], 3);
      expect(mapping['stok'], 4);
    });

    test('tidak menukar harga beli dan harga jual pada header umum', () {
      final rows = <List<dynamic>>[
        ['Nama', 'Modal', 'Harga', 'Qty'],
        ['Vitamin C 500mg', 'Rp 12.500', '18,000', 12],
      ];

      final mapping = detectColumnMapping(rows);

      expect(mapping['nama'], 0);
      expect(mapping['hargaBeli'], 1);
      expect(mapping['hargaJual'], 2);
      expect(mapping['stok'], 3);
    });

    test('inferensi tanpa header menjaga barcode, nama, dan harga sebaris', () {
      final rows = <List<dynamic>>[
        ['8991234567890', 'Paracetamol 500mg', 'Rp5.000', '8,000', 25],
        ['8991234567891', 'Amoxicillin 500mg', '6.500', '10.000', 9],
      ];

      final mapping = detectColumnMapping(rows);

      expect(mapping['kode'], 0);
      expect(mapping['nama'], 1);
      expect(mapping['hargaBeli'], 2);
      expect(mapping['hargaJual'], 3);
      expect(mapping['stok'], 4);
    });

    test('import memperbarui stok obat lama lewat mutasi resmi', () async {
      await DatabaseHelper.openInMemoryForTesting();
      addTearDown(DatabaseHelper.instance.closeAndReset);

      final obatService = ObatService();
      final obatId = await obatService.insert(
        Obat(
          nama: 'Paracetamol 500mg',
          kodeObat: 'OBT-IMPORT-001',
          satuan: 'STRIP',
          kategoriId: 1,
          hargaBeli: 5000,
          hargaJual: 8000,
          stokTersedia: 10,
          stokMinimal: 5,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      final tempDir = await Directory.systemTemp.createTemp(
        'firdan_import_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final excel = Excel.createExcel();
      final sheet = excel['Data Obat'];
      excel.setDefaultSheet('Data Obat');
      sheet.appendRow([
        TextCellValue('Kode Obat'),
        TextCellValue('Nama Obat'),
        TextCellValue('Harga Beli'),
        TextCellValue('Harga Jual'),
        TextCellValue('Stok Tersedia'),
        TextCellValue('Stok Minimal'),
      ]);
      sheet.appendRow([
        TextCellValue('OBT-IMPORT-001'),
        TextCellValue('Paracetamol 500mg'),
        DoubleCellValue(5200),
        DoubleCellValue(8500),
        IntCellValue(17),
        IntCellValue(4),
      ]);

      final file = File('${tempDir.path}${Platform.pathSeparator}obat.xlsx');
      await file.writeAsBytes(excel.save()!, flush: true);

      final result = await SpreadsheetService().importSpreadsheetToDb(
        file.path,
      );
      final updatedObat = await obatService.getById(obatId);
      final db = await DatabaseHelper.instance.database;
      final importMutations = await db.query(
        'stok',
        where: 'obat_id = ? AND reference_type = ?',
        whereArgs: [obatId, 'stok_opname'],
      );

      expect(result.updated, 1);
      expect(updatedObat?.hargaBeli, 5200);
      expect(updatedObat?.hargaJual, 8500);
      expect(updatedObat?.stokTersedia, 17);
      expect(updatedObat?.stokMinimal, 4);
      expect(importMutations, hasLength(1));
      expect(importMutations.single['stok_sebelum'], 10);
      expect(importMutations.single['stok_sesudah'], 17);
      expect(importMutations.single['alasan'], 'IMPORT_XLSX');
    });
  });
}
