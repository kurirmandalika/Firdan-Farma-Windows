import 'package:firdan_farma_windows/data/database/database_helper.dart';

class LaporanRingkasan {
  final double totalPenjualan;
  final double totalPembelian;
  final int totalTransaksi;
  final int totalItemTerjual;
  final double totalLabaKotor;
  final double nilaiStokAkhir;
  final int stokMenipisCount;

  LaporanRingkasan({
    required this.totalPenjualan,
    required this.totalPembelian,
    required this.totalTransaksi,
    required this.totalItemTerjual,
    required this.totalLabaKotor,
    required this.nilaiStokAkhir,
    required this.stokMenipisCount,
  });
}

class MedicinePeriodReport {
  final int obatId;
  final String kodeObat;
  final String namaObat;
  final String satuan;
  final int awl;
  final int msk;
  final int klr;
  final int penyesuaianMasuk;
  final int penyesuaianKeluar;
  final int sisa;
  final double hargaBeli;
  final double hargaJual;
  final double omzet;
  final double pembelian;
  final double modalTerjual;
  final double labaKotor;
  final double nilaiStokAkhir;

  MedicinePeriodReport({
    required this.obatId,
    required this.kodeObat,
    required this.namaObat,
    required this.satuan,
    required this.awl,
    required this.msk,
    required this.klr,
    required this.penyesuaianMasuk,
    required this.penyesuaianKeluar,
    required this.sisa,
    required this.hargaBeli,
    required this.hargaJual,
    required this.omzet,
    required this.pembelian,
    required this.modalTerjual,
    required this.labaKotor,
    required this.nilaiStokAkhir,
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
    final bounds = _dateBounds(dari, sampai);

    final txMaps = await db.rawQuery(
      '''
      SELECT COUNT(*) as total_tx, COALESCE(SUM(total), 0) as sum_total, COALESCE(SUM(jumlah_item), 0) as sum_item
      FROM transaksi
      WHERE tanggal >= ? AND tanggal < ?
    ''',
      [bounds.startIso, bounds.endExclusiveIso],
    );

    final totalTx = txMaps.first['total_tx'] as int? ?? 0;
    final totalPenjualan =
        (txMaps.first['sum_total'] as num?)?.toDouble() ?? 0.0;
    final totalItemTerjual = (txMaps.first['sum_item'] as num?)?.toInt() ?? 0;

    final profitMaps = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(COALESCE(
        d.laba_kotor,
        d.subtotal - (COALESCE(d.harga_modal_satuan, o.harga_beli, 0) * d.jumlah)
      )), 0) as total_profit
      FROM detail_transaksi d
      JOIN transaksi t ON d.transaksi_id = t.id
      LEFT JOIN obat o ON d.obat_id = o.id
      WHERE t.tanggal >= ? AND t.tanggal < ?
    ''',
      [bounds.startIso, bounds.endExclusiveIso],
    );

    final grossProfit =
        (profitMaps.first['total_profit'] as num?)?.toDouble() ?? 0.0;

    final purchaseMaps = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) as total_purchase
      FROM pembelian
      WHERE tanggal >= ? AND tanggal < ?
      ''',
      [bounds.startIso, bounds.endExclusiveIso],
    );

    final stockValueMaps = await db.rawQuery('''
      SELECT COALESCE(SUM(stok_tersedia * harga_beli), 0) AS value
      FROM obat
      WHERE is_active = 1
      ''');

