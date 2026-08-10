import 'package:flutter_test/flutter_test.dart';
import 'package:firdan_farma_windows/services/spreadsheet_service.dart';

void main() {
  group('Spreadsheet import column detection', () {
    test('mendeteksi header dari Excel yang tidak sama persis dengan template', () {
      final rows = <List<dynamic>>[
        ['Daftar Stok Obat Apotek'],
        ['Kode Barang', 'Nama Barang', 'Harga Beli (Rp)', 'Harga Jual (Rp)', 'Stok Saat Ini', 'Stok Min', 'Keterangan'],
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
    });

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
  });
}
