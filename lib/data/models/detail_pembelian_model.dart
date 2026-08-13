class DetailPembelian {
  final int? id;
  final int? pembelianId;
  final int obatId;
  final int qty;
  final double hargaBeli;
  final double subtotal;
  final String createdAt;

  // Joined display fields
  final String? namaObat;
  final String? kodeObat;
  final String? satuan;

  DetailPembelian({
    this.id,
    this.pembelianId,
    required this.obatId,
    required this.qty,
    required this.hargaBeli,
    double? subtotal,
    String? createdAt,
    this.namaObat,
    this.kodeObat,
    this.satuan,
  }) : subtotal = subtotal ?? qty * hargaBeli,
       createdAt = createdAt ?? DateTime.now().toIso8601String();

  factory DetailPembelian.fromMap(Map<String, dynamic> map) {
    return DetailPembelian(
      id: map['id'] as int?,
      pembelianId: map['pembelian_id'] as int?,
      obatId: map['obat_id'] as int,
      qty: map['qty'] as int,
      hargaBeli: (map['harga_beli'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      namaObat: map['nama_obat'] as String?,
      kodeObat: map['kode_obat'] as String?,
      satuan: map['satuan'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (pembelianId != null) 'pembelian_id': pembelianId,
      'obat_id': obatId,
      'qty': qty,
      'harga_beli': hargaBeli,
      'subtotal': subtotal,
      'created_at': createdAt,
    };
  }
}
