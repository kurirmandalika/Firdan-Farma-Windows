import '../database/database_helper.dart';

class LaporanRingkasan {
  final double totalPenjualan;
  final int totalTransaksi;
  final int totalItemTerjual;
  final double totalEstKeuntungan;

  LaporanRingkasan({
    required this.totalPenjualan,
    required this.totalTransaksi,
    required this.totalItemTerjual,
    required this.totalEstKeuntungan,
  });
}

class ObatTerlarisItem {
  final String namaObat;
  final String kodeObat;
  final int totalTerjual;
  final double totalSubtotal;

  ObatTerlarisItem({
    required this.namaObat,
    required this.kodeObat,
    required this.totalTerjual,
    required this.totalSubtotal,
  });
}

class LaporanService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<LaporanRingkasan> getRingkasan(DateTime dari, DateTime sampai) async {
    final db = await _dbHelper.database;
    final dariStr = dari.toIso8601String().substring(0, 10);
    final sampaiStr = sampai.toIso8601String().substring(0, 10) + 'T23:59:59';

    final txMaps = await db.rawQuery('''
      SELECT COUNT(*) as total_tx, COALESCE(SUM(total), 0) as sum_total, COALESCE(SUM(jumlah_item), 0) as sum_item
      FROM transaksi
      WHERE tanggal >= ? AND tanggal <= ?
    ''', [dariStr, sampaiStr]);

    final totalTx = txMaps.first['total_tx'] as int? ?? 0;
    final totalPenjualan = (txMaps.first['sum_total'] as num?)?.toDouble() ?? 0.0;
    final totalItemTerjual = (txMaps.first['sum_item'] as num?)?.toInt() ?? 0;

    // Estimate profit = sum( (harga_satuan - harga_beli) * jumlah )
    final profitMaps = await db.rawQuery('''
      SELECT COALESCE(SUM((d.harga_satuan - COALESCE(o.harga_beli, 0)) * d.jumlah), 0) as total_profit
      FROM detail_transaksi d
      JOIN transaksi t ON d.transaksi_id = t.id
      LEFT JOIN obat o ON d.obat_id = o.id
      WHERE t.tanggal >= ? AND t.tanggal <= ?
    ''', [dariStr, sampaiStr]);

    final estProfit = (profitMaps.first['total_profit'] as num?)?.toDouble() ?? 0.0;

    return LaporanRingkasan(
      totalPenjualan: totalPenjualan,
      totalTransaksi: totalTx,
      totalItemTerjual: totalItemTerjual,
      totalEstKeuntungan: estProfit,
    );
  }

  Future<List<ObatTerlarisItem>> getObatTerlaris(
    DateTime dari,
    DateTime sampai, {
    int limit = 5,
  }) async {
    final db = await _dbHelper.database;
    final dariStr = dari.toIso8601String().substring(0, 10);
    final sampaiStr = sampai.toIso8601String().substring(0, 10) + 'T23:59:59';

    final sql = '''
      SELECT COALESCE(o.nama, '(Obat telah dihapus)') AS nama_obat,
             COALESCE(o.kode_obat, '-') AS kode_obat,
             SUM(d.jumlah) AS total_terjual,
             SUM(d.subtotal) AS total_subtotal
      FROM detail_transaksi d
      JOIN transaksi t ON d.transaksi_id = t.id
      LEFT JOIN obat o ON d.obat_id = o.id
      WHERE t.tanggal >= ? AND t.tanggal <= ?
      GROUP BY d.obat_id
      ORDER BY total_terjual DESC
      LIMIT ?
    ''';
    final maps = await db.rawQuery(sql, [dariStr, sampaiStr, limit]);
    return maps.map((m) => ObatTerlarisItem(
      namaObat: m['nama_obat'] as String,
      kodeObat: m['kode_obat'] as String,
      totalTerjual: (m['total_terjual'] as num).toInt(),
      totalSubtotal: (m['total_subtotal'] as num).toDouble(),
    )).toList();
  }
}
