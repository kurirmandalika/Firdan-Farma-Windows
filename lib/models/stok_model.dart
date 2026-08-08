class StokMutasi {
  final int? id;
  final int obatId;
  final String jenis; // 'masuk' or 'keluar'
  final int jumlah;
  final String? catatan;
  final String tanggal;

  // Joined display field
  final String? namaObat;

  StokMutasi({
    this.id,
    required this.obatId,
    required this.jenis,
    required this.jumlah,
    this.catatan,
    required this.tanggal,
    this.namaObat,
  });

  factory StokMutasi.fromMap(Map<String, dynamic> map) {
    return StokMutasi(
      id: map['id'] as int?,
      obatId: map['obat_id'] as int,
      jenis: map['jenis'] as String,
      jumlah: map['jumlah'] as int,
      catatan: map['catatan'] as String?,
      tanggal: map['tanggal'] as String,
      namaObat: map['nama_obat'] as String? ?? '(Obat telah dihapus)',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'obat_id': obatId,
      'jenis': jenis,
      'jumlah': jumlah,
      'catatan': catatan,
      'tanggal': tanggal,
    };
  }
}
