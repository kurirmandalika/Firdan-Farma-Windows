import 'package:firdan_farma_windows/data/models/detail_pembelian_model.dart';

class Pembelian {
  final int? id;
  final String nomorPembelian;
  final int? supplierId;
  final String tanggal;
  final String? nomorFaktur;
  final double subtotal;
  final double diskon;
  final double total;
  final String? catatan;
  final int? userId;
  final String? usernameSnapshot;
  final String createdAt;
  final String? updatedAt;
  final List<DetailPembelian> items;

  // Joined display field
  final String? namaSupplier;

  Pembelian({
    this.id,
    required this.nomorPembelian,
    this.supplierId,
    required this.tanggal,
    this.nomorFaktur,
    required this.subtotal,
    this.diskon = 0,
    double? total,
    this.catatan,
    String? createdAt,
    this.updatedAt,
    this.items = const [],
    this.namaSupplier,
    this.userId,
    this.usernameSnapshot,
  }) : total = total ?? (subtotal - diskon),
       createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory Pembelian.fromMap(
    Map<String, dynamic> map, {
    List<DetailPembelian> items = const [],
  }) {
    return Pembelian(
      id: map['id'] as int?,
      nomorPembelian: map['nomor_pembelian'] as String,
      supplierId: map['supplier_id'] as int?,
      tanggal: map['tanggal'] as String,
      nomorFaktur: map['nomor_faktur'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      diskon: (map['diskon'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num).toDouble(),
      catatan: map['catatan'] as String?,
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] as String?,
      namaSupplier: map['nama_supplier'] as String?,
      userId: map['user_id'] as int?,
      usernameSnapshot: map['username_snapshot'] as String?,
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nomor_pembelian': nomorPembelian,
      'supplier_id': supplierId,
      'tanggal': tanggal,
      'nomor_faktur': nomorFaktur,
      'subtotal': subtotal,
      'diskon': diskon,
      'total': total,
      'catatan': catatan,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user_id': userId,
      'username_snapshot': usernameSnapshot,
    };
  }
}
