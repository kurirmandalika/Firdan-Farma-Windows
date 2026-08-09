import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/laporan_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/medical_card.dart';
import '../../widgets/stat_card.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LaporanProvider>(context, listen: false).fetchLaporan();
    });
  }

  Future<void> _pickDateRange() async {
    final lapProv = Provider.of<LaporanProvider>(context, listen: false);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: lapProv.dariTanggal, end: lapProv.sampaiTanggal),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryTeal,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      lapProv.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Consumer<LaporanProvider>(
      builder: (context, lapProv, _) {
        final ringkasan = lapProv.ringkasan;
        final dariStr = DateFormat('dd MMM yyyy').format(lapProv.dariTanggal);
        final sampaiStr = DateFormat('dd MMM yyyy').format(lapProv.sampaiTanggal);

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = ResponsiveHelper.getStatCardCrossAxisCount(width);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Laporan & Analitik Penjualan',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ringkasan pendapatan, transaksi, est. keuntungan, dan obat terlaris',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range, color: AppTheme.primaryTeal),
                        label: Text('Periode: $dariStr - $sampaiStr'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Stat Cards Grid
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: crossAxisCount == 1 ? 3.0 : (crossAxisCount == 2 ? 2.6 : 2.2),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(
                        title: 'Total Penjualan',
                        value: currencyFormatter.format(ringkasan?.totalPenjualan ?? 0),
                        subtitle: 'Omset kotor periode ini',
                        icon: Icons.trending_up,
                        iconBgColor: AppTheme.primaryTealLight,
                        iconColor: AppTheme.primaryTeal,
                      ),
                      StatCard(
                        title: 'Total Transaksi',
                        value: '${ringkasan?.totalTransaksi ?? 0}',
                        subtitle: 'Struk penjualan kasir',
                        icon: Icons.receipt_long,
                        iconBgColor: AppTheme.emeraldLight,
                        iconColor: AppTheme.emeraldGreen,
                      ),
                      StatCard(
                        title: 'Item Terjual',
                        value: '${ringkasan?.totalItemTerjual ?? 0} Unit',
                        subtitle: 'Total obat terjual',
                        icon: Icons.shopping_bag_outlined,
                        iconBgColor: const Color(0xFFE0F2FE),
                        iconColor: AppTheme.cyanAccent,
                      ),
                      StatCard(
                        title: 'Est. Keuntungan Bersih',
                        value: currencyFormatter.format(ringkasan?.totalEstKeuntungan ?? 0),
                        subtitle: 'Total Harga Jual - Harga Beli',
                        icon: Icons.account_balance_wallet_outlined,
                        iconBgColor: const Color(0xFFEEF2FF),
                        iconColor: const Color(0xFF6366F1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Obat Terlaris Table
                  MedicalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.star_outline, color: AppTheme.primaryTeal),
                            SizedBox(width: 8),
                            Text(
                              'Obat Terlaris (Top 5 Best Seller)',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (lapProv.isLoading)
                          const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
                        else if (lapProv.obatTerlaris.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(28),
                            child: Center(child: Text('Belum ada data penjualan pada periode ini')),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lapProv.obatTerlaris.length,
                            separatorBuilder: (context, index) => const Divider(height: 10),
                            itemBuilder: (context, index) {
                              final item = lapProv.obatTerlaris[index];
                              return Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: index == 0 ? AppTheme.warningOrange : AppTheme.primaryTealLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '#${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: index == 0 ? Colors.white : AppTheme.primaryTeal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.namaObat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('Kode Obat: ${item.kodeObat}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${item.totalTerjual} Unit Terjual',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal),
                                      ),
                                      Text(
                                        'Total Omset: ${currencyFormatter.format(item.totalSubtotal)}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
