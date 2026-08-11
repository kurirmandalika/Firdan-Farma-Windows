class DetailTransaksi {
  final int? id;
  final int? transaksiId;
  final int obatId;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;

  // Joined display field
  final String? namaObat;
  final String? kodeObat;

  DetailTransaksi({
    this.id,
    this.transaksiId,
    required this.obatId,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.namaObat,
    this.kodeObat,
  });

  factory DetailTransaksi.fromMap(Map<String, dynamic> map) {
    return DetailTransaksi(
      id: map['id'] as int?,
      transaksiId: map['transaksi_id'] as int?,
      obatId: map['obat_id'] as int,
      jumlah: map['jumlah'] as int,
      hargaSatuan: (map['harga_satuan'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      namaObat: map['nama_obat'] as String? ?? '(Obat telah dihapus)',
      kodeObat: map['kode_obat'] as String? ?? '-',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (transaksiId != null) 'transaksi_id': transaksiId,
      'obat_id': obatId,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
    };
  }
}
