import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../providers/pin_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactScreen = screenWidth < ResponsiveBreakpoints.tabletMax;

    return Consumer2<AppProvider, PinProvider>(
      builder: (context, appProv, pinProv, _) {
        final isCollapsed = isCompactScreen || appProv.isSidebarCollapsed;

        return Scaffold(
          body: Row(
            children: [
              // Animated Sidebar Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isCollapsed ? 72 : 240,
                color: AppTheme.sidebarBackground,
                child: Column(
                  children: [
                    // Brand Header
                    Container(
                      height: 64,
                      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 16),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.local_pharmacy,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          if (!isCollapsed) ...[
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FIRDAN FARMA',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Apotek Windows POS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFF334155), height: 1),
                    const SizedBox(height: 12),

                    // Nav Menu Items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          _buildNavItem(context, appProv, index: 0, title: 'Dashboard', icon: Icons.dashboard_outlined, isCollapsed: isCollapsed),
                          _buildNavItem(context, appProv, index: 1, title: 'Kasir Penjualan', icon: Icons.point_of_sale, isCollapsed: isCollapsed),
                          _buildNavItem(context, appProv, index: 2, title: 'Katalog Obat', icon: Icons.medication_outlined, isCollapsed: isCollapsed),
                          _buildNavItem(context, appProv, index: 3, title: 'Mutasi Stok', icon: Icons.swap_vert, isCollapsed: isCollapsed),
                          _buildNavItem(context, appProv, index: 4, title: 'Kategori & Supplier', icon: Icons.category_outlined, isCollapsed: isCollapsed),
                          _buildNavItem(context, appProv, index: 5, title: 'Laporan & Analitik', icon: Icons.analytics_outlined, isCollapsed: isCollapsed),
                          _buildNavItem(context, appProv, index: 6, title: 'Backup & Excel', icon: Icons.table_chart_outlined, isCollapsed: isCollapsed),
                        ],
                      ),
                    ),

                    // User Info & PIN Lock Footer
                    const Divider(color: Color(0xFF334155), height: 1),
                    Container(
                      padding: EdgeInsets.all(isCollapsed ? 8 : 12),
                      child: isCollapsed
                          ? IconButton(
                              onPressed: () => pinProv.lockApp(),
                              icon: const Icon(Icons.lock_outline, color: AppTheme.warningOrange, size: 20),
                              tooltip: 'Kunci Aplikasi (PIN)',
                            )
                          : Row(
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.primaryTeal,
                                  child: Icon(Icons.person, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kasir Utama',
                                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                      ),
                                      Text(
                                        'Offline Desktop',
                                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => pinProv.lockApp(),
                                  icon: const Icon(Icons.lock_outline, color: AppTheme.warningOrange, size: 18),
                                  tooltip: 'Kunci Aplikasi (PIN)',
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),

              // Main Active Screen & Header Bar
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar Header
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: const BoxDecoration(
                        color: AppTheme.cardBg,
                        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => appProv.toggleSidebar(),
                                icon: Icon(
                                  isCollapsed ? Icons.menu : Icons.menu_open,
                                  color: AppTheme.textPrimary,
                                ),
                                tooltip: isCollapsed ? 'Buka Sidebar' : 'Ciutkan Sidebar',
                              ),
                              const SizedBox(width: 12),
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
                                    if (screenWidth > 600) ...[
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
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
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

  Widget _buildNavItem(
    BuildContext context,
    AppProvider appProv, {
    required int index,
    required String title,
    required IconData icon,
    required bool isCollapsed,
  }) {
    final isSelected = appProv.selectedNavIndex == index;

    Widget itemContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected ? AppTheme.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => appProv.setNavIndex(index),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 14 : 14, vertical: 11),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.emeraldGreen : AppTheme.textMuted,
                  size: 20,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(
        message: title,
        preferBelow: false,
        child: itemContent,
      );
    }
    return itemContent;
  }
}
