import 'package:flutter_test/flutter_test.dart';
import 'package:firdan_farma_windows/core/utils/reporting_period.dart';
import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/detail_pembelian_model.dart';
import 'package:firdan_farma_windows/data/models/detail_transaksi_model.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';
import 'package:firdan_farma_windows/data/services/auth_service.dart';
import 'package:firdan_farma_windows/data/services/laporan_service.dart';
import 'package:firdan_farma_windows/data/services/obat_service.dart';
import 'package:firdan_farma_windows/data/services/pembelian_service.dart';
import 'package:firdan_farma_windows/data/services/transaksi_service.dart';

void main() {
  late int obatId;

  setUp(() async {
    await DatabaseHelper.openInMemoryForTesting();
    obatId = await ObatService().insert(
      Obat(
        nama: 'OBAT BATCH TEST',
        kodeObat: 'BATCH001',
        kategoriId: 1,
        hargaBeli: 5000,
        hargaJual: 10000,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  });

  tearDown(() => DatabaseHelper.instance.closeAndReset());

  test('cutoff 15.00 menggeser tanggal laporan', () {
    final before = DateTime(2026, 8, 17, 14, 59);
    final atCutoff = DateTime(2026, 8, 17, 15, 0);
    expect(ReportingPeriod.businessDateString(before), '2026-08-17');
    expect(ReportingPeriod.businessDateString(atCutoff), '2026-08-18');
  });

  test('penjualan membuat kode T/Q, diskon, batch FEFO, dan audit', () async {
    final purchaseService = PembelianService();
    await purchaseService.createPembelian(
      tanggal: DateTime(2026, 8, 17, 10),
      items: [
        DetailPembelian(
          obatId: obatId,
          qty: 1,
          hargaBeli: 5000,
          batchNo: 'BATCH-LAMA',
          expiredDate: '2026-08-20',
        ),
        DetailPembelian(
          obatId: obatId,
          qty: 2,
          hargaBeli: 5000,
          batchNo: 'BATCH-BARU',
          expiredDate: '2026-09-20',
        ),
      ],
    );

    final service = TransaksiService();
    final cash = await service.createTransaksi(
      tanggal: DateTime(2026, 8, 17, 14, 59),
      total: 9000,
      bayar: 9000,
      metodePembayaran: 'TUNAI',
      subtotalSebelumDiskon: 10000,
      diskon: 1000,
      diberiDiskon: true,
      items: [
        DetailTransaksi(
          obatId: obatId,
          jumlah: 1,
          hargaSatuan: 10000,
          hargaModalSatuan: 5000,
          subtotal: 10000,
        ),
      ],
    );
    final qris = await service.createTransaksi(
      tanggal: DateTime(2026, 8, 17, 15, 0),
      total: 10000,
      bayar: 10000,
      metodePembayaran: 'QRIS',
      items: [
        DetailTransaksi(
          obatId: obatId,
          jumlah: 1,
          hargaSatuan: 10000,
          hargaModalSatuan: 5000,
          subtotal: 10000,
        ),
      ],
    );

    expect(cash?.kodeLaporan, 'T1');
    expect(cash?.laporanTanggal, '2026-08-17');
    expect(cash?.diskon, 1000);
    expect(qris?.kodeLaporan, 'Q1');
    expect(qris?.laporanTanggal, '2026-08-18');

    final db = await DatabaseHelper.instance.database;
    final stockRows = await db.query(
      'stok',
      where: 'reference_type = ?',
      whereArgs: ['transaksi'],
      orderBy: 'id ASC',
    );
    expect(stockRows.first['batch_no'], 'BATCH-LAMA');
    expect(stockRows.first['kode_transaksi'], 'T1');
    expect(stockRows[1]['batch_no'], 'BATCH-BARU');
    expect(stockRows[1]['kode_transaksi'], 'Q1');

    final summaries = await LaporanService().getPaymentSummaries(
      DateTime(2026, 8, 17),
      DateTime(2026, 8, 17),
    );
    expect(summaries.single.metodePembayaran, 'TUNAI');
    expect(summaries.single.total, 9000);

    final audit = await LaporanService().getActivityLogs();
    expect(audit.any((item) => item.aksi == 'PENJUALAN'), isTrue);
  });

  test(
    'akun default memiliki dua role dan password dapat diverifikasi',
    () async {
      final auth = AuthService();
      await auth.ensureDefaultUsers();
      final admin = await auth.login('admin1', 'admin123');
      expect(admin?.isSuperAdmin, isTrue);
      await auth.logout();
      final employee = await auth.login('karyawan', 'karyawan123');
      expect(employee?.isSuperAdmin, isFalse);
    },
  );
}
