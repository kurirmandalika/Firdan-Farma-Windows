import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/detail_pembelian_model.dart';
import 'package:firdan_farma_windows/data/models/detail_transaksi_model.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';
import 'package:firdan_farma_windows/data/services/laporan_service.dart';
import 'package:firdan_farma_windows/data/services/obat_service.dart';
import 'package:firdan_farma_windows/data/services/pembelian_service.dart';
import 'package:firdan_farma_windows/data/services/stok_service.dart';
import 'package:firdan_farma_windows/data/services/transaksi_service.dart';

void main() {
  late ObatService obatService;
  late PembelianService pembelianService;
  late TransaksiService transaksiService;
  late LaporanService laporanService;
  late StokService stokService;

  setUp(() async {
    await DatabaseHelper.openInMemoryForTesting();
    obatService = ObatService();
    pembelianService = PembelianService();
    transaksiService = TransaksiService();
    laporanService = LaporanService();
    stokService = StokService();
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeAndReset();
  });

  test(
    'database baru dimulai tanpa obat, supplier, dan data operasional',
    () async {
      final db = await DatabaseHelper.instance.database;
      expect(
        (await db.rawQuery(
          'SELECT COUNT(*) AS count FROM obat',
        )).first['count'],
        0,
      );
      expect(
        (await db.rawQuery(
          'SELECT COUNT(*) AS count FROM supplier',
        )).first['count'],
        0,
      );
      expect(
        (await db.rawQuery(
          'SELECT COUNT(*) AS count FROM stok',
        )).first['count'],
        0,
      );
      expect(
        (await db.rawQuery(
          'SELECT COUNT(*) AS count FROM transaksi',
        )).first['count'],
        0,
      );
      expect(
        (await db.rawQuery(
          'SELECT COUNT(*) AS count FROM kategori_obat',
        )).first['count'],
        greaterThan(0),
      );
    },
  );

  test(
    'input operasional menghasilkan ledger, snapshot, dan report otomatis',
    () async {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1)).toIso8601String();

      final obatId = await obatService.insert(
        Obat(
          nama: 'PARACETAMOL 500 MG',
          kodeObat: 'OBTTEST001',
          satuan: 'STRIP',
          kategoriId: 1,
          hargaBeli: 6000,
          hargaJual: 8000,
          stokTersedia: 20,
          stokMinimal: 5,
          createdAt: yesterday,
        ),
      );

      await db.update(
        'stok',
        {'tanggal': yesterday, 'created_at': yesterday},
        where: 'obat_id = ? AND tipe_mutasi = ?',
        whereArgs: [obatId, 'SALDO_AWAL'],
      );

      final saldoAwal = await db.query(
        'stok',
        where: 'obat_id = ? AND tipe_mutasi = ?',
        whereArgs: [obatId, 'SALDO_AWAL'],
      );
      expect(saldoAwal, hasLength(1));
      expect(saldoAwal.first['jumlah'], 20);

      await pembelianService.createPembelian(
        items: [DetailPembelian(obatId: obatId, qty: 10, hargaBeli: 6000)],
      );

      var obat = await obatService.getById(obatId);
      expect(obat?.stokTersedia, 30);

      final tx = await transaksiService.createTransaksi(
        total: 24000,
        bayar: 24000,
        metodePembayaran: 'TUNAI',
        items: [
          DetailTransaksi(
            obatId: obatId,
            jumlah: 3,
            hargaSatuan: 8000,
            hargaModalSatuan: 6000,
            subtotal: 24000,
            namaObat: 'PARACETAMOL 500 MG',
            kodeObat: 'OBTTEST001',
          ),
        ],
      );

      expect(tx?.items.single.hargaModalSatuan, 6000);
      expect(tx?.items.single.labaKotor, 6000);

      obat = await obatService.getById(obatId);
      expect(obat?.stokTersedia, 27);

      await obatService.update(obat!.copyWith(hargaBeli: 7000));

      final reports = await laporanService.getMedicinePeriodReports(now, now);
      final report = reports.singleWhere((item) => item.obatId == obatId);
      expect(report.awl, 20);
      expect(report.msk, 10);
      expect(report.klr, 3);
      expect(report.sisa, 27);
      expect(report.omzet, 24000);
      expect(report.modalTerjual, 18000);
      expect(report.labaKotor, 6000);
    },
  );

  test('crud obat mengikuti kolom Excel AWL MSK KLR SISA', () async {
    final obatId = await obatService.insert(
      Obat(
        nama: 'OBAT CRUD EXCEL',
        kodeObat: 'CRUDX001',
        satuan: 'PCS',
        kategoriId: 1,
        hargaBeli: 1000,
        hargaJual: 1500,
        awl: 5,
        msk: 3,
        klr: 1,
        stokTersedia: 7,
        stokMinimal: 2,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    var obat = await obatService.getById(obatId);
    expect(obat?.awl, 5);
    expect(obat?.msk, 3);
    expect(obat?.klr, 1);
    expect(obat?.stokTersedia, 7);

    await obatService.update(
      obat!.copyWith(nama: 'OBAT CRUD EXCEL EDIT', awl: 6, msk: 4, klr: 2),
    );
    obat = await obatService.getById(obatId);
    expect(obat?.nama, 'OBAT CRUD EXCEL EDIT');
    expect(obat?.awl, 6);
    expect(obat?.msk, 4);
    expect(obat?.klr, 2);
    expect(obat?.stokTersedia, 8);

    await obatService.delete(obatId);
    obat = await obatService.getById(obatId);
    expect(obat?.isActive, isFalse);

    await obatService.reactivate(obatId);
    obat = await obatService.getById(obatId);
    expect(obat?.isActive, isTrue);
  });

  test('penyesuaian stok mencatat selisih dan saldo akhir', () async {
    final obatId = await obatService.insert(
      Obat(
        nama: 'AMOXICILLIN TEST',
        kodeObat: 'OBTTEST002',
        satuan: 'STRIP',
        kategoriId: 1,
        hargaBeli: 5000,
        hargaJual: 7000,
        stokTersedia: 20,
        stokMinimal: 5,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await stokService.adjustToPhysicalStock(
      obatId: obatId,
      stokFisik: 18,
      alasan: 'Stok opname',
    );

    final obat = await obatService.getById(obatId);
    expect(obat?.stokTersedia, 18);

    final mutasi = await stokService.getAllMutasi();
    final adjustment = mutasi.firstWhere(
      (item) =>
          item.obatId == obatId && item.tipeMutasi == 'PENYESUAIAN_KELUAR',
    );
    expect(adjustment.jumlah, 2);
    expect(adjustment.stokSebelum, 20);
    expect(adjustment.stokSesudah, 18);

    final report = (await laporanService.getMedicinePeriodReports(
      DateTime.now(),
      DateTime.now(),
    )).singleWhere((item) => item.obatId == obatId);
    expect(report.klr, 2);
    expect(report.penyesuaianKeluar, 2);
    expect(report.sisa, 18);
  });

  test('pembelian menolak diskon yang lebih besar dari subtotal', () async {
    final obatId = await obatService.insert(
      Obat(
        nama: 'CETIRIZINE TEST',
        kodeObat: 'OBTTEST003',
        satuan: 'STRIP',
        kategoriId: 1,
        hargaBeli: 3000,
        hargaJual: 5000,
        stokTersedia: 5,
        stokMinimal: 2,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    expect(
      () => pembelianService.createPembelian(
        diskon: 5000,
        items: [DetailPembelian(obatId: obatId, qty: 1, hargaBeli: 3000)],
      ),
      throwsException,
    );
  });

  test(
    'data manual tetap utuh setelah database ditutup dan dibuka ulang',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'firdan_farma_persistence_',
      );
      final dbPath =
          '${tempDirectory.path}${Platform.pathSeparator}workflow.db';
      addTearDown(() async {
        await DatabaseHelper.instance.closeAndReset();
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      await DatabaseHelper.openFileForTesting(dbPath);
      var db = await DatabaseHelper.instance.database;
      final category = await db.query('kategori_obat', limit: 1);
      expect(category, isNotEmpty);

      var localObatService = ObatService();
      final obatId = await localObatService.insert(
        Obat(
          nama: 'ACYCLOVIR 400 MG',
          kodeObat: '',
          satuan: 'STRIP',
          kategoriId: category.first['id'] as int,
          hargaBeli: 6000,
          hargaJual: 9000,
          stokTersedia: 20,
          stokMinimal: 5,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      await DatabaseHelper.instance.closeAndReset();
      await DatabaseHelper.openFileForTesting(dbPath);
      localObatService = ObatService();
      var persisted = await localObatService.getById(obatId);
      expect(persisted?.nama, 'ACYCLOVIR 400 MG');
      expect(persisted?.satuan, 'STRIP');
      expect(persisted?.hargaBeli, 6000);
      expect(persisted?.hargaJual, 9000);
      expect(persisted?.stokTersedia, 20);

      await StokService().updateStok(
        obatId: obatId,
        jenis: 'masuk',
        jumlah: 10,
        alasan: 'RESTOK',
        hargaBeli: 6200,
        catatan: 'Restok pengujian',
      );

      await DatabaseHelper.instance.closeAndReset();
      await DatabaseHelper.openFileForTesting(dbPath);
      localObatService = ObatService();
      persisted = await localObatService.getById(obatId);
      expect(persisted?.hargaBeli, 6200);
      expect(persisted?.stokTersedia, 30);

      await TransaksiService().createTransaksi(
        total: 27000,
        bayar: 27000,
        metodePembayaran: 'TUNAI',
        items: [
          DetailTransaksi(
            obatId: obatId,
            jumlah: 3,
            hargaSatuan: 9000,
            hargaModalSatuan: 6200,
            subtotal: 27000,
            namaObat: 'ACYCLOVIR 400 MG',
            kodeObat: persisted!.kodeObat,
          ),
        ],
      );

      await DatabaseHelper.instance.closeAndReset();
      await DatabaseHelper.openFileForTesting(dbPath);
      localObatService = ObatService();
      persisted = await localObatService.getById(obatId);
      expect(persisted?.stokTersedia, 27);

      final report = (await LaporanService().getMedicinePeriodReports(
        DateTime.now(),
        DateTime.now(),
      )).singleWhere((item) => item.obatId == obatId);
      expect(report.awl, 20);
      expect(report.msk, 10);
      expect(report.klr, 3);
      expect(report.sisa, 27);
    },
  );
}
