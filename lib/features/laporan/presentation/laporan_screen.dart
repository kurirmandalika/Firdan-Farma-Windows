import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firdan_farma_windows/application/providers/laporan_provider.dart';
import 'package:firdan_farma_windows/core/constants/app_constants.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/core/utils/responsive_helper.dart';
import 'package:firdan_farma_windows/data/services/laporan_service.dart';
import 'package:firdan_farma_windows/data/services/spreadsheet_service.dart';
import 'package:firdan_farma_windows/shared/widgets/app_page.dart';
import 'package:firdan_farma_windows/shared/widgets/medical_card.dart';
import 'package:firdan_farma_windows/shared/widgets/stat_card.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final SpreadsheetService _spreadsheetService = SpreadsheetService();
  bool _isExporting = false;
  bool _isPrinting = false;

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
              onPrimary: theme.colorScheme.onPrimary,
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

  Future<void> _exportExcel() async {
    if (_isExporting) return;
    final provider = Provider.of<LaporanProvider>(context, listen: false);
    setState(() => _isExporting = true);
    try {
      final path = await _spreadsheetService.exportReportToSpreadsheet(
        provider.dariTanggal,
        provider.sampaiTanggal,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Ekspor laporan dibatalkan.'
                : 'Laporan Excel tersimpan.',
          ),
          backgroundColor: path == null ? null : AppTheme.successGreen,
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ekspor gagal: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _printReport() async {
    if (_isPrinting) return;
    final provider = Provider.of<LaporanProvider>(context, listen: false);
    setState(() => _isPrinting = true);

    try {
      if (provider.ringkasan == null && !provider.isLoading) {
        await provider.fetchLaporan();
      }

      final ringkasan = provider.ringkasan;
      final currencyFormatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      final period =
          '${DateFormat('dd MMM yyyy', 'id_ID').format(provider.dariTanggal)} - '
          '${DateFormat('dd MMM yyyy', 'id_ID').format(provider.sampaiTanggal)}';
      final printedAt = DateFormat(
        'dd MMM yyyy HH:mm',
        'id_ID',
      ).format(DateTime.now());
      final pdf = pw.Document();

      pw.Widget summaryCell(String label, String value) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: const pw.TextStyle(
                  color: PdfColors.grey700,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                value,
                style: pw.TextStyle(
                  color: PdfColors.green800,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        AppConstants.appName,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Laporan Penjualan',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        period,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Dicetak: $printedAt',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(),
                  1: pw.FlexColumnWidth(),
                  2: pw.FlexColumnWidth(),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 6, bottom: 8),
                        child: summaryCell(
                          'Total Penjualan',
                          currencyFormatter.format(
                            ringkasan?.totalPenjualan ?? 0,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(
                          left: 3,
                          right: 3,
                          bottom: 8,
                        ),
                        child: summaryCell(
                          'Laba Kotor',
                          currencyFormatter.format(
                            ringkasan?.totalLabaKotor ?? 0,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 6, bottom: 8),
                        child: summaryCell(
                          'Jumlah Transaksi',
                          '${ringkasan?.totalTransaksi ?? 0}',
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 6),
                        child: summaryCell(
                          'Item Terjual',
                          '${ringkasan?.totalItemTerjual ?? 0}',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 3, right: 3),
                        child: summaryCell(
                          'Total Pembelian',
                          currencyFormatter.format(
                            ringkasan?.totalPembelian ?? 0,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 6),
                        child: summaryCell(
                          'Nilai Stok',
                          currencyFormatter.format(
                            ringkasan?.nilaiStokAkhir ?? 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'Obat Terlaris',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              if (provider.obatTerlaris.isEmpty)
                pw.Text(
                  'Belum ada penjualan pada periode ini.',
                  style: const pw.TextStyle(fontSize: 9),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: ['Kode', 'Nama Obat', 'Terjual', 'Penjualan'],
                  data: provider.obatTerlaris
                      .map(
                        (item) => [
                          item.kodeObat,
                          item.namaObat,
                          '${item.totalTerjual}',
                          currencyFormatter.format(item.totalSubtotal),
                        ],
                      )
                      .toList(),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  headerStyle: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellPadding: const pw.EdgeInsets.all(5),
                ),
              pw.SizedBox(height: 18),
              pw.Text(
                'Detail Stok dan Penjualan per Obat',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              if (provider.medicineReports.isEmpty)
                pw.Text(
                  'Belum ada data obat untuk periode ini.',
                  style: const pw.TextStyle(fontSize: 9),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Kode',
                    'Nama',
                    'AWL',
                    'MSK',
                    'KLR',
                    'SISA',
                    'Penjualan',
                    'Laba',
                  ],
                  data: provider.medicineReports
                      .map(
                        (item) => [
                          item.kodeObat,
                          item.namaObat,
                          '${item.awl}',
                          '${item.msk}',
                          '${item.klr}',
                          '${item.sisa}',
                          currencyFormatter.format(item.omzet),
                          currencyFormatter.format(item.labaKotor),
                        ],
                      )
                      .toList(),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  headerStyle: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  cellPadding: const pw.EdgeInsets.all(4),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(48),
                    1: const pw.FlexColumnWidth(2.4),
                  },
                ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        name: 'Laporan_Firdan_Farma',
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cetak gagal: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
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
                  'Ringkasan omzet, pembelian, laba kotor, dan stok per obat',
              icon: Icons.analytics_outlined,
              actions: [
                OutlinedButton.icon(
                  onPressed: lapProv.setToday,
                  icon: const Icon(Icons.today, size: 17),
                  label: const Text('Hari Ini'),
                ),
                OutlinedButton.icon(
                  onPressed: lapProv.setYesterday,
                  icon: const Icon(Icons.history_outlined, size: 17),
                  label: const Text('Kemarin'),
                ),
                OutlinedButton.icon(
                  onPressed: lapProv.setLast7Days,
                  icon: const Icon(Icons.view_week_outlined, size: 17),
                  label: const Text('7 Hari'),
                ),
                OutlinedButton.icon(
                  onPressed: lapProv.setThisMonth,
                  icon: const Icon(Icons.calendar_month_outlined, size: 17),
                  label: const Text('Bulan Ini'),
                ),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: Icon(Icons.date_range, color: AppTheme.primaryTeal),
                  label: Text('$dariStr - $sampaiStr'),
                ),
                ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportExcel,
                  icon: _isExporting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_outlined, size: 17),
                  label: const Text('Ekspor Excel'),
                ),
                ElevatedButton.icon(
                  onPressed: _isPrinting || lapProv.isLoading
                      ? null
                      : _printReport,
                  icon: _isPrinting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined, size: 17),
                  label: const Text('Cetak PDF'),
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
                        title: 'Total Pembelian',
                        value: currencyFormatter.format(
                          ringkasan?.totalPembelian ?? 0,
                        ),
                        subtitle: 'Obat masuk periode ini',
                        icon: Icons.shopping_bag_outlined,
                        iconBgColor: AppTheme.emeraldLight,
                        iconColor: AppTheme.emeraldGreen,
                      ),
                      StatCard(
                        title: 'Laba Kotor',
                        value: currencyFormatter.format(
                          ringkasan?.totalLabaKotor ?? 0,
                        ),
                        subtitle: 'Omzet dikurangi modal terjual',
                        icon: Icons.account_balance_wallet_outlined,
                        iconBgColor: AppTheme.primaryTealLight,
                        iconColor: AppTheme.cyanAccent,
                      ),
                      StatCard(
                        title: 'Jumlah Transaksi',
                        value: '${ringkasan?.totalTransaksi ?? 0}',
                        subtitle: 'Transaksi kasir periode ini',
                        icon: Icons.receipt_long_outlined,
                        iconBgColor: AppTheme.warningBg,
                        iconColor: AppTheme.warningOrange,
                      ),
                      StatCard(
                        title: 'Nilai Stok',
                        value: currencyFormatter.format(
                          ringkasan?.nilaiStokAkhir ?? 0,
                        ),
                        subtitle:
                            '${ringkasan?.stokMenipisCount ?? 0} item stok menipis',
                        icon: Icons.inventory_2_outlined,
                        iconBgColor: AppTheme.indigoLight,
                        iconColor: AppTheme.indigo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _MedicineReportTable(
                    items: lapProv.medicineReports,
                    currencyFormatter: currencyFormatter,
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
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary
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

class _MedicineReportTable extends StatelessWidget {
  final List<MedicinePeriodReport> items;
  final NumberFormat currencyFormatter;

  const _MedicineReportTable({
    required this.items,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            icon: Icons.table_chart_outlined,
            title: 'Laporan Stok dan Penjualan per Obat',
            subtitle: 'AWL, MSK, KLR, dan SISA dihitung dari riwayat stok',
          ),
          const SizedBox(height: 16),
          const Divider(),
          if (items.isEmpty)
            const EmptyState(
              icon: Icons.table_rows_outlined,
              title: 'Belum ada data',
              subtitle: 'Data laporan akan tampil setelah ada master obat.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('Kode')),
                  DataColumn(label: Text('Nama Obat')),
                  DataColumn(label: Text('Sat')),
                  DataColumn(label: Text('AWL'), numeric: true),
                  DataColumn(label: Text('MSK'), numeric: true),
                  DataColumn(label: Text('KLR'), numeric: true),
                  DataColumn(label: Text('SISA'), numeric: true),
                  DataColumn(label: Text('HB'), numeric: true),
                  DataColumn(label: Text('HJ'), numeric: true),
                  DataColumn(label: Text('Penjualan'), numeric: true),
                  DataColumn(label: Text('Pembelian'), numeric: true),
                  DataColumn(label: Text('Laba Kotor'), numeric: true),
                  DataColumn(label: Text('Nilai Stok'), numeric: true),
                ],
                rows: items.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(item.kodeObat)),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Text(
                            item.namaObat,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(item.satuan)),
                      DataCell(Text('${item.awl}')),
                      DataCell(Text('${item.msk}')),
                      DataCell(Text('${item.klr}')),
                      DataCell(Text('${item.sisa}')),
                      DataCell(Text(currencyFormatter.format(item.hargaBeli))),
                      DataCell(Text(currencyFormatter.format(item.hargaJual))),
                      DataCell(Text(currencyFormatter.format(item.omzet))),
                      DataCell(Text(currencyFormatter.format(item.pembelian))),
                      DataCell(Text(currencyFormatter.format(item.labaKotor))),
                      DataCell(
                        Text(currencyFormatter.format(item.nilaiStokAkhir)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
