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

    test('mendeteksi format stok Firdan Farma dengan header dua baris', () {
      final rows = <List<dynamic>>[
        [
          'No',
          'Nama Barang',
          'SATUAN',
          '',
          '',
          '',
          '',
          'HargaBeli',
          'HargaJual',
        ],
        [
          '',
          '',
          '',
          'AWL(stok awal masuk)',
          'MSK (Pemasukan setiap beli dari supplier)',
          'KLR (penjualan keluar per harinya)',
          'SISA',
          '',
          '',
        ],
        ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
        ['1', 'ACETON', 'FLES', '1', '', '0', '1', '7665', '10000'],
        ['2', 'ACID SALICYL', 'GR', '70', '', '0', '70', '2000', '3000'],
      ];

      final mapping = detectColumnMapping(rows);

      expect(mapping['kode'], -1);
      expect(mapping['nama'], 1);
      expect(mapping['satuan'], 2);
      expect(mapping['awl'], 3);
      expect(mapping['msk'], 4);
      expect(mapping['klr'], 5);
      expect(mapping['stok'], 6);
      expect(mapping['hargaBeli'], 7);
      expect(mapping['hargaJual'], 8);
      expect(mapping['stokMinimal'], -1);
      expect(mapping['deskripsi'], -1);
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

    test(
      'import format Firdan Farma memakai SISA dan menyimpan satuan',
      () async {
        await DatabaseHelper.openInMemoryForTesting();
        addTearDown(DatabaseHelper.instance.closeAndReset);

        final tempDir = await Directory.systemTemp.createTemp(
          'firdan_import_format_test_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        final excel = Excel.createExcel();
        final sheet = excel['Sheet1'];
        excel.setDefaultSheet('Sheet1');
        sheet.appendRow([
          TextCellValue('No'),
          TextCellValue('Nama Barang'),
          TextCellValue('SATUAN'),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue('HargaBeli'),
          TextCellValue('HargaJual'),
        ]);
        sheet.appendRow([
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue('AWL(stok awal masuk)'),
          TextCellValue('MSK (Pemasukan setiap beli dari supplier)'),
          TextCellValue('KLR (penjualan keluar per harinya)'),
          TextCellValue('SISA'),
          TextCellValue(''),
          TextCellValue(''),
        ]);
        sheet.appendRow([
          TextCellValue('1'),
          TextCellValue('2'),
          TextCellValue('3'),
          TextCellValue('4'),
          TextCellValue('5'),
          TextCellValue('6'),
          TextCellValue('7'),
          TextCellValue('8'),
          TextCellValue('9'),
        ]);
        sheet.appendRow([
          IntCellValue(1),
          TextCellValue('ACETON'),
          TextCellValue('FLES'),
          IntCellValue(1),
          TextCellValue(''),
          IntCellValue(0),
          IntCellValue(1),
          DoubleCellValue(7665),
          DoubleCellValue(10000),
        ]);
        sheet.appendRow([
          TextCellValue(''),
          TextCellValue('GRAND TOTAL'),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
        ]);
        sheet.appendRow([
          TextCellValue(''),
          TextCellValue('SISA STOK'),
          TextCellValue('0'),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
        ]);

        final file = File('${tempDir.path}${Platform.pathSeparator}obat.xlsx');
        await file.writeAsBytes(excel.save()!, flush: true);

        final result = await SpreadsheetService().importSpreadsheetToDb(
          file.path,
        );
        final obatList = await ObatService().getAll(includeInactive: true);
        final aceton = obatList.singleWhere((obat) => obat.nama == 'ACETON');

        expect(result.inserted, 1);
        expect(result.skipped, 4);
        expect(obatList.any((obat) => obat.nama == '2'), isFalse);
        expect(obatList.any((obat) => obat.nama == 'SISA STOK'), isFalse);
        expect(aceton.kodeObat, 'A-0004');
        expect(aceton.satuan, 'FLES');
        expect(aceton.awl, 1);
        expect(aceton.msk, 0);
        expect(aceton.klr, 0);
        expect(aceton.hargaBeli, 7665);
        expect(aceton.hargaJual, 10000);
        expect(aceton.stokTersedia, 1);
        expect(aceton.stokMinimal, 5);
        expect(aceton.deskripsi, isNull);
      },
    );
  });
}
