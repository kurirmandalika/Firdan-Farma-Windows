class KategoriObat {
  final int? id;
  final String nama;
  final String? deskripsi;

  KategoriObat({
    this.id,
    required this.nama,
    this.deskripsi,
  });

  factory KategoriObat.fromMap(Map<String, dynamic> map) {
    return KategoriObat(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      deskripsi: map['deskripsi'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
    };
  }
}
