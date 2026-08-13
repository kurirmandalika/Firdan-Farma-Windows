class Obat {
  final int? id;
  final String nama;
  final String kodeObat;
  final String satuan;
  final int kategoriId;
  final int? supplierId;
  final double hargaBeli;
  final double hargaJual;
  final int stokMinimal;
  final int stokTersedia;
  final String? deskripsi;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  // Extra joined fields for display UI
  final String? namaKategori;
  final String? namaSupplier;

  Obat({
    this.id,
    required this.nama,
    required this.kodeObat,
    this.satuan = 'PCS',
    required this.kategoriId,
    this.supplierId,
    required this.hargaBeli,
    required this.hargaJual,
    this.stokMinimal = 5,
    this.stokTersedia = 0,
    this.deskripsi,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
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
      satuan: (map['satuan'] as String?)?.trim().isNotEmpty == true
          ? (map['satuan'] as String).trim().toUpperCase()
          : 'PCS',
      kategoriId: map['kategori_id'] as int,
      supplierId: map['supplier_id'] as int?,
      hargaBeli: (map['harga_beli'] as num).toDouble(),
      hargaJual: (map['harga_jual'] as num).toDouble(),
      stokMinimal: map['stok_minimal'] as int? ?? 5,
      stokTersedia: map['stok_tersedia'] as int? ?? 0,
      deskripsi: map['deskripsi'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] as String?,
      namaKategori: map['nama_kategori'] as String?,
      namaSupplier: map['nama_supplier'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'kode_obat': kodeObat,
      'satuan': satuan.trim().isEmpty ? 'PCS' : satuan.trim().toUpperCase(),
      'kategori_id': kategoriId,
      'supplier_id': supplierId,
      'harga_beli': hargaBeli,
      'harga_jual': hargaJual,
      'stok_minimal': stokMinimal,
      'stok_tersedia': stokTersedia,
      'deskripsi': deskripsi,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Obat copyWith({
    int? id,
    String? nama,
    String? kodeObat,
    String? satuan,
    int? kategoriId,
    int? supplierId,
    double? hargaBeli,
    double? hargaJual,
    int? stokMinimal,
    int? stokTersedia,
    String? deskripsi,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    String? namaKategori,
    String? namaSupplier,
  }) {
    return Obat(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kodeObat: kodeObat ?? this.kodeObat,
      satuan: satuan ?? this.satuan,
      kategoriId: kategoriId ?? this.kategoriId,
      supplierId: supplierId ?? this.supplierId,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      hargaJual: hargaJual ?? this.hargaJual,
      stokMinimal: stokMinimal ?? this.stokMinimal,
      stokTersedia: stokTersedia ?? this.stokTersedia,
      deskripsi: deskripsi ?? this.deskripsi,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      namaKategori: namaKategori ?? this.namaKategori,
      namaSupplier: namaSupplier ?? this.namaSupplier,
    );
  }
}
