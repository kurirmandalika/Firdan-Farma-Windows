class Supplier {
  final int? id;
  final String nama;
  final String? kontak;
  final String? alamat;

  Supplier({this.id, required this.nama, this.kontak, this.alamat});

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      kontak: map['kontak'] as String?,
      alamat: map['alamat'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'kontak': kontak,
      'alamat': alamat,
    };
  }
}
