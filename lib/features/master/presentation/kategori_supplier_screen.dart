import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firdan_farma_windows/data/models/kategori_model.dart';
import 'package:firdan_farma_windows/data/models/supplier_model.dart';
import 'package:firdan_farma_windows/application/providers/kategori_provider.dart';
import 'package:firdan_farma_windows/application/providers/supplier_provider.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/shared/widgets/app_page.dart';
import 'package:firdan_farma_windows/shared/widgets/medical_card.dart';

class KategoriSupplierScreen extends StatefulWidget {
  const KategoriSupplierScreen({super.key});

  @override
  State<KategoriSupplierScreen> createState() => _KategoriSupplierScreenState();
}

class _KategoriSupplierScreenState extends State<KategoriSupplierScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KategoriProvider>(context, listen: false).fetchKategori();
      Provider.of<SupplierProvider>(context, listen: false).fetchSupplier();
    });
  }

  void _showKategoriDialog({KategoriObat? kategori}) {
    final namaController = TextEditingController(text: kategori?.nama ?? '');
    final deskripsiController = TextEditingController(
      text: kategori?.deskripsi ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(kategori == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Kategori *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.trim().isEmpty) return;
              final navigator = Navigator.of(dialogContext);
              final katProv = Provider.of<KategoriProvider>(
                context,
                listen: false,
              );
              final newKat = KategoriObat(
                id: kategori?.id,
                nama: namaController.text.trim(),
                deskripsi: deskripsiController.text.trim(),
              );

              if (kategori == null) {
                await katProv.addKategori(newKat);
              } else {
                await katProv.updateKategori(newKat);
              }
              navigator.pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKategori(int id, String nama) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final katProv = Provider.of<KategoriProvider>(
                context,
                listen: false,
              );

              navigator.pop();
              try {
                await katProv.deleteKategori(id);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Kategori berhasil dihapus')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal menghapus kategori: ${e.toString().replaceAll('Exception: ', '')}',
                    ),
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

  void _showSupplierDialog({Supplier? supplier}) {
    final namaController = TextEditingController(text: supplier?.nama ?? '');
    final kontakController = TextEditingController(
      text: supplier?.kontak ?? '',
    );
    final alamatController = TextEditingController(
      text: supplier?.alamat ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(supplier == null ? 'Tambah Supplier' : 'Edit Supplier'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Supplier *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kontakController,
                decoration: const InputDecoration(labelText: 'Kontak / No HP'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.trim().isEmpty) return;
              final navigator = Navigator.of(dialogContext);
              final supProv = Provider.of<SupplierProvider>(
                context,
                listen: false,
              );
              final newSup = Supplier(
                id: supplier?.id,
                nama: namaController.text.trim(),
                kontak: kontakController.text.trim(),
                alamat: alamatController.text.trim(),
              );

              if (supplier == null) {
                await supProv.addSupplier(newSup);
              } else {
                await supProv.updateSupplier(newSup);
              }
              navigator.pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSupplier(int id, String nama) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Supplier'),
        content: Text('Apakah Anda yakin ingin menghapus supplier "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final supProv = Provider.of<SupplierProvider>(
                context,
                listen: false,
              );

              navigator.pop();
              try {
                await supProv.deleteSupplier(id);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Supplier berhasil dihapus')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal menghapus supplier: ${e.toString().replaceAll('Exception: ', '')}',
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPageHeader(
            title: 'Kategori dan Supplier',
            subtitle: 'Kelola master data yang dipakai pada katalog obat',
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 900;
                if (isCompact) {
                  return DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: TabBar(
                            labelColor: AppTheme.primaryTeal,
                            unselectedLabelColor: AppTheme.textSecondary,
                            indicatorColor: AppTheme.primaryTeal,
                            tabs: [
                              Tab(
                                icon: Icon(Icons.category_outlined),
                                text: 'Kategori',
                              ),
                              Tab(
                                icon: Icon(Icons.local_shipping_outlined),
                                text: 'Supplier',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildKategoriSection(context),
                              _buildSupplierSection(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildKategoriSection(context)),
                    const SizedBox(width: 18),
                    Expanded(child: _buildSupplierSection(context)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriSection(BuildContext context) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.category_outlined,
            title: 'Kategori Obat',
            subtitle: 'Pengelompokan produk untuk filter dan laporan',
            trailing: ElevatedButton.icon(
              onPressed: () => _showKategoriDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah'),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: Consumer<KategoriProvider>(
              builder: (context, katProv, _) {
                if (katProv.isLoading && katProv.kategoriList.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                  );
                }
                if (katProv.kategoriList.isEmpty) {
                  return const EmptyState(
                    icon: Icons.category_outlined,
                    title: 'Belum ada kategori',
                    subtitle:
                        'Tambahkan kategori agar katalog obat lebih mudah difilter.',
                  );
                }
                return _MasterList(
                  isLoading: katProv.isLoading,
                  itemCount: katProv.kategoriList.length,
                  itemBuilder: (context, index) {
                    final k = katProv.kategoriList[index];
                    return _MasterTile(
                      icon: Icons.category_outlined,
                      title: k.nama,
                      subtitle: k.deskripsi?.isNotEmpty == true
                          ? k.deskripsi!
                          : 'Tanpa deskripsi',
                      onEdit: () => _showKategoriDialog(kategori: k),
                      onDelete: () => _confirmDeleteKategori(k.id!, k.nama),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierSection(BuildContext context) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.local_shipping_outlined,
            title: 'Data Supplier',
            subtitle: 'Pemasok yang terhubung dengan katalog obat',
            trailing: ElevatedButton.icon(
              onPressed: () => _showSupplierDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah'),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: Consumer<SupplierProvider>(
              builder: (context, supProv, _) {
                if (supProv.isLoading && supProv.supplierList.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                  );
                }
                if (supProv.supplierList.isEmpty) {
                  return const EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'Belum ada supplier',
                    subtitle: 'Tambahkan supplier untuk melengkapi data obat.',
                  );
                }
                return _MasterList(
                  isLoading: supProv.isLoading,
                  itemCount: supProv.supplierList.length,
                  itemBuilder: (context, index) {
                    final s = supProv.supplierList[index];
                    return _MasterTile(
                      icon: Icons.local_shipping_outlined,
                      title: s.nama,
                      subtitle:
                          'Kontak: ${s.kontak?.isNotEmpty == true ? s.kontak : '-'} | Alamat: ${s.alamat?.isNotEmpty == true ? s.alamat : '-'}',
                      onEdit: () => _showSupplierDialog(supplier: s),
                      onDelete: () => _confirmDeleteSupplier(s.id!, s.nama),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterList extends StatelessWidget {
  final bool isLoading;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _MasterList({
    required this.isLoading,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isLoading)
          LinearProgressIndicator(
            minHeight: 3,
            color: AppTheme.primaryTeal,
            backgroundColor: AppTheme.primaryTealLight,
          ),
        Expanded(
          child: ListView.separated(
            itemCount: itemCount,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: itemBuilder,
          ),
        ),
      ],
    );
  }
}

class _MasterTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MasterTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryTealLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: AppTheme.primaryTeal, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Edit',
            child: IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: AppTheme.primaryTeal,
                size: 19,
              ),
              onPressed: onEdit,
            ),
          ),
          Tooltip(
            message: 'Hapus',
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: AppTheme.dangerRed,
                size: 19,
              ),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
