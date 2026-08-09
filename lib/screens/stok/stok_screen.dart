import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/obat_provider.dart';
import '../../providers/stok_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_card.dart';

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
          const SnackBar(content: Text('Jumlah unit harus berupa angka positif!'), backgroundColor: AppTheme.dangerRed),
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
          catatan: _catatanController.text.trim().isNotEmpty ? _catatanController.text.trim() : null,
        );

        if (success && mounted) {
          _jumlahController.clear();
          _catatanController.clear();
          await obatProv.fetchObat();

          messenger.showSnackBar(
            const SnackBar(
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: isCompact
              ? Column(
                  children: [
                    _buildFormInput(context),
                    const SizedBox(height: 20),
                    _buildMutasiHistory(context),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildFormInput(context),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 6,
                      child: _buildMutasiHistory(context),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFormInput(BuildContext context) {
    return MedicalCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.swap_vert, color: AppTheme.primaryTeal),
                SizedBox(width: 8),
                Text(
                  'Input Mutasi Stok',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const Divider(height: 20),
            Consumer<ObatProvider>(
              builder: (context, obatProv, _) {
                final validValue = obatProv.obatList.any((o) => o.id == _selectedObatId) ? _selectedObatId : null;

                return DropdownButtonFormField<int?>(
                  initialValue: validValue,
                  decoration: const InputDecoration(labelText: 'Pilih Obat *'),
                  items: obatProv.obatList.map((o) {
                    return DropdownMenuItem<int?>(
                      value: o.id,
                      child: Text('${o.nama} (Stok: ${o.stokTersedia})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedObatId = val),
                );
              },
            ),
            const SizedBox(height: 14),
            // Modern SegmentedButton instead of deprecated RadioListTile
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'masuk',
                    label: Text('Stok Masuk (+)'),
                    icon: Icon(Icons.arrow_downward, color: AppTheme.emeraldGreen),
                  ),
                  ButtonSegment<String>(
                    value: 'keluar',
                    label: Text('Stok Keluar (-)'),
                    icon: Icon(Icons.arrow_upward, color: AppTheme.dangerRed),
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
              decoration: const InputDecoration(labelText: 'Jumlah Unit *'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                final num = int.tryParse(v);
                if (num == null || num <= 0) return 'Jumlah harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _catatanController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan / Alasan Mutasi'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedJenis == 'masuk' ? AppTheme.primaryTeal : AppTheme.dangerRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submitMutasi,
                icon: const Icon(Icons.save),
                label: Text('Simpan Mutasi ${_selectedJenis.toUpperCase()}'),
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
          const Row(
            children: [
              Icon(Icons.history, color: AppTheme.primaryTeal),
              SizedBox(width: 8),
              Text(
                'Riwayat Mutasi Stok',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const Divider(height: 20),
          Consumer<StokProvider>(
            builder: (context, stokProv, _) {
              if (stokProv.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
              }

              if (stokProv.mutasiList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Belum ada riwayat mutasi stok')),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stokProv.mutasiList.length,
                separatorBuilder: (context, index) => const Divider(height: 10),
                itemBuilder: (context, index) {
                  final mutasi = stokProv.mutasiList[index];
                  final isMasuk = mutasi.jenis == 'masuk';
                  final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(mutasi.tanggal));

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMasuk ? AppTheme.emeraldLight : AppTheme.dangerBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isMasuk ? AppTheme.emeraldGreen : AppTheme.dangerRed,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mutasi.namaObat ?? 'Obat ID ${mutasi.obatId}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              mutasi.catatan ?? (isMasuk ? 'Stok Masuk' : 'Stok Keluar'),
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isMasuk ? '+' : '-'}${mutasi.jumlah} unit',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isMasuk ? AppTheme.emeraldGreen : AppTheme.dangerRed,
                            ),
                          ),
                          Text(
                            dateFormatted,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
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