    final lowStockMaps = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM obat
      WHERE is_active = 1 AND stok_tersedia <= stok_minimal
      ''');

    return LaporanRingkasan(
      totalPenjualan: totalPenjualan,
      totalPembelian:
          (purchaseMaps.first['total_purchase'] as num?)?.toDouble() ?? 0.0,
      totalTransaksi: totalTx,
      totalItemTerjual: totalItemTerjual,
      totalLabaKotor: grossProfit,
      nilaiStokAkhir:
          (stockValueMaps.first['value'] as num?)?.toDouble() ?? 0.0,
      stokMenipisCount: lowStockMaps.first['count'] as int? ?? 0,
    );
  }

  Future<List<MedicinePeriodReport>> getMedicinePeriodReports(
    DateTime dari,
    DateTime sampai,
  ) async {
    final db = await _dbHelper.database;
    final bounds = _dateBounds(dari, sampai);

    final rows = await db.rawQuery(
      '''
      SELECT
        o.id AS obat_id,
        o.kode_obat,
        o.nama AS nama_obat,
        COALESCE(o.satuan, 'PCS') AS satuan,
        COALESCE(o.harga_beli, 0) AS harga_beli,
        COALESCE(o.harga_jual, 0) AS harga_jual,
        COALESCE((
          SELECT SUM(CASE WHEN s.jenis = 'masuk' THEN s.jumlah ELSE -s.jumlah END)
          FROM stok s
          WHERE s.obat_id = o.id AND s.tanggal < ?
        ), 0) + COALESCE((
          SELECT SUM(s.jumlah)
          FROM stok s
          WHERE s.obat_id = o.id
            AND s.tipe_mutasi = 'SALDO_AWAL'
            AND s.tanggal >= ?
            AND s.tanggal < ?
        ), 0) AS awl,
        COALESCE((
          SELECT SUM(s.jumlah)
          FROM stok s
          WHERE s.obat_id = o.id
            AND s.jenis = 'masuk'
            AND s.tipe_mutasi <> 'SALDO_AWAL'
            AND s.tanggal >= ?
            AND s.tanggal < ?
        ), 0) AS msk,
        COALESCE((
          SELECT SUM(s.jumlah)
          FROM stok s
          WHERE s.obat_id = o.id
            AND s.tipe_mutasi = 'PENJUALAN'
            AND s.tanggal >= ?
            AND s.tanggal < ?
        ), 0) AS klr,
        COALESCE((
          SELECT SUM(s.jumlah)
          FROM stok s
          WHERE s.obat_id = o.id
            AND s.jenis = 'masuk'
            AND s.tipe_mutasi NOT IN ('SALDO_AWAL', 'PEMBELIAN', 'STOK_MASUK')
            AND s.tanggal >= ?
            AND s.tanggal < ?
        ), 0) AS penyesuaian_masuk,
        COALESCE((
          SELECT SUM(s.jumlah)
          FROM stok s
          WHERE s.obat_id = o.id
            AND s.jenis = 'keluar'
            AND s.tipe_mutasi <> 'PENJUALAN'
            AND s.tanggal >= ?
            AND s.tanggal < ?
        ), 0) AS penyesuaian_keluar,
        COALESCE((
          SELECT SUM(CASE WHEN s.jenis = 'masuk' THEN s.jumlah ELSE -s.jumlah END)
          FROM stok s
          WHERE s.obat_id = o.id AND s.tanggal < ?
        ), 0) AS sisa,
        COALESCE((
          SELECT SUM(d.subtotal)
          FROM detail_transaksi d
          JOIN transaksi t ON d.transaksi_id = t.id
          WHERE d.obat_id = o.id AND t.tanggal >= ? AND t.tanggal < ?
        ), 0) AS omzet,
        COALESCE((
          SELECT SUM(dp.subtotal)
          FROM detail_pembelian dp
          JOIN pembelian p ON dp.pembelian_id = p.id
          WHERE dp.obat_id = o.id AND p.tanggal >= ? AND p.tanggal < ?
        ), 0) AS pembelian,
        COALESCE((
          SELECT SUM(COALESCE(d.subtotal_modal, COALESCE(d.harga_modal_satuan, o.harga_beli, 0) * d.jumlah))
          FROM detail_transaksi d
          JOIN transaksi t ON d.transaksi_id = t.id
          WHERE d.obat_id = o.id AND t.tanggal >= ? AND t.tanggal < ?
        ), 0) AS modal_terjual,
        COALESCE((
          SELECT SUM(COALESCE(d.laba_kotor, d.subtotal - COALESCE(d.subtotal_modal, COALESCE(d.harga_modal_satuan, o.harga_beli, 0) * d.jumlah)))
          FROM detail_transaksi d
          JOIN transaksi t ON d.transaksi_id = t.id
          WHERE d.obat_id = o.id AND t.tanggal >= ? AND t.tanggal < ?
        ), 0) AS laba_kotor
      FROM obat o
      WHERE o.is_active = 1
         OR EXISTS (
            SELECT 1 FROM stok s
            WHERE s.obat_id = o.id AND s.tanggal < ?
         )
         OR EXISTS (
            SELECT 1 FROM detail_transaksi d
            JOIN transaksi t ON d.transaksi_id = t.id
            WHERE d.obat_id = o.id AND t.tanggal >= ? AND t.tanggal < ?
         )
      ORDER BY o.nama ASC
      ''',
      [
        bounds.startIso,
        bounds.startIso,
        bounds.endExclusiveIso,
        bounds.startIso,
        bounds.endExclusiveIso,
        bounds.startIso,
        bounds.endExclusiveIso,
        bounds.startIso,
        bounds.endExclusiveIso,
        bounds.startIso,
        bounds.endExclusiveIso,
        bounds.endExclusiveIso,
        bounds.startIso,
        bounds.endExclusiveIso,
        bounds.startIso,
        bounds.endExclusiveIso,
        bounds.startIso,
        bounds.endExclusiveIso,
        bounds.startIso,
        bounds.endExclusiveIso,
        bounds.endExclusiveIso,
        bounds.startIso,
        bounds.endExclusiveIso,
      ],
    );

    return rows.map((row) {
      final sisa = (row['sisa'] as num?)?.toInt() ?? 0;
      final hargaBeli = (row['harga_beli'] as num?)?.toDouble() ?? 0.0;
      return MedicinePeriodReport(
        obatId: row['obat_id'] as int,
        kodeObat: row['kode_obat'] as String? ?? '-',
        namaObat: row['nama_obat'] as String? ?? '(Obat telah dihapus)',
        satuan: row['satuan'] as String? ?? 'PCS',
        awl: (row['awl'] as num?)?.toInt() ?? 0,
        msk: (row['msk'] as num?)?.toInt() ?? 0,
        klr: (row['klr'] as num?)?.toInt() ?? 0,
        penyesuaianMasuk: (row['penyesuaian_masuk'] as num?)?.toInt() ?? 0,
        penyesuaianKeluar: (row['penyesuaian_keluar'] as num?)?.toInt() ?? 0,
        sisa: sisa,
        hargaBeli: hargaBeli,
        hargaJual: (row['harga_jual'] as num?)?.toDouble() ?? 0.0,
        omzet: (row['omzet'] as num?)?.toDouble() ?? 0.0,
        pembelian: (row['pembelian'] as num?)?.toDouble() ?? 0.0,
        modalTerjual: (row['modal_terjual'] as num?)?.toDouble() ?? 0.0,
        labaKotor: (row['laba_kotor'] as num?)?.toDouble() ?? 0.0,
        nilaiStokAkhir: sisa * hargaBeli,
      );
    }).toList();
  }

  Future<List<ObatTerlarisItem>> getObatTerlaris(
    DateTime dari,
    DateTime sampai, {
    int limit = 5,
  }) async {
    final db = await _dbHelper.database;
    final bounds = _dateBounds(dari, sampai);

    final sql = '''
      SELECT COALESCE(d.nama_obat_snapshot, o.nama, '(Obat telah dihapus)') AS nama_obat,
             COALESCE(d.kode_obat_snapshot, o.kode_obat, '-') AS kode_obat,
             SUM(d.jumlah) AS total_terjual,
             SUM(d.subtotal) AS total_subtotal
      FROM detail_transaksi d
      JOIN transaksi t ON d.transaksi_id = t.id
      LEFT JOIN obat o ON d.obat_id = o.id
      WHERE t.tanggal >= ? AND t.tanggal < ?
      GROUP BY d.obat_id
      ORDER BY total_terjual DESC
      LIMIT ?
    ''';
    final maps = await db.rawQuery(sql, [
      bounds.startIso,
      bounds.endExclusiveIso,
      limit,
    ]);
    return maps
        .map(
          (m) => ObatTerlarisItem(
            namaObat: m['nama_obat'] as String,
            kodeObat: m['kode_obat'] as String,
            totalTerjual: (m['total_terjual'] as num).toInt(),
            totalSubtotal: (m['total_subtotal'] as num).toDouble(),
          ),
        )
        .toList();
  }

  _ReportBounds _dateBounds(DateTime dari, DateTime sampai) {
    final start = DateTime(dari.year, dari.month, dari.day);
    final inclusiveEnd = DateTime(sampai.year, sampai.month, sampai.day);
    final endExclusive = inclusiveEnd.add(const Duration(days: 1));
    return _ReportBounds(
      startIso: start.toIso8601String(),
      endExclusiveIso: endExclusive.toIso8601String(),
    );
  }
}

class _ReportBounds {
  final String startIso;
  final String endExclusiveIso;

  const _ReportBounds({required this.startIso, required this.endExclusiveIso});
}
