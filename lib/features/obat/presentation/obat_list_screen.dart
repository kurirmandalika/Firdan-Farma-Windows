import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';
import 'package:firdan_farma_windows/application/providers/obat_provider.dart';
import 'package:firdan_farma_windows/application/providers/kategori_provider.dart';
import 'package:firdan_farma_windows/application/providers/supplier_provider.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/shared/widgets/app_page.dart';
import 'package:firdan_farma_windows/shared/widgets/medical_card.dart';
import 'package:firdan_farma_windows/shared/widgets/custom_badge.dart';

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
        content: Text(
          'Apakah Anda yakin ingin menghapus data obat "$namaObat"?\n(Jika obat sudah pernah digunakan dalam transaksi/stok, obat akan dinonaktifkan).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final obatProv = Provider.of<ObatProvider>(
                context,
                listen: false,
              );

              navigator.pop();
              try {
                await obatProv.deleteObat(obatId);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Berhasil memperbarui status obat'),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus data obat: $e'),
                    backgroundColor: AppTheme.dangerRed,
                  ),
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
        content: Text(
          'Apakah Anda yakin ingin mengaktifkan kembali obat "$namaObat"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
            ),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final obatProv = Provider.of<ObatProvider>(
                context,
                listen: false,
              );

              navigator.pop();
              try {
                await obatProv.reactivateObat(obatId);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Obat berhasil diaktifkan kembali'),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengaktifkan obat: $e'),
                    backgroundColor: AppTheme.dangerRed,
                  ),
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
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPageHeader(
            title: 'Katalog Obat',
            subtitle: 'Kelola produk, harga, supplier, dan status stok apotek',
            icon: Icons.medication_outlined,
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showObatDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Obat'),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                          hintText: 'Cari nama atau kode obat',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppTheme.primaryTeal,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(_searchController.clear);
                                    Provider.of<ObatProvider>(
                                      context,
                                      listen: false,
                                    ).setSearchQuery('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() {});
                          Provider.of<ObatProvider>(
                            context,
                            listen: false,
                          ).setSearchQuery(val);
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
                          hintText: 'Cari nama atau kode obat',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppTheme.primaryTeal,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(_searchController.clear);
                                    Provider.of<ObatProvider>(
                                      context,
                                      listen: false,
                                    ).setSearchQuery('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() {});
                          Provider.of<ObatProvider>(
                            context,
                            listen: false,
                          ).setSearchQuery(val);
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
          Expanded(
            child: MedicalCard(
              padding: EdgeInsets.zero,
              child: Consumer<ObatProvider>(
                builder: (context, obatProv, _) {
                  if (obatProv.isLoading && obatProv.obatList.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryTeal,
                      ),
                    );
                  }

                  if (obatProv.obatList.isEmpty) {
                    return const EmptyState(
                      icon: Icons.medication_liquid_outlined,
                      title: 'Data obat belum ditemukan',
                      subtitle: 'Tambah obat baru atau ubah filter pencarian.',
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 820;
                      return Column(
                        children: [
                          if (obatProv.isLoading)
                            LinearProgressIndicator(
                              minHeight: 3,
                              color: AppTheme.primaryTeal,
                              backgroundColor: AppTheme.primaryTealLight,
                            ),
                          if (!isCompact) const _ObatListHeader(),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(10),
                              itemCount: obatProv.obatList.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final obat = obatProv.obatList[index];
                                return _ObatListRow(
                                  obat: obat,
                                  currencyFormatter: currencyFormatter,
                                  isCompact: isCompact,
                                  onEdit: obat.isActive
                                      ? () => _showObatDialog(obat: obat)
                                      : null,
                                  onDelete: obat.isActive
                                      ? () =>
                                            _confirmDelete(obat.id!, obat.nama)
                                      : null,
                                  onReactivate: !obat.isActive
                                      ? () => _confirmReactivate(
                                          obat.id!,
                                          obat.nama,
                                        )
                                      : null,
                                );
                              },
                            ),
                          ),
                        ],
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
        final selectedKatId = Provider.of<ObatProvider>(
          context,
        ).selectedKategoriId;
        final validValue =
            katProv.kategoriList.any((k) => k.id == selectedKatId)
            ? selectedKatId
            : null;

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
            ...katProv.kategoriList.map(
              (k) => DropdownMenuItem<int?>(value: k.id, child: Text(k.nama)),
            ),
          ],
          onChanged: (val) {
            Provider.of<ObatProvider>(
              context,
              listen: false,
            ).setKategoriFilter(val);
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
            Text(
              'Tampilkan Nonaktif',
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ],
        );
      },
    );
  }
}

