class Obat {
  final int? id;
  final String nama;
  final String kodeObat;
  final int kategoriId;
  final int? supplierId;
  final double hargaBeli;
  final double hargaJual;
  final int stokMinimal;
  final int stokTersedia;
  final String? deskripsi;
  final String createdAt;

  // Extra joined fields for display UI
  final String? namaKategori;
  final String? namaSupplier;

  Obat({
    this.id,
    required this.nama,
    required this.kodeObat,
    required this.kategoriId,
    this.supplierId,
    required this.hargaBeli,
    required this.hargaJual,
    this.stokMinimal = 5,
    this.stokTersedia = 0,
    this.deskripsi,
    required this.createdAt,
    this.namaKategori,
    this.namaSupplier,
  });

  bool get isStokMenipis => stokTersedia <= stokMinimal;
  bool get isHabis => stokTersedia <= 0;

  factory Obat.fromMap(Map<String, dynamic> map) {
    return Obat(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      kodeObat: map['kode_obat'] as String,
      kategoriId: map['kategori_id'] as int,
      supplierId: map['supplier_id'] as int?,
      hargaBeli: (map['harga_beli'] as num).toDouble(),
      hargaJual: (map['harga_jual'] as num).toDouble(),
      stokMinimal: map['stok_minimal'] as int? ?? 5,
      stokTersedia: map['stok_tersedia'] as int? ?? 0,
      deskripsi: map['deskripsi'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      namaKategori: map['nama_kategori'] as String?,
      namaSupplier: map['nama_supplier'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'kode_obat': kodeObat,
      'kategori_id': kategoriId,
      'supplier_id': supplierId,
      'harga_beli': hargaBeli,
      'harga_jual': hargaJual,
      'stok_minimal': stokMinimal,
      'stok_tersedia': stokTersedia,
      'deskripsi': deskripsi,
      'created_at': createdAt,
    };
  }

  Obat copyWith({
    int? id,
    String? nama,
    String? kodeObat,
    int? kategoriId,
    int? supplierId,
    double? hargaBeli,
    double? hargaJual,
    int? stokMinimal,
    int? stokTersedia,
    String? deskripsi,
    String? createdAt,
    String? namaKategori,
    String? namaSupplier,
  }) {
    return Obat(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kodeObat: kodeObat ?? this.kodeObat,
      kategoriId: kategoriId ?? this.kategoriId,
      supplierId: supplierId ?? this.supplierId,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      hargaJual: hargaJual ?? this.hargaJual,
      stokMinimal: stokMinimal ?? this.stokMinimal,
      stokTersedia: stokTersedia ?? this.stokTersedia,
      deskripsi: deskripsi ?? this.deskripsi,
      createdAt: createdAt ?? this.createdAt,
      namaKategori: namaKategori ?? this.namaKategori,
      namaSupplier: namaSupplier ?? this.namaSupplier,
    );
  }
}
