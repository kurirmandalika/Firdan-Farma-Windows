import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firdan_farma_windows/application/providers/obat_provider.dart';
import 'package:firdan_farma_windows/application/providers/stok_provider.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/shared/widgets/app_page.dart';
import 'package:firdan_farma_windows/shared/widgets/medical_card.dart';

class StokScreen extends StatefulWidget {
  const StokScreen({super.key});

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StockTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StockTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? color : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? color : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StokScreenState extends State<StokScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _hargaBeliController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  int? _selectedObatId;
  String _selectedJenis = 'masuk';
  String _selectedAlasanKeluar = 'PENYESUAIAN';

  static const _alasanKeluar = {
    'PENYESUAIAN': 'Penyesuaian',
    'RUSAK': 'Rusak',
    'KEDALUWARSA': 'Kedaluwarsa',
    'RETUR_SUPPLIER': 'Retur Supplier',
    'LAINNYA': 'Lainnya',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObatProvider>(context, listen: false).fetchObat();
      Provider.of<StokProvider>(context, listen: false).fetchMutasi();
    });
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _hargaBeliController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submitMutasi() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedObatId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih obat terlebih dahulu!')),
        );
        return;
      }

      final jumlah = int.tryParse(_jumlahController.text.trim());
      if (jumlah == null || jumlah <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jumlah unit harus berupa angka positif!'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
        return;
      }

      final hargaBeli = _selectedJenis == 'masuk'
          ? double.tryParse(_hargaBeliController.text.trim())
          : null;
      if (_selectedJenis == 'masuk' && (hargaBeli == null || hargaBeli < 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harga beli stok masuk wajib berupa angka valid.'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
        return;
      }

      final stokProv = Provider.of<StokProvider>(context, listen: false);
      final obatProv = Provider.of<ObatProvider>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);

      try {
        final success = await stokProv.updateStok(
          obatId: _selectedObatId!,
          jenis: _selectedJenis,
          jumlah: jumlah,
          alasan: _selectedJenis == 'keluar' ? _selectedAlasanKeluar : 'RESTOK',
          hargaBeli: hargaBeli,
          catatan: _catatanController.text.trim().isNotEmpty
              ? _catatanController.text.trim()
              : null,
        );

        if (success && mounted) {
          _jumlahController.clear();
          _hargaBeliController.clear();
          _catatanController.clear();
          await obatProv.fetchObat();

          messenger.showSnackBar(
            SnackBar(
              content: Text('Mutasi stok berhasil dicatat!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPageHeader(
            title: 'Stok',
            subtitle: 'Catat stok masuk atau keluar non-penjualan dengan aman',
            icon: Icons.swap_vert,
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
                              Tab(icon: Icon(Icons.edit_note), text: 'Input'),
                              Tab(icon: Icon(Icons.history), text: 'Riwayat'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TabBarView(
                            children: [
                              SingleChildScrollView(
                                child: _buildFormInput(context),
                              ),
                              _buildMutasiHistory(context),
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
                    SizedBox(
                      width: constraints.maxWidth < 1200 ? 380 : 430,
                      child: SingleChildScrollView(
                        child: _buildFormInput(context),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(child: _buildMutasiHistory(context)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _selectedUnit(BuildContext context) {
    final medicines = Provider.of<ObatProvider>(
      context,
      listen: false,
    ).obatList;
    for (final medicine in medicines) {
      if (medicine.id == _selectedObatId) return medicine.satuan;
    }
    return 'unit';
  }

  Widget _buildFormInput(BuildContext context) {
    return MedicalCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Perubahan Stok',
              subtitle: 'Penjualan hanya dicatat melalui menu Kasir',
            ),
            const SizedBox(height: 16),
            const Divider(),
            Consumer<ObatProvider>(
              builder: (context, obatProv, _) {
                final validValue =
                    obatProv.obatList.any((o) => o.id == _selectedObatId)
                    ? _selectedObatId
                    : null;

                return DropdownButtonFormField<int?>(
                  initialValue: validValue,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Pilih Obat *'),
                  items: obatProv.obatList.map((o) {
                    return DropdownMenuItem<int?>(
                      value: o.id,
                      child: Text(
                        '${o.nama} (stok ${o.stokTersedia})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedObatId = val);
                    for (final medicine in obatProv.obatList) {
                      if (medicine.id == val) {
                        _hargaBeliController.text = medicine.hargaBeli
                            .toStringAsFixed(0);
                        break;
                      }
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.bgSubtle,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StockTypeButton(
                        label: 'Stok Masuk',
                        icon: Icons.south_west,
                        color: AppTheme.emeraldGreen,
                        selected: _selectedJenis == 'masuk',
                        onTap: () => setState(() => _selectedJenis = 'masuk'),
                      ),
                    ),
                    Expanded(
                      child: _StockTypeButton(
                        label: 'Stok Keluar',
                        icon: Icons.north_east,
                        color: AppTheme.dangerRed,
                        selected: _selectedJenis == 'keluar',
                        onTap: () => setState(() => _selectedJenis = 'keluar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah Unit *',
                prefixIcon: Icon(Icons.numbers, color: AppTheme.primaryTeal),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final num = int.tryParse(v);
                if (num == null || num <= 0) return 'Jumlah harus lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 14),
            if (_selectedJenis == 'masuk') ...[
              TextFormField(
                controller: _hargaBeliController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga Beli per ${_selectedUnit(context)} *',
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                validator: (value) {
                  if (_selectedJenis != 'masuk') return null;
                  final price = double.tryParse(value?.trim() ?? '');
                  if (price == null || price < 0) {
                    return 'Harga beli tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ] else ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedAlasanKeluar,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Alasan Stok Keluar *',
                ),
                items: _alasanKeluar.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedAlasanKeluar = value);
                  }
                },
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _catatanController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan / alasan mutasi *',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Alasan wajib diisi' : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedJenis == 'masuk'
                      ? AppTheme.primaryTeal
                      : AppTheme.dangerRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submitMutasi,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  'Simpan Stok ${_selectedJenis == 'masuk' ? 'Masuk' : 'Keluar'}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutasiHistory(BuildContext context) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            icon: Icons.history,
            title: 'Riwayat Stok',
            subtitle: 'Catatan stok terbaru ditampilkan dari yang paling baru',
          ),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: Consumer<StokProvider>(
              builder: (context, stokProv, _) {
                if (stokProv.isLoading && stokProv.mutasiList.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                  );
                }

                if (stokProv.mutasiList.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Belum ada mutasi',
                    subtitle:
                        'Riwayat stok akan tampil setelah ada stok masuk atau keluar.',
                  );
                }

                return Column(
                  children: [
                    if (stokProv.isLoading)
                      LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.primaryTeal,
                        backgroundColor: AppTheme.primaryTealLight,
                      ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: stokProv.mutasiList.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final mutasi = stokProv.mutasiList[index];
                          final isMasuk = mutasi.jenis == 'masuk';
                          final dateFormatted = DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(DateTime.parse(mutasi.tanggal));

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isMasuk
                                        ? AppTheme.emeraldLight
                                        : AppTheme.dangerBg,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                  ),
                                  child: Icon(
                                    isMasuk
                                        ? Icons.south_west
                                        : Icons.north_east,
                                    color: isMasuk
                                        ? AppTheme.emeraldGreen
                                        : AppTheme.dangerRed,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mutasi.namaObat ??
                                            'Obat ID ${mutasi.obatId}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${(mutasi.alasan ?? mutasi.tipeMutasi).replaceAll('_', ' ')}'
                                        '${mutasi.stokSebelum != null && mutasi.stokSesudah != null ? ' | ${mutasi.stokSebelum} -> ${mutasi.stokSesudah}' : ''}'
                                        '${mutasi.catatan != null ? ' | ${mutasi.catatan}' : ''}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${mutasi.qtySigned} ${mutasi.satuan ?? 'unit'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: isMasuk
                                            ? AppTheme.emeraldGreen
                                            : AppTheme.dangerRed,
                                      ),
                                    ),
                                    Text(
                                      dateFormatted,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
