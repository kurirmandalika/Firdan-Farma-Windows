class DetailTransaksi {
  final int? id;
  final int? transaksiId;
  final int obatId;
  final int jumlah;
  final double hargaSatuan;
  final double hargaModalSatuan;
  final double subtotal;
  final double subtotalModal;
  final double labaKotor;

  // Joined display field
  final String? namaObat;
  final String? kodeObat;

  DetailTransaksi({
    this.id,
    this.transaksiId,
    required this.obatId,
    required this.jumlah,
    required this.hargaSatuan,
    this.hargaModalSatuan = 0,
    required this.subtotal,
    double? subtotalModal,
    double? labaKotor,
    this.namaObat,
    this.kodeObat,
  }) : subtotalModal = subtotalModal ?? hargaModalSatuan * jumlah,
       labaKotor =
           labaKotor ?? subtotal - (subtotalModal ?? hargaModalSatuan * jumlah);

  factory DetailTransaksi.fromMap(Map<String, dynamic> map) {
    return DetailTransaksi(
      id: map['id'] as int?,
      transaksiId: map['transaksi_id'] as int?,
      obatId: map['obat_id'] as int,
      jumlah: map['jumlah'] as int,
      hargaSatuan: (map['harga_satuan'] as num).toDouble(),
      hargaModalSatuan: (map['harga_modal_satuan'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num).toDouble(),
      subtotalModal: (map['subtotal_modal'] as num?)?.toDouble(),
      labaKotor: (map['laba_kotor'] as num?)?.toDouble(),
      namaObat:
          map['nama_obat_snapshot'] as String? ??
          map['nama_obat'] as String? ??
          '(Obat telah dihapus)',
      kodeObat:
          map['kode_obat_snapshot'] as String? ??
          map['kode_obat'] as String? ??
          '-',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (transaksiId != null) 'transaksi_id': transaksiId,
      'obat_id': obatId,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'harga_modal_satuan': hargaModalSatuan,
      'subtotal': subtotal,
      'subtotal_modal': subtotalModal,
      'laba_kotor': labaKotor,
      'nama_obat_snapshot': namaObat,
      'kode_obat_snapshot': kodeObat,
    };
  }
}
