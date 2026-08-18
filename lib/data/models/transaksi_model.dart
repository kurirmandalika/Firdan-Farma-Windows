import 'package:firdan_farma_windows/data/models/detail_transaksi_model.dart';

class Transaksi {
  final int? id;
  final String nomorTransaksi;
  final double total;
  final double bayar;
  final double kembali;
  final String metodePembayaran;
  final String tanggal;
  final int jumlahItem;
  final double totalSebelumDiskon;
  final double diskon;
  final bool diberiDiskon;
  final String? laporanTanggal;
  final String? kodeLaporan;
  final int? userId;
  final String? usernameSnapshot;
  final List<DetailTransaksi> items;

  Transaksi({
    this.id,
    required this.nomorTransaksi,
    required this.total,
    required this.bayar,
    required this.kembali,
    this.metodePembayaran = 'TUNAI',
    required this.tanggal,
    required this.jumlahItem,
    double? totalSebelumDiskon,
    this.diskon = 0,
    this.diberiDiskon = false,
    this.laporanTanggal,
    this.kodeLaporan,
    this.userId,
    this.usernameSnapshot,
    this.items = const [],
  }) : totalSebelumDiskon = totalSebelumDiskon ?? total;

  factory Transaksi.fromMap(
    Map<String, dynamic> map, {
    List<DetailTransaksi> items = const [],
  }) {
    return Transaksi(
      id: map['id'] as int?,
      nomorTransaksi: map['nomor_transaksi'] as String,
      total: (map['total'] as num).toDouble(),
      bayar: (map['bayar'] as num).toDouble(),
      kembali: (map['kembali'] as num).toDouble(),
      metodePembayaran: map['metode_pembayaran'] as String? ?? 'TUNAI',
      tanggal: map['tanggal'] as String,
      jumlahItem: map['jumlah_item'] as int? ?? 0,
      totalSebelumDiskon:
          (map['total_sebelum_diskon'] as num?)?.toDouble() ??
          (map['total'] as num).toDouble(),
      diskon: (map['diskon'] as num?)?.toDouble() ?? 0,
      diberiDiskon: (map['diberi_diskon'] as int? ?? 0) == 1,
      laporanTanggal: map['laporan_tanggal'] as String?,
      kodeLaporan: map['kode_laporan'] as String?,
      userId: map['user_id'] as int?,
      usernameSnapshot: map['username_snapshot'] as String?,
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nomor_transaksi': nomorTransaksi,
      'total': total,
      'bayar': bayar,
      'kembali': kembali,
      'metode_pembayaran': metodePembayaran,
      'tanggal': tanggal,
      'jumlah_item': jumlahItem,
      'total_sebelum_diskon': totalSebelumDiskon,
      'diskon': diskon,
      'diberi_diskon': diberiDiskon ? 1 : 0,
      'laporan_tanggal': laporanTanggal,
      'kode_laporan': kodeLaporan,
      'user_id': userId,
      'username_snapshot': usernameSnapshot,
    };
  }
}
