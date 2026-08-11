import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firdan_farma_windows/application/providers/laporan_provider.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/core/utils/responsive_helper.dart';
import 'package:firdan_farma_windows/shared/widgets/app_page.dart';
import 'package:firdan_farma_windows/shared/widgets/medical_card.dart';
import 'package:firdan_farma_windows/shared/widgets/stat_card.dart';

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
      initialDateRange: DateTimeRange(
        start: lapProv.dariTanggal,
        end: lapProv.sampaiTanggal,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppTheme.primaryTeal,
              onPrimary: AppTheme.isDark ? Colors.black : Colors.white,
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
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Consumer<LaporanProvider>(
      builder: (context, lapProv, _) {
        final ringkasan = lapProv.ringkasan;
        final dariStr = DateFormat('dd MMM yyyy').format(lapProv.dariTanggal);
        final sampaiStr = DateFormat(
          'dd MMM yyyy',
        ).format(lapProv.sampaiTanggal);

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = ResponsiveHelper.getStatCardCrossAxisCount(
              width,
            );

            return AppPage(
              title: 'Laporan Penjualan',
              subtitle:
                  'Ringkasan omset, transaksi, keuntungan, dan obat terlaris',
              icon: Icons.analytics_outlined,
              actions: [
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: Icon(Icons.date_range, color: AppTheme.primaryTeal),
                  label: Text('$dariStr - $sampaiStr'),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lapProv.isLoading)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.primaryTeal,
                        backgroundColor: AppTheme.primaryTealLight,
                      ),
                    ),
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: crossAxisCount == 1
                        ? 3.0
                        : (crossAxisCount == 2 ? 2.7 : 2.25),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(
                        title: 'Total Penjualan',
                        value: currencyFormatter.format(
                          ringkasan?.totalPenjualan ?? 0,
                        ),
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
                        value: '${ringkasan?.totalItemTerjual ?? 0} unit',
                        subtitle: 'Total obat keluar via kasir',
                        icon: Icons.shopping_bag_outlined,
                        iconBgColor: const Color(0xFFE0F2FE),
                        iconColor: AppTheme.cyanAccent,
                      ),
                      StatCard(
                        title: 'Est. Keuntungan',
                        value: currencyFormatter.format(
                          ringkasan?.totalEstKeuntungan ?? 0,
                        ),
                        subtitle: 'Harga jual dikurangi harga beli',
                        icon: Icons.account_balance_wallet_outlined,
                        iconBgColor: AppTheme.indigoLight,
                        iconColor: AppTheme.indigo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  MedicalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(
                          icon: Icons.star_outline,
                          title: 'Obat Terlaris',
                          subtitle:
                              'Lima item dengan penjualan tertinggi pada periode ini',
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        if (lapProv.obatTerlaris.isEmpty)
                          const EmptyState(
                            icon: Icons.bar_chart_outlined,
                            title: 'Belum ada penjualan',
                            subtitle:
                                'Data terlaris akan tampil setelah transaksi tersimpan.',
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lapProv.obatTerlaris.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final item = lapProv.obatTerlaris[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: index == 0
                                            ? AppTheme.warningOrange
                                            : AppTheme.primaryTealLight,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMd,
                                        ),
                                      ),
                                      child: Text(
                                        '#${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: index == 0
                                              ? Colors.white
                                              : AppTheme.primaryTeal,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.namaObat,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Kode: ${item.kodeObat}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${item.totalTerjual} unit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: AppTheme.primaryTeal,
                                          ),
                                        ),
                                        Text(
                                          currencyFormatter.format(
                                            item.totalSubtotal,
                                          ),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
