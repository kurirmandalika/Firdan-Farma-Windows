import 'package:intl/intl.dart';
import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/detail_transaksi_model.dart';
import 'package:firdan_farma_windows/data/models/transaksi_model.dart';

class TransaksiService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String> generateNomorTransaksi() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final datePrefix = DateFormat('yyyyMMdd').format(now);

    final maps = await db.rawQuery(
      "SELECT COUNT(*) as count FROM transaksi WHERE nomor_transaksi LIKE ?",
      ['TRX-$datePrefix-%'],
    );
    final count = (maps.first['count'] as int? ?? 0) + 1;
    final formattedCount = count.toString().padLeft(4, '0');
    return 'TRX-$datePrefix-$formattedCount';
  }

  Future<Transaksi?> createTransaksi({
    required double total,
    required double bayar,
    String metodePembayaran = 'TUNAI',
    required List<DetailTransaksi> items,
  }) async {
    if (items.isEmpty) return null;
    final normalizedPayment = metodePembayaran.trim().toUpperCase();
    if (normalizedPayment == 'TUNAI' && bayar < total) {
      throw Exception('Nominal pembayaran kurang dari total belanja!');
    }

    final db = await _dbHelper.database;
    final nomorTx = await generateNomorTransaksi();
    final nowStr = DateTime.now().toIso8601String();
    final paid = normalizedPayment == 'TUNAI' ? bayar : total;
    final kembali = normalizedPayment == 'TUNAI' ? paid - total : 0.0;
    final totalItemCount = items.fold<int>(0, (sum, item) => sum + item.jumlah);

    return await db.transaction((txn) async {
      // 1. Verify stock availability
      for (final item in items) {
        final obatMaps = await txn.query(
          'obat',
          where: 'id = ?',
          whereArgs: [item.obatId],
        );
        if (obatMaps.isEmpty) {
          throw Exception('Obat ID ${item.obatId} tidak ditemukan!');
        }
        final stok = obatMaps.first['stok_tersedia'] as int;
        final isActive = (obatMaps.first['is_active'] as int? ?? 1) == 1;
        if (!isActive) {
          final nama = obatMaps.first['nama'] as String;
          throw Exception(
            'Obat "$nama" sudah nonaktif dan tidak dapat dijual.',
          );
        }
        if (stok < item.jumlah) {
          final nama = obatMaps.first['nama'] as String;
          throw Exception(
            'Stok obat "$nama" tidak mencukupi (tersedia: $stok, diminta: ${item.jumlah})',
          );
        }
      }

      // 2. Insert transaksi master record
      final txId = await txn.insert('transaksi', {
        'nomor_transaksi': nomorTx,
        'total': total,
        'bayar': paid,
        'kembali': kembali,
        'metode_pembayaran': normalizedPayment,
        'tanggal': nowStr,
        'jumlah_item': totalItemCount,
      });

      List<DetailTransaksi> savedDetails = [];

      // 3. Insert details and update stock
      for (final item in items) {
        final obatMaps = await txn.query(
          'obat',
          where: 'id = ?',
          whereArgs: [item.obatId],
        );
        final obat = obatMaps.first;
        final stokSebelum = obat['stok_tersedia'] as int;
        final stokSesudah = stokSebelum - item.jumlah;
        final hargaModal = item.hargaModalSatuan > 0
            ? item.hargaModalSatuan
            : (obat['harga_beli'] as num).toDouble();
        final hargaJual = item.hargaSatuan;
        final subtotal = hargaJual * item.jumlah;
        final subtotalModal = hargaModal * item.jumlah;
        final labaKotor = subtotal - subtotalModal;
        final namaObat = item.namaObat ?? obat['nama'] as String?;
        final kodeObat = item.kodeObat ?? obat['kode_obat'] as String?;

        final detailId = await txn.insert('detail_transaksi', {
          'transaksi_id': txId,
          'obat_id': item.obatId,
          'jumlah': item.jumlah,
          'harga_satuan': hargaJual,
          'harga_modal_satuan': hargaModal,
          'subtotal': subtotal,
          'subtotal_modal': subtotalModal,
          'laba_kotor': labaKotor,
          'nama_obat_snapshot': namaObat,
          'kode_obat_snapshot': kodeObat,
        });

        // Decrement stock
        await txn.update(
          'obat',
          {'stok_tersedia': stokSesudah, 'updated_at': nowStr},
          where: 'id = ?',
          whereArgs: [item.obatId],
        );

        // Record stock mutation
        await txn.insert('stok', {
          'obat_id': item.obatId,
          'jenis': 'keluar',
          'jumlah': item.jumlah,
          'tipe_mutasi': 'PENJUALAN',
          'reference_type': 'transaksi',
          'reference_id': txId,
          'harga_beli_snapshot': hargaModal,
          'stok_sebelum': stokSebelum,
          'stok_sesudah': stokSesudah,
          'alasan': 'PENJUALAN',
          'catatan': 'Penjualan Kasir $nomorTx',
          'tanggal': nowStr,
          'created_at': nowStr,
        });

        savedDetails.add(
          DetailTransaksi(
            id: detailId,
            transaksiId: txId,
            obatId: item.obatId,
            jumlah: item.jumlah,
            hargaSatuan: hargaJual,
            hargaModalSatuan: hargaModal,
            subtotal: subtotal,
            subtotalModal: subtotalModal,
            labaKotor: labaKotor,
            namaObat: namaObat,
            kodeObat: kodeObat,
          ),
        );
      }

      return Transaksi(
        id: txId,
        nomorTransaksi: nomorTx,
        total: total,
        bayar: paid,
        kembali: kembali,
        metodePembayaran: normalizedPayment,
        tanggal: nowStr,
        jumlahItem: totalItemCount,
        items: savedDetails,
      );
    });
  }

  Future<List<Transaksi>> getAll({int limit = 100}) async {
    final db = await _dbHelper.database;
    final txMaps = await db.query(
      'transaksi',
      orderBy: 'id DESC',
      limit: limit,
    );

    List<Transaksi> result = [];
    for (final map in txMaps) {
      final txId = map['id'] as int;
      final detailMaps = await db.rawQuery(
        '''
        SELECT d.*, o.nama AS nama_obat, o.kode_obat AS kode_obat
        FROM detail_transaksi d
        LEFT JOIN obat o ON d.obat_id = o.id
        WHERE d.transaksi_id = ?
      ''',
        [txId],
      );

      final items = detailMaps.map((d) => DetailTransaksi.fromMap(d)).toList();
      result.add(Transaksi.fromMap(map, items: items));
    }
    return result;
  }

  Future<int> getTodayCount() async {
    final db = await _dbHelper.database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM transaksi WHERE tanggal LIKE ?",
      ['$todayStr%'],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<double> getTodayRevenue() async {
    final db = await _dbHelper.database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await db.rawQuery(
      "SELECT SUM(total) as sum FROM transaksi WHERE tanggal LIKE ?",
      ['$todayStr%'],
    );
    return (result.first['sum'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTodayGrossProfit() async {
    final db = await _dbHelper.database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final result = await db.rawQuery(
      '''
      SELECT SUM(COALESCE(d.laba_kotor,
             d.subtotal - (COALESCE(d.harga_modal_satuan, o.harga_beli, 0) * d.jumlah)
      )) as sum
      FROM detail_transaksi d
      JOIN transaksi t ON d.transaksi_id = t.id
      LEFT JOIN obat o ON d.obat_id = o.id
      WHERE t.tanggal LIKE ?
      ''',
      ['$todayStr%'],
    );
    return (result.first['sum'] as num?)?.toDouble() ?? 0.0;
  }
}
