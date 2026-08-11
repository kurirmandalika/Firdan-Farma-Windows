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

class _StokScreenState extends State<StokScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  int? _selectedObatId;
  String _selectedJenis = 'masuk';

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

      final stokProv = Provider.of<StokProvider>(context, listen: false);
      final obatProv = Provider.of<ObatProvider>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);

      try {
        final success = await stokProv.updateStok(
          obatId: _selectedObatId!,
          jenis: _selectedJenis,
          jumlah: jumlah,
          catatan: _catatanController.text.trim().isNotEmpty
              ? _catatanController.text.trim()
              : null,
        );

        if (success && mounted) {
          _jumlahController.clear();
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
            title: 'Mutasi Stok',
            subtitle:
                'Catat stok masuk dan keluar dengan riwayat yang mudah diaudit',
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

  Widget _buildFormInput(BuildContext context) {
    return MedicalCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Input Mutasi',
              subtitle: 'Pilih obat, jenis mutasi, lalu simpan perubahan stok',
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
                  onChanged: (val) => setState(() => _selectedObatId = val),
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment<String>(
                    value: 'masuk',
                    label: Text('Masuk'),
                    icon: Icon(Icons.south_west, color: AppTheme.emeraldGreen),
                  ),
                  ButtonSegment<String>(
                    value: 'keluar',
                    label: Text('Keluar'),
                    icon: Icon(Icons.north_east, color: AppTheme.dangerRed),
                  ),
                ],
                selected: {_selectedJenis},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedJenis = newSelection.first;
                  });
                },
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
            TextFormField(
              controller: _catatanController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan / alasan mutasi',
              ),
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
            title: 'Riwayat Mutasi',
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
                                        mutasi.catatan ??
                                            (isMasuk
                                                ? 'Stok masuk'
                                                : 'Stok keluar'),
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
                                      '${isMasuk ? '+' : '-'}${mutasi.jumlah} unit',
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
