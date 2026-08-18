import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firdan_farma_windows/core/utils/reporting_period.dart';
import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/detail_transaksi_model.dart';
import 'package:firdan_farma_windows/data/models/transaksi_model.dart';
import 'package:firdan_farma_windows/data/services/audit_service.dart';
import 'package:firdan_farma_windows/data/services/auth_service.dart';

class TransaksiService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuditService _auditService = AuditService();

  Future<String> generateNomorTransaksi({DateTime? timestamp}) async {
    final db = await _dbHelper.database;
    final date = timestamp ?? DateTime.now();
    final datePrefix = DateFormat('yyyyMMdd').format(date);
    final maps = await db.rawQuery(
      "SELECT COUNT(*) as count FROM transaksi WHERE nomor_transaksi LIKE ?",
      ['TRX-$datePrefix-%'],
    );
    final count = (maps.first['count'] as int? ?? 0) + 1;
    return 'TRX-$datePrefix-${count.toString().padLeft(4, '0')}';
  }

  Future<Transaksi?> createTransaksi({
    required double total,
    required double bayar,
    String metodePembayaran = 'TUNAI',
    required List<DetailTransaksi> items,
    double? subtotalSebelumDiskon,
    double diskon = 0,
    bool diberiDiskon = false,
    DateTime? tanggal,
  }) async {
    if (items.isEmpty) return null;
    if (diskon < 0) throw Exception('Diskon tidak boleh negatif.');

    final normalizedPayment = metodePembayaran.trim().toUpperCase();
    final subtotal =
        subtotalSebelumDiskon ??
        items.fold<double>(
          0,
          (sum, item) => sum + item.hargaSatuan * item.jumlah,
        );
    if (diskon > subtotal) {
      throw Exception('Diskon tidak boleh lebih besar dari subtotal.');
    }
    final calculatedTotal = subtotal - diskon;
    if ((total - calculatedTotal).abs() > 0.01) {
      throw Exception('Total transaksi tidak sesuai dengan diskon.');
    }
    if (normalizedPayment == 'TUNAI' && bayar < total) {
      throw Exception('Nominal pembayaran kurang dari total belanja!');
    }
    for (final item in items) {
      if (item.jumlah <= 0) throw Exception('Jumlah obat harus lebih dari 0.');
    }

    final db = await _dbHelper.database;
    final timestamp = tanggal ?? DateTime.now();
    final nowStr = timestamp.toIso8601String();
    final laporanTanggal = ReportingPeriod.businessDateString(timestamp);
    final user = AuthSession.currentUser;
    final paid = normalizedPayment == 'TUNAI' ? bayar : total;
    final kembali = normalizedPayment == 'TUNAI' ? paid - total : 0.0;
    final totalItemCount = items.fold<int>(0, (sum, item) => sum + item.jumlah);

    final saved = await db.transaction((txn) async {
      final nomorTx = await _generateTransactionNumber(txn, timestamp);
      final kodeLaporan = await _generateReportCode(
        txn,
        laporanTanggal,
        normalizedPayment,
      );

      for (final item in items) {
        final obatMaps = await txn.query(
          'obat',
          where: 'id = ?',
          whereArgs: [item.obatId],
        );
        if (obatMaps.isEmpty) {
          throw Exception('Obat ID ${item.obatId} tidak ditemukan!');
        }
        final obat = obatMaps.first;
        final stok = obat['stok_tersedia'] as int? ?? 0;
        if ((obat['is_active'] as int? ?? 1) != 1) {
          throw Exception(
            'Obat "${obat['nama']}" sudah nonaktif dan tidak dapat dijual.',
          );
        }
        if (stok < item.jumlah) {
          throw Exception(
            'Stok obat "${obat['nama']}" tidak mencukupi (tersedia: $stok, diminta: ${item.jumlah})',
          );
        }
      }

      final txId = await txn.insert('transaksi', {
        'nomor_transaksi': nomorTx,
        'total': total,
        'bayar': paid,
        'kembali': kembali,
        'metode_pembayaran': normalizedPayment,
        'tanggal': nowStr,
        'jumlah_item': totalItemCount,
        'total_sebelum_diskon': subtotal,
        'diskon': diskon,
        'diberi_diskon': diberiDiskon || diskon > 0 ? 1 : 0,
        'laporan_tanggal': laporanTanggal,
        'kode_laporan': kodeLaporan,
        'user_id': user?.id,
        'username_snapshot': user?.username ?? 'SISTEM',
      });

      final savedDetails = <DetailTransaksi>[];
      for (final item in items) {
        final obat = (await txn.query(
          'obat',
          where: 'id = ?',
          whereArgs: [item.obatId],
        )).first;
        final stokSebelum = obat['stok_tersedia'] as int;
        final stokSesudah = stokSebelum - item.jumlah;
        final hargaModal = item.hargaModalSatuan > 0
            ? item.hargaModalSatuan
            : (obat['harga_beli'] as num).toDouble();
        final hargaJual = item.hargaSatuan;
        final subtotalItem = hargaJual * item.jumlah;
        final subtotalModal = hargaModal * item.jumlah;
        final diskonItem = subtotal <= 0 ? 0 : diskon * subtotalItem / subtotal;
        final labaKotor = subtotalItem - diskonItem - subtotalModal;
        final namaObat = item.namaObat ?? obat['nama'] as String?;
        final kodeObat = item.kodeObat ?? obat['kode_obat'] as String?;

        final detailId = await txn.insert('detail_transaksi', {
          'transaksi_id': txId,
          'obat_id': item.obatId,
          'jumlah': item.jumlah,
          'harga_satuan': hargaJual,
          'harga_modal_satuan': hargaModal,
          'subtotal': subtotalItem,
          'subtotal_modal': subtotalModal,
          'laba_kotor': labaKotor,
          'nama_obat_snapshot': namaObat,
          'kode_obat_snapshot': kodeObat,
        });

        await txn.update(
          'obat',
          {
            'stok_tersedia': stokSesudah,
            'klr': (obat['klr'] as int? ?? 0) + item.jumlah,
            'updated_at': nowStr,
          },
          where: 'id = ?',
          whereArgs: [item.obatId],
        );

        final allocations = await _consumeBatches(
          txn,
          obatId: item.obatId,
          jumlah: item.jumlah,
        );
        var runningStock = stokSebelum;
        for (final allocation in allocations) {
          final stockAfter = runningStock - allocation.jumlah;
          await txn.insert('stok', {
            'obat_id': item.obatId,
            'jenis': 'keluar',
            'jumlah': allocation.jumlah,
            'tipe_mutasi': 'PENJUALAN',
            'reference_type': 'transaksi',
            'reference_id': txId,
            'harga_beli_snapshot': hargaModal,
            'stok_sebelum': runningStock,
            'stok_sesudah': stockAfter,
            'alasan': 'PENJUALAN',
            'catatan': 'Penjualan Kasir $nomorTx',
            'kode_transaksi': kodeLaporan,
            'batch_no': allocation.batchNo,
            'expired_date': allocation.expiredDate,
            'user_id': user?.id,
            'username_snapshot': user?.username ?? 'SISTEM',
            'tanggal': nowStr,
            'created_at': nowStr,
          });
          runningStock = stockAfter;
        }

        savedDetails.add(
          DetailTransaksi(
            id: detailId,
            transaksiId: txId,
            obatId: item.obatId,
            jumlah: item.jumlah,
            hargaSatuan: hargaJual,
            hargaModalSatuan: hargaModal,
            subtotal: subtotalItem,
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
        totalSebelumDiskon: subtotal,
        diskon: diskon,
        diberiDiskon: diberiDiskon || diskon > 0,
        laporanTanggal: laporanTanggal,
        kodeLaporan: kodeLaporan,
        userId: user?.id,
        usernameSnapshot: user?.username ?? 'SISTEM',
        items: savedDetails,
      );
    });

    await _auditService.log(
      aksi: 'PENJUALAN',
      entitas: 'TRANSAKSI',
      entitasId: saved.id,
      metodePembayaran: normalizedPayment,
      nominal: saved.total,
      alasan: saved.diskon > 0 ? 'DISKON DIBERIKAN' : 'TANPA DISKON',
      detail:
          '${saved.kodeLaporan ?? '-'} | ${saved.nomorTransaksi} | ${saved.jumlahItem} item',
    );
    return saved;
  }

  Future<String> _generateTransactionNumber(
    Transaction txn,
    DateTime timestamp,
  ) async {
    final prefix = DateFormat('yyyyMMdd').format(timestamp);
    final rows = await txn.rawQuery(
      'SELECT COUNT(*) AS count FROM transaksi WHERE nomor_transaksi LIKE ?',
      ['TRX-$prefix-%'],
    );
    final next = (rows.first['count'] as int? ?? 0) + 1;
    return 'TRX-$prefix-${next.toString().padLeft(4, '0')}';
  }

  Future<String> _generateReportCode(
    Transaction txn,
    String reportDate,
    String paymentMethod,
  ) async {
    final prefix = ReportingPeriod.paymentPrefix(paymentMethod);
    final rows = await txn.rawQuery(
      'SELECT COUNT(*) AS count FROM transaksi WHERE laporan_tanggal = ? AND metode_pembayaran = ?',
      [reportDate, paymentMethod],
    );
    return '$prefix${(rows.first['count'] as int? ?? 0) + 1}';
  }

  Future<List<_BatchAllocation>> _consumeBatches(
    Transaction txn, {
    required int obatId,
    required int jumlah,
  }) async {
    final rows = await txn.query(
      'stok_batch',
      where: 'obat_id = ? AND stok_sisa > 0',
      whereArgs: [obatId],
      orderBy:
          'CASE WHEN expired_date IS NULL THEN 1 ELSE 0 END ASC, expired_date ASC, id ASC',
    );
    var remaining = jumlah;
    final allocations = <_BatchAllocation>[];
    for (final row in rows) {
      if (remaining <= 0) break;
      final available = row['stok_sisa'] as int? ?? 0;
      final take = available < remaining ? available : remaining;
      await txn.update(
        'stok_batch',
        {
          'qty_keluar': (row['qty_keluar'] as int? ?? 0) + take,
          'stok_sisa': available - take,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      allocations.add(
        _BatchAllocation(
          jumlah: take,
          batchNo: row['batch_no'] as String?,
          expiredDate: row['expired_date'] as String?,
        ),
      );
      remaining -= take;
    }
    if (remaining > 0) allocations.add(_BatchAllocation(jumlah: remaining));
    return allocations;
  }

  Future<List<Transaksi>> getAll({int limit = 100}) async {
    final db = await _dbHelper.database;
    final txMaps = await db.query(
      'transaksi',
      orderBy: 'id DESC',
      limit: limit,
    );
    final result = <Transaksi>[];
    for (final map in txMaps) {
      final txId = map['id'] as int;
      final detailMaps = await db.rawQuery(
        '''
        SELECT d.*, o.nama AS nama_obat, o.kode_obat AS kode_obat
        FROM detail_transaksi d
        LEFT JOIN obat o ON d.obat_id = o.id
        WHERE d.transaksi_id = ?
        ORDER BY d.id ASC
        ''',
        [txId],
      );
      result.add(
        Transaksi.fromMap(
          map,
          items: detailMaps.map(DetailTransaksi.fromMap).toList(),
        ),
      );
    }
    return result;
  }

  Future<int> getTodayCount() async {
    final db = await _dbHelper.database;
    final reportDate = ReportingPeriod.businessDateString(DateTime.now());
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM transaksi WHERE COALESCE(laporan_tanggal, substr(tanggal, 1, 10)) = ?',
      [reportDate],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<double> getTodayRevenue() async {
    final db = await _dbHelper.database;
    final reportDate = ReportingPeriod.businessDateString(DateTime.now());
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total), 0) AS sum FROM transaksi WHERE COALESCE(laporan_tanggal, substr(tanggal, 1, 10)) = ?',
      [reportDate],
    );
    return (result.first['sum'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTodayGrossProfit() async {
    final db = await _dbHelper.database;
    final reportDate = ReportingPeriod.businessDateString(DateTime.now());
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(COALESCE(d.laba_kotor,
             d.subtotal - (COALESCE(d.harga_modal_satuan, o.harga_beli, 0) * d.jumlah)
      )), 0) AS sum
      FROM detail_transaksi d
      JOIN transaksi t ON d.transaksi_id = t.id
      LEFT JOIN obat o ON d.obat_id = o.id
      WHERE COALESCE(t.laporan_tanggal, substr(t.tanggal, 1, 10)) = ?
      ''',
      [reportDate],
    );
    return (result.first['sum'] as num?)?.toDouble() ?? 0.0;
  }
}

class _BatchAllocation {
  final int jumlah;
  final String? batchNo;
  final String? expiredDate;

  const _BatchAllocation({
    required this.jumlah,
    this.batchNo,
    this.expiredDate,
  });
}
