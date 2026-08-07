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

      final stokProv = Provider.of<StokProvider>(context, listen: false);
      final obatProv = Provider.of<ObatProvider>(context, listen: false);

      try {
        final success = await stokProv.updateStok(
          obatId: _selectedObatId!,
          jenis: _selectedJenis,
          jumlah: int.parse(_jumlahController.text.trim()),
          catatan: _catatanController.text.trim().isNotEmpty ? _catatanController.text.trim() : null,
        );

        if (success && mounted) {
          _jumlahController.clear();
          _catatanController.clear();
          await obatProv.fetchObat();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mutasi stok berhasil dicatat!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Form Input Mutasi Stok
          Expanded(
            flex: 4,
            child: MedicalCard(
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
                    const Divider(height: 24),
                    Consumer<ObatProvider>(
                      builder: (context, obatProv, _) {
                        return DropdownButtonFormField<int?>(
                          value: _selectedObatId,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Stok Masuk (+)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            value: 'masuk',
                            groupValue: _selectedJenis,
                            activeColor: AppTheme.emeraldGreen,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _selectedJenis = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Stok Keluar (-)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            value: 'keluar',
                            groupValue: _selectedJenis,
                            activeColor: AppTheme.dangerRed,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _selectedJenis = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _catatanController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Catatan / Alasan Mutasi'),
                    ),
                    const SizedBox(height: 24),
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
            ),
          ),

          const SizedBox(width: 24),

          // Right: Riwayat Mutasi Table
          Expanded(
            flex: 6,
            child: MedicalCard(
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
                  const Divider(height: 24),
                  Expanded(
                    child: Consumer<StokProvider>(
                      builder: (context, stokProv, _) {
                        if (stokProv.isLoading) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
                        }

                        if (stokProv.mutasiList.isEmpty) {
                          return const Center(child: Text('Belum ada riwayat mutasi stok'));
                        }

                        return ListView.separated(
                          itemCount: stokProv.mutasiList.length,
                          separatorBuilder: (_, __) => const Divider(height: 12),
                          itemBuilder: (context, index) {
                            final mutasi = stokProv.mutasiList[index];
                            final isMasuk = mutasi.jenis == 'masuk';
                            final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(mutasi.tanggal));

                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isMasuk ? AppTheme.emeraldLight : AppTheme.dangerBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isMasuk ? AppTheme.emeraldGreen : AppTheme.dangerRed,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
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
                                        fontSize: 14,
                                        color: isMasuk ? AppTheme.emeraldGreen : AppTheme.dangerRed,
                                      ),
                                    ),
                                    Text(
                                      dateFormatted,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
