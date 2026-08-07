import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'utils/app_constants.dart';
import 'database/database_helper.dart';

import 'providers/app_provider.dart';
import 'providers/obat_provider.dart';
import 'providers/kategori_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/stok_provider.dart';
import 'providers/transaksi_provider.dart';
import 'providers/laporan_provider.dart';
import 'providers/pin_provider.dart';

import 'screens/pin/pin_gate_screen.dart';
import 'screens/main_desktop_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for Desktop (Windows / Linux / macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize Date Formatting Locale
  await initializeDateFormatting('id_ID', null);

  // Pre-warm database connection
  await DatabaseHelper.instance.database;

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
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const PinGateScreen(
          child: MainDesktopShell(),
        ),
      ),
    );
  }
}
