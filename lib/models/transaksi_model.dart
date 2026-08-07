import 'detail_transaksi_model.dart';

class Transaksi {
  final int? id;
  final String nomorTransaksi;
  final double total;
  final double bayar;
  final double kembali;
  final String tanggal;
  final int jumlahItem;
  final List<DetailTransaksi> items;

  Transaksi({
    this.id,
    required this.nomorTransaksi,
    required this.total,
    required this.bayar,
    required this.kembali,
    required this.tanggal,
    required this.jumlahItem,
    this.items = const [],
  });

  factory Transaksi.fromMap(Map<String, dynamic> map, {List<DetailTransaksi> items = const []}) {
    return Transaksi(
      id: map['id'] as int?,
      nomorTransaksi: map['nomor_transaksi'] as String,
      total: (map['total'] as num).toDouble(),
      bayar: (map['bayar'] as num).toDouble(),
      kembali: (map['kembali'] as num).toDouble(),
      tanggal: map['tanggal'] as String,
      jumlahItem: map['jumlah_item'] as int? ?? 0,
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
      'tanggal': tanggal,
      'jumlah_item': jumlahItem,
    };
  }
}
