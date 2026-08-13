import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firdan_farma_windows/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firdan_farma_windows/application/providers/app_provider.dart';
import 'package:firdan_farma_windows/application/providers/obat_provider.dart';
import 'package:firdan_farma_windows/application/providers/kategori_provider.dart';
import 'package:firdan_farma_windows/application/providers/supplier_provider.dart';
import 'package:firdan_farma_windows/application/providers/stok_provider.dart';
import 'package:firdan_farma_windows/application/providers/transaksi_provider.dart';
import 'package:firdan_farma_windows/application/providers/laporan_provider.dart';
import 'package:firdan_farma_windows/application/providers/pembelian_provider.dart';
import 'package:firdan_farma_windows/application/providers/pin_provider.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/features/backup_excel/presentation/backup_excel_screen.dart';
import 'package:firdan_farma_windows/features/shell/presentation/main_desktop_shell.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.runAsync(DatabaseHelper.openInMemoryForTesting);
    addTearDown(DatabaseHelper.instance.closeAndReset);
    await tester.pumpWidget(const FirdanFarmaApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FirdanFarmaApp), findsOneWidget);
  });

  testWidgets('Data page fits desktop and compact layouts', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(DatabaseHelper.openInMemoryForTesting);
    addTearDown(DatabaseHelper.instance.closeAndReset);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    Future<void> pumpDataPage(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
            ChangeNotifierProvider(create: (_) => ObatProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: BackupExcelScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await pumpDataPage(const Size(1280, 820));
    await pumpDataPage(const Size(560, 820));
  });

  testWidgets('All workspace pages mount without framework errors', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(DatabaseHelper.openInMemoryForTesting);
    addTearDown(DatabaseHelper.instance.closeAndReset);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await initializeDateFormatting('id_ID');
    await tester.binding.setSurfaceSize(const Size(1440, 900));

    final appProvider = AppProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appProvider),
          ChangeNotifierProvider(create: (_) => ObatProvider()),
          ChangeNotifierProvider(create: (_) => KategoriProvider()),
          ChangeNotifierProvider(create: (_) => SupplierProvider()),
          ChangeNotifierProvider(create: (_) => StokProvider()),
          ChangeNotifierProvider(create: (_) => TransaksiProvider()),
          ChangeNotifierProvider(create: (_) => PembelianProvider()),
          ChangeNotifierProvider(create: (_) => LaporanProvider()),
          ChangeNotifierProvider(create: (_) => PinProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainDesktopShell(),
        ),
      ),
    );
    await tester.pump();

    for (var index = 1; index < 8; index++) {
      appProvider.setNavIndex(index);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      // The shell clock is intentionally periodic, so use bounded pumps.
      await tester.pump(const Duration(milliseconds: 300));
      final exception = tester.takeException();
      expect(exception, isNull, reason: 'Halaman indeks $index');
    }
  });
}
