import 'package:flutter_test/flutter_test.dart';
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
  });
}
