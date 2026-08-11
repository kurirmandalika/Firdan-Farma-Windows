import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firdan_farma_windows/application/providers/app_provider.dart';
import 'package:firdan_farma_windows/application/providers/pin_provider.dart';
import 'package:firdan_farma_windows/core/constants/app_constants.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/core/utils/responsive_helper.dart';
import 'package:firdan_farma_windows/features/backup_excel/presentation/backup_excel_screen.dart';
import 'package:firdan_farma_windows/features/dashboard/presentation/dashboard_screen.dart';
import 'package:firdan_farma_windows/features/master/presentation/kategori_supplier_screen.dart';
import 'package:firdan_farma_windows/features/laporan/presentation/laporan_screen.dart';
import 'package:firdan_farma_windows/features/obat/presentation/obat_list_screen.dart';
import 'package:firdan_farma_windows/features/stok/presentation/stok_screen.dart';
import 'package:firdan_farma_windows/features/transaksi/presentation/transaksi_screen.dart';
import 'package:firdan_farma_windows/shared/widgets/brand_logo.dart';

class MainDesktopShell extends StatelessWidget {
  const MainDesktopShell({super.key});

  static const _destinations = [
    _NavDestination('Dashboard', 'Ringkasan', Icons.dashboard_outlined),
    _NavDestination('Kasir', 'Transaksi', Icons.point_of_sale),
    _NavDestination('Obat', 'Katalog', Icons.medication_outlined),
    _NavDestination('Stok', 'Mutasi', Icons.swap_vert),
    _NavDestination('Master', 'Kategori', Icons.category_outlined),
    _NavDestination('Laporan', 'Analitik', Icons.analytics_outlined),
    _NavDestination('Data', 'Excel', Icons.table_chart_outlined),
  ];

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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactScreen = screenWidth < ResponsiveBreakpoints.tabletMax;

    return Consumer2<AppProvider, PinProvider>(
      builder: (context, appProv, pinProv, _) {
        final isCollapsed = isCompactScreen || appProv.isSidebarCollapsed;
        final currentIndex = appProv.selectedNavIndex
            .clamp(0, _destinations.length - 1)
            .toInt();
        final active = _destinations[currentIndex];

        return Scaffold(
          body: Row(
            children: [
              _Sidebar(
                isCollapsed: isCollapsed,
                selectedIndex: currentIndex,
                destinations: _destinations,
                onDestinationSelected: appProv.setNavIndex,
                onLock: pinProv.lockApp,
              ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      title: active.label,
                      subtitle: active.subtitle,
                      isCollapsed: isCollapsed,
                      canShowDetails: screenWidth > 720,
                      spreadsheetPath: appProv.connectedSpreadsheetPath,
                      isDarkMode: appProv.isDarkMode,
                      onToggleSidebar: appProv.toggleSidebar,
                      onToggleTheme: appProv.toggleThemeMode,
                      onLock: pinProv.lockApp,
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: AppTheme.bgLight,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: KeyedSubtree(
                            key: ValueKey(currentIndex),
                            child: _getScreen(currentIndex),
                          ),
                        ),
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
}

class _Sidebar extends StatelessWidget {
  final bool isCollapsed;
  final int selectedIndex;
  final List<_NavDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLock;

  const _Sidebar({
    required this.isCollapsed,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: isCollapsed ? 78 : 260,
      decoration: BoxDecoration(
        color: AppTheme.sidebarBackground,
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isCollapsed ? 14 : 16,
                14,
                isCollapsed ? 14 : 16,
                12,
              ),
              child: Row(
                children: [
                  const BrandLogo.mark(size: 42, shadow: true),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName.replaceFirst('Apotek ', ''),
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kasir Apotek',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(color: AppTheme.borderLight),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final item = destinations[index];
                  return _SidebarItem(
                    item: item,
                    isSelected: selectedIndex == index,
                    isCollapsed: isCollapsed,
                    onTap: () => onDestinationSelected(index),
                  );
                },
              ),
            ),
            Divider(color: AppTheme.borderLight),
            Padding(
              padding: EdgeInsets.all(isCollapsed ? 10 : 12),
              child: isCollapsed
                  ? Tooltip(
                      message: 'Kunci aplikasi',
                      child: IconButton.filledTonal(
                        onPressed: onLock,
                        icon: const Icon(Icons.lock_outline, size: 19),
                        color: AppTheme.warningOrange,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSubtle,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: AppTheme.primaryTeal,
                            child: Icon(
                              Icons.person_outline,
                              color: AppTheme.isDark
                                  ? Colors.black
                                  : Colors.white,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kasir Utama',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Mode offline',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: 'Kunci aplikasi',
                            child: IconButton(
                              onPressed: onLock,
                              icon: const Icon(Icons.lock_outline, size: 19),
                              color: AppTheme.warningOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavDestination item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected ? AppTheme.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Stack(
            children: [
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 9,
                  bottom: 9,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 0 : 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected
                          ? AppTheme.primaryTeal
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? AppTheme.primaryTeal
                                    : AppTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isCollapsed) return content;
    return Tooltip(message: item.label, preferBelow: false, child: content);
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCollapsed;
  final bool canShowDetails;
  final String? spreadsheetPath;
  final bool isDarkMode;
  final VoidCallback onToggleSidebar;
  final VoidCallback onToggleTheme;
  final VoidCallback onLock;

  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.isCollapsed,
    required this.canShowDetails,
    required this.spreadsheetPath,
    required this.isDarkMode,
    required this.onToggleSidebar,
    required this.onToggleTheme,
    required this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    final hasSpreadsheet = spreadsheetPath != null;

    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Tooltip(
            message: isCollapsed ? 'Buka menu' : 'Ciutkan menu',
            child: IconButton(
              onPressed: onToggleSidebar,
              icon: Icon(
                isCollapsed ? Icons.menu : Icons.menu_open,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (canShowDetails)
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
          const SizedBox(width: 10),
          _StatusPill(
            icon: hasSpreadsheet
                ? Icons.table_chart
                : Icons.table_chart_outlined,
            label: hasSpreadsheet ? 'Excel terhubung' : 'Excel belum aktif',
            color: hasSpreadsheet
                ? AppTheme.primaryTeal
                : AppTheme.warningOrange,
            backgroundColor: hasSpreadsheet
                ? AppTheme.primaryTealLight
                : AppTheme.warningBg,
            showLabel: canShowDetails,
          ),
          const SizedBox(width: 8),
          _ThemeModeButton(isDarkMode: isDarkMode, onPressed: onToggleTheme),
          const SizedBox(width: 8),
          if (canShowDetails) const _ClockPill(),
          if (!canShowDetails)
            Tooltip(
              message: 'Kunci aplikasi',
              child: IconButton(
                onPressed: onLock,
                icon: Icon(
                  Icons.lock_outline,
                  color: AppTheme.warningOrange,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onPressed;

  const _ThemeModeButton({required this.isDarkMode, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDarkMode ? 'Mode terang' : 'Mode malam',
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          color: AppTheme.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final bool showLabel;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: showLabel ? 11 : 9),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (showLabel) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClockPill extends StatelessWidget {
  const _ClockPill();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (tick) => tick),
      builder: (context, snapshot) {
        final nowStr = DateFormat('HH:mm:ss').format(DateTime.now());
        return Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: AppTheme.bgSubtle,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 7),
              Text(
                nowStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavDestination {
  final String label;
  final String subtitle;
  final IconData icon;

  const _NavDestination(this.label, this.subtitle, this.icon);
}
