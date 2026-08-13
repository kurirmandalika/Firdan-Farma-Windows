import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firdan_farma_windows/application/providers/app_provider.dart';
import 'package:firdan_farma_windows/application/providers/obat_provider.dart';
import 'package:firdan_farma_windows/application/providers/pembelian_provider.dart';
import 'package:firdan_farma_windows/application/providers/transaksi_provider.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/core/utils/responsive_helper.dart';
import 'package:firdan_farma_windows/shared/widgets/app_page.dart';
import 'package:firdan_farma_windows/shared/widgets/medical_card.dart';
import 'package:firdan_farma_windows/shared/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObatProvider>(context, listen: false).fetchDashboardSummary();
      Provider.of<TransaksiProvider>(context, listen: false).fetchSummary();
      Provider.of<PembelianProvider>(context, listen: false).fetchSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Consumer4<
      AppProvider,
      ObatProvider,
      TransaksiProvider,
      PembelianProvider
    >(
      builder: (context, appProv, obatProv, txProv, beliProv, _) {
        final totalObatCount = obatProv.totalActiveCount;
        final lowStockCount = obatProv.lowStockList.length;
        final todayRevenue = txProv.todayRevenue;
        final todayGrossProfit = txProv.todayGrossProfit;
        final todayTxCount = txProv.todayTxCount;
        final todayPurchase = beliProv.todayPurchaseTotal;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isCompact = width < 900;
            final crossAxisCount = ResponsiveHelper.getStatCardCrossAxisCount(
              width,
            );

            return AppPage(
              title: 'Ringkasan Operasional',
              subtitle:
                  'Penjualan hari ini, kondisi stok, dan kesiapan data apotek',
              icon: Icons.dashboard_outlined,
              actions: [_DatePill(date: DateTime.now())],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (totalObatCount == 0) ...[
                    _FirstMedicinePrompt(onAdd: () => appProv.setNavIndex(2)),
                    const SizedBox(height: 18),
                  ],
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
                        title: 'Penjualan Hari Ini',
                        value: currencyFormatter.format(todayRevenue),
                        subtitle: '$todayTxCount transaksi kasir',
                        icon: Icons.payments_outlined,
                        iconBgColor: AppTheme.primaryTealLight,
                        iconColor: AppTheme.primaryTeal,
                      ),
                      StatCard(
                        title: 'Laba Kotor Hari Ini',
                        value: currencyFormatter.format(todayGrossProfit),
                        subtitle: 'Berdasarkan harga modal snapshot',
                        icon: Icons.account_balance_wallet_outlined,
                        iconBgColor: AppTheme.emeraldLight,
                        iconColor: AppTheme.emeraldGreen,
                      ),
                      StatCard(
                        title: 'Transaksi Kasir',
                        value: '$todayTxCount',
                        subtitle: 'Invoice tersimpan hari ini',
                        icon: Icons.receipt_long_outlined,
                        iconBgColor: AppTheme.primaryTealLight,
                        iconColor: AppTheme.primaryTeal,
                      ),
                      StatCard(
                        title: 'Katalog Obat',
                        value: '$totalObatCount item',
                        subtitle: 'Produk aktif sesuai filter',
                        icon: Icons.medication_outlined,
                        iconBgColor: AppTheme.indigoLight,
                        iconColor: AppTheme.indigo,
                      ),
                      StatCard(
                        title: 'Stok Menipis',
                        value: '$lowStockCount item',
                        subtitle: lowStockCount > 0
                            ? 'Perlu restok segera'
                            : 'Semua aman',
                        icon: Icons.warning_amber_rounded,
                        iconBgColor: lowStockCount > 0
                            ? AppTheme.warningBg
                            : AppTheme.successBg,
                        iconColor: lowStockCount > 0
                            ? AppTheme.warningOrange
                            : AppTheme.successGreen,
                      ),
                      StatCard(
                        title: 'Pembelian Hari Ini',
                        value: currencyFormatter.format(todayPurchase),
                        subtitle: 'Obat masuk dari supplier',
                        icon: Icons.shopping_bag_outlined,
                        iconBgColor: AppTheme.warningBg,
                        iconColor: AppTheme.warningOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (isCompact)
                    Column(
                      children: [
                        _buildLowStockPanel(context, appProv, obatProv),
                        const SizedBox(height: 18),
                        _buildQuickActionPanel(context, appProv),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildLowStockPanel(
                            context,
                            appProv,
                            obatProv,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 4,
                          child: _buildQuickActionPanel(context, appProv),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLowStockPanel(
    BuildContext context,
    AppProvider appProv,
    ObatProvider obatProv,
  ) {
    final items = obatProv.lowStockList.take(8).toList();

    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.inventory_2_outlined,
            title: 'Pantauan Stok Menipis',
            subtitle: 'Item aktif yang sudah mencapai batas stok minimal',
            trailing: OutlinedButton.icon(
              onPressed: () => appProv.setNavIndex(4),
              icon: const Icon(Icons.swap_vert, size: 16),
              label: const Text('Mutasi'),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          if (items.isEmpty)
            EmptyState(
              icon: obatProv.totalActiveCount == 0
                  ? Icons.medication_outlined
                  : Icons.check_circle_outline,
              title: obatProv.totalActiveCount == 0
                  ? 'Belum ada obat'
                  : 'Stok aman',
              subtitle: obatProv.totalActiveCount == 0
                  ? 'Tambahkan obat pertama untuk mulai mencatat stok dan penjualan.'
                  : 'Tidak ada obat aktif di bawah batas minimal.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final obat = items[index];
                final color = obat.isHabis
                    ? AppTheme.dangerRed
                    : AppTheme.warningOrange;
                final bgColor = obat.isHabis
                    ? AppTheme.dangerBg
                    : AppTheme.warningBg;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        child: Icon(
                          obat.isHabis
                              ? Icons.error_outline
                              : Icons.warning_amber_rounded,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              obat.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${obat.kodeObat} | ${obat.namaKategori ?? 'Tanpa kategori'}',
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
                            '${obat.stokTersedia} unit',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          Text(
                            'Min ${obat.stokMinimal}',
                            style: TextStyle(
                              fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildQuickActionPanel(BuildContext context, AppProvider appProv) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            icon: Icons.flash_on,
            title: 'Akses Cepat',
            subtitle: 'Pindah ke alur kerja yang paling sering dipakai',
          ),
          const SizedBox(height: 16),
          const Divider(),
          _QuickActionTile(
            label: 'Buka Kasir Penjualan',
            subtitle: 'Tambah item dan proses pembayaran',
            icon: Icons.point_of_sale,
            color: AppTheme.primaryTeal,
            onTap: () => appProv.setNavIndex(1),
          ),
          _QuickActionTile(
            label: 'Kelola Katalog Obat',
            subtitle: 'Tambah atau koreksi data produk',
            icon: Icons.add_box_outlined,
            color: AppTheme.emeraldGreen,
            onTap: () => appProv.setNavIndex(2),
          ),
          _QuickActionTile(
            label: 'Catat Pembelian',
            subtitle: 'Stok datang dari supplier',
            icon: Icons.shopping_bag_outlined,
            color: AppTheme.warningOrange,
            onTap: () => appProv.setNavIndex(3),
          ),
          _QuickActionTile(
            label: 'Lihat Laporan',
            subtitle: 'Pantau omset dan item terlaris',
            icon: Icons.analytics_outlined,
            color: AppTheme.cyanAccent,
            onTap: () => appProv.setNavIndex(6),
          ),
          _QuickActionTile(
            label: 'Backup dan Excel',
            subtitle: 'Ekspor, impor, atau pulihkan data',
            icon: Icons.sd_storage_outlined,
            color: AppTheme.indigo,
            onTap: () => appProv.setNavIndex(7),
          ),
        ],
      ),
    );
  }
}

class _FirstMedicinePrompt extends StatelessWidget {
  final VoidCallback onAdd;

  const _FirstMedicinePrompt({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      backgroundColor: AppTheme.primaryTealLight.withValues(alpha: 0.55),
      border: BorderSide(color: AppTheme.primaryTeal.withValues(alpha: 0.25)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final message = Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppTheme.primaryTeal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belum ada data obat',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tambahkan obat pertama untuk mulai menggunakan Apotek Firdan Farma.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final action = ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah Obat'),
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [message, const SizedBox(height: 14), action],
            );
          }
          return Row(
            children: [
              Expanded(child: message),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final DateTime date;

  const _DatePill({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 15, color: AppTheme.primaryTeal),
          const SizedBox(width: 8),
          Text(
            DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
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
                Icon(Icons.chevron_right, size: 20, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
