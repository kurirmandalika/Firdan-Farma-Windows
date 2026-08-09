import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kategori_model.dart';
import '../../models/supplier_model.dart';
import '../../providers/kategori_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_card.dart';

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
    final deskripsiController = TextEditingController(text: kategori?.deskripsi ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(kategori == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Kategori *')),
            const SizedBox(height: 12),
            TextField(controller: deskripsiController, decoration: const InputDecoration(labelText: 'Deskripsi')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.trim().isNotEmpty) {
                final navigator = Navigator.of(dialogContext);
                final katProv = Provider.of<KategoriProvider>(context, listen: false);
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
              }
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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final katProv = Provider.of<KategoriProvider>(context, listen: false);

              navigator.pop();
              try {
                await katProv.deleteKategori(id);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Kategori berhasil dihapus')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus kategori: ${e.toString().replaceAll('Exception: ', '')}'),
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
    final kontakController = TextEditingController(text: supplier?.kontak ?? '');
    final alamatController = TextEditingController(text: supplier?.alamat ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(supplier == null ? 'Tambah Supplier' : 'Edit Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Supplier *')),
            const SizedBox(height: 12),
            TextField(controller: kontakController, decoration: const InputDecoration(labelText: 'Kontak / No HP')),
            const SizedBox(height: 12),
            TextField(controller: alamatController, decoration: const InputDecoration(labelText: 'Alamat')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.trim().isNotEmpty) {
                final navigator = Navigator.of(dialogContext);
                final supProv = Provider.of<SupplierProvider>(context, listen: false);
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
              }
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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              final supProv = Provider.of<SupplierProvider>(context, listen: false);

              navigator.pop();
              try {
                await supProv.deleteSupplier(id);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Supplier berhasil dihapus')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus supplier: ${e.toString().replaceAll('Exception: ', '')}'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: isCompact
              ? Column(
                  children: [
                    _buildKategoriSection(context),
                    const SizedBox(height: 20),
                    _buildSupplierSection(context),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildKategoriSection(context)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildSupplierSection(context)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildKategoriSection(BuildContext context) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.category_outlined, color: AppTheme.primaryTeal),
                  SizedBox(width: 8),
                  Text('Kategori Obat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showKategoriDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Kategori'),
              ),
            ],
          ),
          const Divider(height: 20),
          Consumer<KategoriProvider>(
            builder: (context, katProv, _) {
              if (katProv.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
              }
              if (katProv.kategoriList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Belum ada data kategori')),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: katProv.kategoriList.length,
                separatorBuilder: (context, index) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  final k = katProv.kategoriList[index];
                  return ListTile(
                    title: Text(k.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(k.deskripsi ?? '-', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.primaryTeal, size: 18),
                          onPressed: () => _showKategoriDialog(kategori: k),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.dangerRed, size: 18),
                          onPressed: () => _confirmDeleteKategori(k.id!, k.nama),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: AppTheme.primaryTeal),
                  SizedBox(width: 8),
                  Text('Data Supplier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showSupplierDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Supplier'),
              ),
            ],
          ),
          const Divider(height: 20),
          Consumer<SupplierProvider>(
            builder: (context, supProv, _) {
              if (supProv.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
              }
              if (supProv.supplierList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Belum ada data supplier')),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: supProv.supplierList.length,
                separatorBuilder: (context, index) => const Divider(height: 8),
                itemBuilder: (context, index) {
                  final s = supProv.supplierList[index];
                  return ListTile(
                    title: Text(s.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Kontak: ${s.kontak ?? '-'} • Alamat: ${s.alamat ?? '-'}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.primaryTeal, size: 18),
                          onPressed: () => _showSupplierDialog(supplier: s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.dangerRed, size: 18),
                          onPressed: () => _confirmDeleteSupplier(s.id!, s.nama),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
