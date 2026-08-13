class StokMutasi {
  final int? id;
  final int obatId;
  final String jenis; // 'masuk' or 'keluar'
  final int jumlah;
  final String tipeMutasi;
  final String? referenceType;
  final int? referenceId;
  final double? hargaBeliSnapshot;
  final int? stokSebelum;
  final int? stokSesudah;
  final String? alasan;
  final String? catatan;
  final String tanggal;
  final String? createdAt;

  // Joined display field
  final String? namaObat;
  final String? kodeObat;
  final String? satuan;

  StokMutasi({
    this.id,
    required this.obatId,
    required this.jenis,
    required this.jumlah,
    this.tipeMutasi = 'PENYESUAIAN_MASUK',
    this.referenceType,
    this.referenceId,
    this.hargaBeliSnapshot,
    this.stokSebelum,
    this.stokSesudah,
    this.alasan,
    this.catatan,
    required this.tanggal,
    this.createdAt,
    this.namaObat,
    this.kodeObat,
    this.satuan,
  });

  bool get isMasuk => jenis == 'masuk';
  String get qtySigned => '${isMasuk ? '+' : '-'}$jumlah';

  factory StokMutasi.fromMap(Map<String, dynamic> map) {
    return StokMutasi(
      id: map['id'] as int?,
      obatId: map['obat_id'] as int,
      jenis: map['jenis'] as String,
      jumlah: map['jumlah'] as int,
      tipeMutasi: map['tipe_mutasi'] as String? ?? 'PENYESUAIAN_MASUK',
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as int?,
      hargaBeliSnapshot: (map['harga_beli_snapshot'] as num?)?.toDouble(),
      stokSebelum: map['stok_sebelum'] as int?,
      stokSesudah: map['stok_sesudah'] as int?,
      alasan: map['alasan'] as String?,
      catatan: map['catatan'] as String?,
      tanggal: map['tanggal'] as String,
      createdAt: map['created_at'] as String?,
      namaObat: map['nama_obat'] as String? ?? '(Obat telah dihapus)',
      kodeObat: map['kode_obat'] as String? ?? '-',
      satuan: map['satuan'] as String? ?? 'PCS',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'obat_id': obatId,
      'jenis': jenis,
      'jumlah': jumlah,
      'tipe_mutasi': tipeMutasi,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'harga_beli_snapshot': hargaBeliSnapshot,
      'stok_sebelum': stokSebelum,
      'stok_sesudah': stokSesudah,
      'alasan': alasan,
      'catatan': catatan,
      'tanggal': tanggal,
      'created_at': createdAt,
    };
  }
}
