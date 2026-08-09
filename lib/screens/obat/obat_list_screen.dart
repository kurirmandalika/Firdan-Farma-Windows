import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/obat_model.dart';
import '../../providers/obat_provider.dart';
import '../../providers/kategori_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_card.dart';
import '../../widgets/custom_badge.dart';

class ObatListScreen extends StatefulWidget {
  const ObatListScreen({super.key});

  @override
  State<ObatListScreen> createState() => _ObatListScreenState();
}

class _ObatListScreenState extends State<ObatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObatProvider>(context, listen: false).fetchObat();
      Provider.of<KategoriProvider>(context, listen: false).fetchKategori();
      Provider.of<SupplierProvider>(context, listen: false).fetchSupplier();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showObatDialog({Obat? obat}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ObatFormDialog(obat: obat),
    );
  }

  void _confirmDelete(int obatId, String namaObat) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data obat "$namaObat"?\n(Jika obat sudah pernah digunakan dalam transaksi/stok, obat akan dinonaktifkan).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final obatProv = Provider.of<ObatProvider>(context, listen: false);

              navigator.pop();
              try {
                await obatProv.deleteObat(obatId);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Berhasil memperbarui status obat')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Gagal menghapus data obat: $e'), backgroundColor: AppTheme.dangerRed),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmReactivate(int obatId, String namaObat) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aktifkan Kembali Obat'),
        content: Text('Apakah Anda yakin ingin mengaktifkan kembali obat "$namaObat"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final obatProv = Provider.of<ObatProvider>(context, listen: false);

              navigator.pop();
              try {
                await obatProv.reactivateObat(obatId);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Obat berhasil diaktifkan kembali')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Gagal mengaktifkan obat: $e'), backgroundColor: AppTheme.dangerRed),
                );
              }
            },
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Katalog & Data Obat',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kelola inventaris obat, harga beli, harga jual, dan stok minimal',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showObatDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Obat Baru'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Filters Card
          MedicalCard(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 750;
                if (isCompact) {
                  return Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari Nama / Kode Obat...',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    Provider.of<ObatProvider>(context, listen: false).setSearchQuery('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          Provider.of<ObatProvider>(context, listen: false).setSearchQuery(val);
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildCategoryDropdown(context)),
                          const SizedBox(width: 12),
                          _buildInactiveCheckbox(context),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari Nama / Kode Obat...',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    Provider.of<ObatProvider>(context, listen: false).setSearchQuery('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          Provider.of<ObatProvider>(context, listen: false).setSearchQuery(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 220,
                      child: _buildCategoryDropdown(context),
                    ),
                    const SizedBox(width: 16),
                    _buildInactiveCheckbox(context),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // Data Table Container with Horizontal Scroll
          Expanded(
            child: MedicalCard(
              padding: EdgeInsets.zero,
              child: Consumer<ObatProvider>(
                builder: (context, obatProv, _) {
                  if (obatProv.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
                  }

                  if (obatProv.obatList.isEmpty) {
                    return const Center(
                      child: Text('Belum ada data obat', style: TextStyle(color: AppTheme.textSecondary)),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppTheme.bgLight),
                                columns: const [
                                  DataColumn(label: Text('KODE', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('NAMA OBAT', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('KATEGORI', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('SUPPLIER', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('HARGA BELI', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('HARGA JUAL', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('STOK / STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: obatProv.obatList.map((obat) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(obat.kodeObat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                      DataCell(Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            obat.nama,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              decoration: obat.isActive ? null : TextDecoration.lineThrough,
                                              color: obat.isActive ? AppTheme.textPrimary : AppTheme.textMuted,
                                            ),
                                          ),
                                          if (obat.deskripsi != null && obat.deskripsi!.isNotEmpty)
                                            Text(obat.deskripsi!, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1),
                                        ],
                                      )),
                                      DataCell(Text(obat.namaKategori ?? '-', style: const TextStyle(fontSize: 12))),
                                      DataCell(Text(obat.namaSupplier ?? '-', style: const TextStyle(fontSize: 12))),
                                      DataCell(Text(currencyFormatter.format(obat.hargaBeli), style: const TextStyle(fontSize: 12))),
                                      DataCell(Text(currencyFormatter.format(obat.hargaJual), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 13))),
                                      DataCell(
                                        !obat.isActive
                                            ? CustomBadge.warning('Nonaktif')
                                            : obat.isHabis
                                                ? CustomBadge.danger('Habis (0)')
                                                : obat.isStokMenipis
                                                    ? CustomBadge.warning('${obat.stokTersedia} unit')
                                                    : CustomBadge.success('${obat.stokTersedia} unit'),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            if (obat.isActive) ...[
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryTeal, size: 20),
                                                onPressed: () => _showObatDialog(obat: obat),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 20),
                                                onPressed: () => _confirmDelete(obat.id!, obat.nama),
                                              ),
                                            ] else ...[
                                              IconButton(
                                                icon: const Icon(Icons.restore_outlined, color: AppTheme.primaryTeal, size: 20),
                                                tooltip: 'Aktifkan Kembali',
                                                onPressed: () => _confirmReactivate(obat.id!, obat.nama),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return Consumer<KategoriProvider>(
      builder: (context, katProv, _) {
        final selectedKatId = Provider.of<ObatProvider>(context).selectedKategoriId;
        final validValue = katProv.kategoriList.any((k) => k.id == selectedKatId) ? selectedKatId : null;

        return DropdownButtonFormField<int?>(
          initialValue: validValue,
          decoration: const InputDecoration(
            hintText: 'Semua Kategori',
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Semua Kategori'),
            ),
            ...katProv.kategoriList.map((k) => DropdownMenuItem<int?>(
                  value: k.id,
                  child: Text(k.nama),
                )),
          ],
          onChanged: (val) {
            Provider.of<ObatProvider>(context, listen: false).setKategoriFilter(val);
          },
        );
      },
    );
  }

  Widget _buildInactiveCheckbox(BuildContext context) {
    return Consumer<ObatProvider>(
      builder: (context, obatProv, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: obatProv.showInactive,
              activeColor: AppTheme.primaryTeal,
              onChanged: (val) {
                obatProv.setShowInactive(val ?? false);
              },
            ),
            const Text(
              'Tampilkan Nonaktif',
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ],
        );
      },
    );
  }
}

class _ObatFormDialog extends StatefulWidget {
  final Obat? obat;

  const _ObatFormDialog({this.obat});

  @override
  State<_ObatFormDialog> createState() => _ObatFormDialogState();
}

class _ObatFormDialogState extends State<_ObatFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _kodeController;
  late TextEditingController _namaController;
  late TextEditingController _hargaBeliController;
  late TextEditingController _hargaJualController;
  late TextEditingController _stokTersediaController;
  late TextEditingController _stokMinimalController;
  late TextEditingController _deskripsiController;

  int? _selectedKategoriId;
  int? _selectedSupplierId;

  @override
  void initState() {
    super.initState();
    final o = widget.obat;
    _kodeController = TextEditingController(text: o?.kodeObat ?? 'OBT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    _namaController = TextEditingController(text: o?.nama ?? '');
    _hargaBeliController = TextEditingController(text: o != null ? o.hargaBeli.toStringAsFixed(0) : '');
    _hargaJualController = TextEditingController(text: o != null ? o.hargaJual.toStringAsFixed(0) : '');
    _stokTersediaController = TextEditingController(text: o != null ? o.stokTersedia.toString() : '0');
    _stokMinimalController = TextEditingController(text: o != null ? o.stokMinimal.toString() : '5');
    _deskripsiController = TextEditingController(text: o?.deskripsi ?? '');

    _selectedKategoriId = o?.kategoriId;
    _selectedSupplierId = o?.supplierId;

    final katList = Provider.of<KategoriProvider>(context, listen: false).kategoriList;
    if (_selectedKategoriId == null && katList.isNotEmpty) {
      _selectedKategoriId = katList.first.id;
    }
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _stokTersediaController.dispose();
    _stokMinimalController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedKategoriId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori obat terlebih dahulu!')),
        );
        return;
      }

      final hargaBeli = double.tryParse(_hargaBeliController.text.trim());
      final hargaJual = double.tryParse(_hargaJualController.text.trim());
      final stokTersedia = int.tryParse(_stokTersediaController.text.trim());
      final stokMinimal = int.tryParse(_stokMinimalController.text.trim());

      if (hargaBeli == null || hargaJual == null || stokTersedia == null || stokMinimal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format harga atau stok tidak valid! Pastikan hanya memasukkan angka.'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
        return;
      }

      final obatProv = Provider.of<ObatProvider>(context, listen: false);
      final newObat = Obat(
        id: widget.obat?.id,
        nama: _namaController.text.trim(),
        kodeObat: _kodeController.text.trim(),
        kategoriId: _selectedKategoriId!,
        supplierId: _selectedSupplierId,
        hargaBeli: hargaBeli,
        hargaJual: hargaJual,
        stokTersedia: stokTersedia,
        stokMinimal: stokMinimal,
        deskripsi: _deskripsiController.text.trim(),
        createdAt: widget.obat?.createdAt ?? DateTime.now().toIso8601String(),
      );

      final navigator = Navigator.of(context);
      if (widget.obat == null) {
        await obatProv.addObat(newObat);
      } else {
        await obatProv.updateObat(newObat);
      }

      if (mounted) {
        navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final katList = Provider.of<KategoriProvider>(context).kategoriList;
    final supList = Provider.of<SupplierProvider>(context).supplierList;

    final validKategoriValue = katList.any((k) => k.id == _selectedKategoriId) ? _selectedKategoriId : null;
    final validSupplierValue = supList.any((s) => s.id == _selectedSupplierId) ? _selectedSupplierId : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.obat == null ? 'Tambah Obat Baru' : 'Edit Data Obat',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _kodeController,
                        decoration: const InputDecoration(labelText: 'Kode Obat *'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(labelText: 'Nama Obat *'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: validKategoriValue,
                        decoration: const InputDecoration(labelText: 'Kategori *'),
                        items: katList.map((k) => DropdownMenuItem<int?>(value: k.id, child: Text(k.nama))).toList(),
                        onChanged: (val) => setState(() => _selectedKategoriId = val),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: validSupplierValue,
                        decoration: const InputDecoration(labelText: 'Supplier'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('- Tanpa Supplier -')),
                          ...supList.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.nama))),
                        ],
                        onChanged: (val) => setState(() => _selectedSupplierId = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hargaBeliController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Harga Beli (Rp) *'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _hargaJualController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Harga Jual (Rp) *'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stokTersediaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stok Tersedia *'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _stokMinimalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stok Minimal *'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deskripsiController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Deskripsi / Indikasi Obat'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Simpan Data Obat'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
