import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/core/constants/app_constants.dart';

import 'package:firdan_farma_windows/application/providers/app_provider.dart';
import 'package:firdan_farma_windows/application/providers/obat_provider.dart';
import 'package:firdan_farma_windows/application/providers/kategori_provider.dart';
import 'package:firdan_farma_windows/application/providers/supplier_provider.dart';
import 'package:firdan_farma_windows/application/providers/stok_provider.dart';
import 'package:firdan_farma_windows/application/providers/transaksi_provider.dart';
import 'package:firdan_farma_windows/application/providers/laporan_provider.dart';
import 'package:firdan_farma_windows/application/providers/pin_provider.dart';

import 'package:firdan_farma_windows/features/pin/presentation/pin_gate_screen.dart';
import 'package:firdan_farma_windows/features/shell/presentation/main_desktop_shell.dart';
import 'package:firdan_farma_windows/features/startup/presentation/startup_splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for Desktop (Windows / Linux / macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const FirdanFarmaApp());
}

class FirdanFarmaApp extends StatelessWidget {
  const FirdanFarmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ObatProvider()),
        ChangeNotifierProvider(create: (_) => KategoriProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => StokProvider()),
        ChangeNotifierProvider(create: (_) => TransaksiProvider()),
        ChangeNotifierProvider(create: (_) => LaporanProvider()),
        ChangeNotifierProvider(create: (_) => PinProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          AppTheme.setBrightness(
            appProvider.isDarkMode ? Brightness.dark : Brightness.light,
          );

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.themeMode,
            home: const StartupSplashScreen(
              child: PinGateScreen(child: MainDesktopShell()),
            ),
          );
        },
      ),
    );
  }
}
