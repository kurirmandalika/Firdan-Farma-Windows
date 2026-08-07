import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../providers/pin_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'transaksi/transaksi_screen.dart';
import 'obat/obat_list_screen.dart';
import 'stok/stok_screen.dart';
import 'kategori_supplier/kategori_supplier_screen.dart';
import 'laporan/laporan_screen.dart';
import 'backup_excel/backup_excel_screen.dart';

class MainDesktopShell extends StatelessWidget {
  const MainDesktopShell({super.key});

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const TransaksiScreen();
      case 2:
        return const ObatListScreen();
      case 3:
        return const StokScreen();
      case 4:
        return const KategoriSupplierScreen();
      case 5:
        return const LaporanScreen();
      case 6:
        return const BackupExcelScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, PinProvider>(
      builder: (context, appProv, pinProv, _) {
        return Scaffold(
          body: Row(
            children: [
              // Left Desktop Navigation Sidebar
              Container(
                width: 250,
                color: AppTheme.sidebarBackground,
                child: Column(
                  children: [
                    // Brand Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_pharmacy,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'FIRDAN FARMA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Apotek Windows',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFF334155), height: 1),
                    const SizedBox(height: 16),

                    // Nav Menu Items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _buildNavItem(context, appProv, index: 0, title: 'Dashboard', icon: Icons.dashboard_outlined),
                          _buildNavItem(context, appProv, index: 1, title: 'Kasir Penjualan', icon: Icons.point_of_sale),
                          _buildNavItem(context, appProv, index: 2, title: 'Katalog Obat', icon: Icons.medication_outlined),
                          _buildNavItem(context, appProv, index: 3, title: 'Mutasi Stok', icon: Icons.swap_vert),
                          _buildNavItem(context, appProv, index: 4, title: 'Kategori & Supplier', icon: Icons.category_outlined),
                          _buildNavItem(context, appProv, index: 5, title: 'Laporan & Analitik', icon: Icons.analytics_outlined),
                          _buildNavItem(context, appProv, index: 6, title: 'Backup & Excel', icon: Icons.table_chart_outlined),
                        ],
                      ),
                    ),

                    // User Info & PIN Lock Button Footer
                    const Divider(color: Color(0xFF334155), height: 1),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryTeal,
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Kasir Utama',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Offline Desktop',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => pinProv.lockApp(),
                            icon: const Icon(Icons.lock_outline, color: AppTheme.warningOrange, size: 20),
                            tooltip: 'Kunci Aplikasi (PIN)',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right Body Content Area
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar Header
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: const BoxDecoration(
                        color: AppTheme.cardBg,
                        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getMenuTitle(appProv.selectedNavIndex),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Excel status pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: appProv.connectedSpreadsheetPath != null
                                      ? AppTheme.primaryTealLight
                                      : AppTheme.warningBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      appProv.connectedSpreadsheetPath != null ? Icons.table_chart : Icons.table_chart_outlined,
                                      size: 14,
                                      color: appProv.connectedSpreadsheetPath != null ? AppTheme.primaryTeal : AppTheme.warningOrange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      appProv.connectedSpreadsheetPath != null ? 'Excel Terhubung' : 'Excel Disconnected',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: appProv.connectedSpreadsheetPath != null ? AppTheme.primaryTeal : AppTheme.warningOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Live Clock
                              StreamBuilder(
                                stream: Stream.periodic(const Duration(seconds: 1)),
                                builder: (context, snapshot) {
                                  final nowStr = DateFormat('HH:mm:ss').format(DateTime.now());
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          nowStr,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main Active Screen View
                    Expanded(
                      child: Container(
                        color: AppTheme.bgLight,
                        child: _getScreen(appProv.selectedNavIndex),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMenuTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard Utama';
      case 1:
        return 'Kasir Penjualan (POS)';
      case 2:
        return 'Katalog & Data Obat';
      case 3:
        return 'Mutasi Stok Obat';
      case 4:
        return 'Kategori & Supplier';
      case 5:
        return 'Laporan & Analitik';
      case 6:
        return 'Backup Database & Excel';
      default:
        return 'Apotek Firdan Farma';
    }
  }

  Widget _buildNavItem(BuildContext context, AppProvider appProv, {required int index, required String title, required IconData icon}) {
    final isSelected = appProv.selectedNavIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected ? AppTheme.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => appProv.setNavIndex(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.emeraldGreen : AppTheme.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
