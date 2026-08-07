import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../providers/obat_provider.dart';
import '../../providers/transaksi_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/medical_card.dart';

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
      Provider.of<ObatProvider>(context, listen: false).fetchObat();
      Provider.of<TransaksiProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Consumer3<AppProvider, ObatProvider, TransaksiProvider>(
      builder: (context, appProv, obatProv, txProv, _) {
        final totalObatCount = obatProv.obatList.length;
        final lowStockCount = obatProv.lowStockList.length;
        final todayRevenue = txProv.todayRevenue;
        final todayTxCount = txProv.todayTxCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Eksekutif Apotek',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monitoring penjualan harian, stok obat, dan koneksi spreadsheet',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryTeal),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Spreadsheet Status Banner
              MedicalCard(
                padding: const EdgeInsets.all(16),
                backgroundColor: appProv.connectedSpreadsheetPath != null
                    ? AppTheme.primaryTealLight.withOpacity(0.5)
                    : AppTheme.warningBg.withOpacity(0.6),
                border: BorderSide(
                  color: appProv.connectedSpreadsheetPath != null ? AppTheme.primaryTeal : AppTheme.warningOrange,
                ),
                child: Row(
                  children: [
                    Icon(
                      appProv.connectedSpreadsheetPath != null ? Icons.table_chart : Icons.table_chart_outlined,
                      color: appProv.connectedSpreadsheetPath != null ? AppTheme.primaryTeal : AppTheme.warningOrange,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appProv.connectedSpreadsheetPath != null
                                ? 'Spreadsheet Terhubung (.xlsx)'
                                : 'Spreadsheet Belum Terhubung',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          Text(
                            appProv.connectedSpreadsheetPath ?? 'Hubungkan file Excel untuk sinkronisasi otomatis data obat.',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appProv.connectedSpreadsheetPath != null ? AppTheme.primaryTeal : AppTheme.warningOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => appProv.setNavIndex(6), // Navigate to Backup & Excel
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: Text(appProv.connectedSpreadsheetPath != null ? 'Kelola Spreadsheet' : 'Hubungkan Excel'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Metric StatCards Grid
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    title: 'Penjualan Hari Ini',
                    value: currencyFormatter.format(todayRevenue),
                    subtitle: '$todayTxCount Transaksi Kasir',
                    icon: Icons.payments_outlined,
                    iconBgColor: AppTheme.primaryTealLight,
                    iconColor: AppTheme.primaryTeal,
                  ),
                  StatCard(
                    title: 'Transaksi Kasir',
                    value: '$todayTxCount',
                    subtitle: 'Total invoice hari ini',
                    icon: Icons.receipt_long_outlined,
                    iconBgColor: AppTheme.emeraldLight,
                    iconColor: AppTheme.emeraldGreen,
                  ),
                  StatCard(
                    title: 'Total Katalog Obat',
                    value: '$totalObatCount Item',
                    subtitle: 'SKU Aktif di Sistem',
                    icon: Icons.medication_outlined,
                    iconBgColor: const Color(0xFFE0F2FE),
                    iconColor: AppTheme.cyanAccent,
                  ),
                  StatCard(
                    title: 'Peringatan Stok Menipis',
                    value: '$lowStockCount Item',
                    subtitle: lowStockCount > 0 ? 'Perlu Restok Segera!' : 'Stok Aman',
                    icon: Icons.warning_amber_rounded,
                    iconBgColor: lowStockCount > 0 ? AppTheme.warningBg : AppTheme.successBg,
                    iconColor: lowStockCount > 0 ? AppTheme.warningOrange : AppTheme.successGreen,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Main Section: Left = Low Stock Alert, Right = Quick Actions & Recent Sales
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Low Stock List
                  Expanded(
                    flex: 6,
                    child: MedicalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, color: AppTheme.primaryTeal),
                                  SizedBox(width: 8),
                                  Text(
                                    'Peringatan Stok Obat Menipis',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                ],
                              ),
                              OutlinedButton(
                                onPressed: () => appProv.setNavIndex(3), // Mutasi Stok
                                child: const Text('Mutasi Stok'),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (obatProv.lowStockList.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              alignment: Alignment.center,
                              child: Column(
                                children: const [
                                  Icon(Icons.check_circle_outline, size: 48, color: AppTheme.emeraldGreen),
                                  SizedBox(height: 12),
                                  Text('Semua stok obat dalam kondisi aman!', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: obatProv.lowStockList.length,
                              separatorBuilder: (_, __) => const Divider(height: 12),
                              itemBuilder: (context, index) {
                                final obat = obatProv.lowStockList[index];
                                return Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: obat.isHabis ? AppTheme.dangerBg : AppTheme.warningBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        obat.isHabis ? Icons.error_outline : Icons.warning_amber_rounded,
                                        color: obat.isHabis ? AppTheme.dangerRed : AppTheme.warningOrange,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            obat.nama,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            'Kode: ${obat.kodeObat} • Kategori: ${obat.namaKategori ?? '-'}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${obat.stokTersedia} unit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: obat.isHabis ? AppTheme.dangerRed : AppTheme.warningOrange,
                                          ),
                                        ),
                                        Text(
                                          'Min: ${obat.stokMinimal}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
                  ),

                  const SizedBox(width: 24),

                  // Quick Action Buttons Panel
                  Expanded(
                    flex: 4,
                    child: MedicalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.flash_on, color: AppTheme.primaryTeal),
                              SizedBox(width: 8),
                              Text(
                                'Akses Cepat',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Column(
                            children: [
                              _buildQuickActionButton(
                                context,
                                label: 'Buka Kasir Penjualan',
                                icon: Icons.point_of_sale,
                                color: AppTheme.primaryTeal,
                                onTap: () => appProv.setNavIndex(1),
                              ),
                              const SizedBox(height: 12),
                              _buildQuickActionButton(
                                context,
                                label: 'Tambah Obat Baru',
                                icon: Icons.add_box_outlined,
                                color: AppTheme.emeraldGreen,
                                onTap: () => appProv.setNavIndex(2),
                              ),
                              const SizedBox(height: 12),
                              _buildQuickActionButton(
                                context,
                                label: 'Laporan Penjualan',
                                icon: Icons.analytics_outlined,
                                color: AppTheme.cyanAccent,
                                onTap: () => appProv.setNavIndex(5),
                              ),
                              const SizedBox(height: 12),
                              _buildQuickActionButton(
                                context,
                                label: 'Backup Database (.db)',
                                icon: Icons.sd_storage_outlined,
                                color: const Color(0xFF6366F1),
                                onTap: () => appProv.setNavIndex(6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.bgLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