class _ObatListHeader extends StatelessWidget {
  const _ObatListHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgSubtle,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 112, child: _HeaderLabel('Kode')),
          Expanded(flex: 3, child: _HeaderLabel('Nama Obat')),
          Expanded(flex: 2, child: _HeaderLabel('Kategori')),
          Expanded(flex: 2, child: _HeaderLabel('Supplier')),
          SizedBox(width: 120, child: _HeaderLabel('Harga Jual')),
          SizedBox(width: 124, child: _HeaderLabel('Stok')),
          SizedBox(width: 96, child: _HeaderLabel('Aksi')),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String label;

  const _HeaderLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppTheme.textSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ObatListRow extends StatelessWidget {
  final Obat obat;
  final NumberFormat currencyFormatter;
  final bool isCompact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReactivate;

  const _ObatListRow({
    required this.obat,
    required this.currencyFormatter,
    required this.isCompact,
    this.onEdit,
    this.onDelete,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) return _buildCompactRow();
    return _buildDesktopRow();
  }

  Widget _buildDesktopRow() {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: obat.isActive ? AppTheme.cardBg : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(
              obat.kodeObat,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 3, child: _MedicineName(obat: obat)),
          Expanded(flex: 2, child: _TextCell(obat.namaKategori ?? '-')),
          Expanded(flex: 2, child: _TextCell(obat.namaSupplier ?? '-')),
          SizedBox(
            width: 120,
            child: Text(
              currencyFormatter.format(obat.hargaJual),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryTeal,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 124, child: _StockBadge(obat: obat)),
          SizedBox(
            width: 96,
            child: _ActionButtons(
              obat: obat,
              onEdit: onEdit,
              onDelete: onDelete,
              onReactivate: onReactivate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRow() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: obat.isActive ? AppTheme.cardBg : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _MedicineName(obat: obat)),
              const SizedBox(width: 8),
              _StockBadge(obat: obat),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetaChip(icon: Icons.qr_code_2, label: obat.kodeObat),
              _MetaChip(
                icon: Icons.category_outlined,
                label: obat.namaKategori ?? '-',
              ),
              _MetaChip(
                icon: Icons.local_shipping_outlined,
                label: obat.namaSupplier ?? '-',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  currencyFormatter.format(obat.hargaJual),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
              _ActionButtons(
                obat: obat,
                onEdit: onEdit,
                onDelete: onDelete,
                onReactivate: onReactivate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicineName extends StatelessWidget {
  final Obat obat;

  const _MedicineName({required this.obat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          obat.nama,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            decoration: obat.isActive ? null : TextDecoration.lineThrough,
            color: obat.isActive ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (obat.deskripsi != null && obat.deskripsi!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            obat.deskripsi!,
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _TextCell extends StatelessWidget {
  final String text;

  const _TextCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StockBadge extends StatelessWidget {
  final Obat obat;

  const _StockBadge({required this.obat});

  @override
  Widget build(BuildContext context) {
    if (!obat.isActive) return CustomBadge.warning('Nonaktif');
    if (obat.isHabis) return CustomBadge.danger('Habis');
    if (obat.isStokMenipis) {
      return CustomBadge.warning('${obat.stokTersedia} unit');
    }
    return CustomBadge.success('${obat.stokTersedia} unit');
  }
}

class _ActionButtons extends StatelessWidget {
  final Obat obat;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReactivate;

  const _ActionButtons({
    required this.obat,
    this.onEdit,
    this.onDelete,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    if (!obat.isActive) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Tooltip(
          message: 'Aktifkan kembali',
          child: IconButton(
            onPressed: onReactivate,
            icon: Icon(
              Icons.restore_outlined,
              color: AppTheme.primaryTeal,
              size: 20,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Edit obat',
          child: IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: AppTheme.primaryTeal,
              size: 20,
            ),
            onPressed: onEdit,
          ),
        ),
        Tooltip(
          message: 'Nonaktifkan obat',
          child: IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: AppTheme.dangerRed,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.bgSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
    _kodeController = TextEditingController(
      text:
          o?.kodeObat ??
          'OBT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    _namaController = TextEditingController(text: o?.nama ?? '');
    _hargaBeliController = TextEditingController(
      text: o != null ? o.hargaBeli.toStringAsFixed(0) : '',
    );
    _hargaJualController = TextEditingController(
      text: o != null ? o.hargaJual.toStringAsFixed(0) : '',
    );
    _stokTersediaController = TextEditingController(
      text: o != null ? o.stokTersedia.toString() : '0',
    );
    _stokMinimalController = TextEditingController(
      text: o != null ? o.stokMinimal.toString() : '5',
    );
    _deskripsiController = TextEditingController(text: o?.deskripsi ?? '');

    _selectedKategoriId = o?.kategoriId;
    _selectedSupplierId = o?.supplierId;

    final katList = Provider.of<KategoriProvider>(
      context,
      listen: false,
    ).kategoriList;
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

      if (hargaBeli == null ||
          hargaJual == null ||
          stokTersedia == null ||
          stokMinimal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Format harga atau stok tidak valid! Pastikan hanya memasukkan angka.',
            ),
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

    final validKategoriValue = katList.any((k) => k.id == _selectedKategoriId)
        ? _selectedKategoriId
        : null;
    final validSupplierValue = supList.any((s) => s.id == _selectedSupplierId)
        ? _selectedSupplierId
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
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
                      widget.obat == null
                          ? 'Tambah Obat Baru'
                          : 'Edit Data Obat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
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
                        decoration: const InputDecoration(
                          labelText: 'Kode Obat *',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Obat *',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
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
                        decoration: const InputDecoration(
                          labelText: 'Kategori *',
                        ),
                        items: katList
                            .map(
                              (k) => DropdownMenuItem<int?>(
                                value: k.id,
                                child: Text(k.nama),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedKategoriId = val),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: validSupplierValue,
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('- Tanpa Supplier -'),
                          ),
                          ...supList.map(
                            (s) => DropdownMenuItem<int?>(
                              value: s.id,
                              child: Text(s.nama),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedSupplierId = val),
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
                        decoration: const InputDecoration(
                          labelText: 'Harga Beli (Rp) *',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _hargaJualController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual (Rp) *',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
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
                        decoration: const InputDecoration(
                          labelText: 'Stok Tersedia *',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _stokMinimalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok Minimal *',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deskripsiController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi / Indikasi Obat',
                  ),
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
