import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firdan_farma_windows/application/providers/laporan_provider.dart';
import 'package:firdan_farma_windows/core/constants/app_constants.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/core/utils/responsive_helper.dart';
import 'package:firdan_farma_windows/data/services/laporan_service.dart';
import 'package:firdan_farma_windows/data/services/auth_service.dart';
import 'package:firdan_farma_windows/data/models/audit_log_model.dart';
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
                _ReportRangeMenu(
                  onSelected: (range) {
                    switch (range) {
                      case _ReportRange.today:
                        lapProv.setToday();
                      case _ReportRange.yesterday:
                        lapProv.setYesterday();
                      case _ReportRange.last7Days:
                        lapProv.setLast7Days();
                      case _ReportRange.thisMonth:
                        lapProv.setThisMonth();
                    }
                  },
                ),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: Icon(Icons.date_range, color: AppTheme.primaryTeal),
                  label: Text('$dariStr - $sampaiStr'),
                ),
                _ReportOutputMenu(
                  isExporting: _isExporting,
                  isPrinting: _isPrinting,
                  isLoading: lapProv.isLoading,
                  onExportExcel: _exportExcel,
                  onPrintReport: _printReport,
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
                  _PaymentSummaryCard(
                    items: lapProv.paymentSummaries,
                    currencyFormatter: currencyFormatter,
                    reportDate: lapProv.dariTanggal,
                  ),
                  const SizedBox(height: 22),
                  _MedicineReportTable(
                    items: lapProv.medicineReports,
                    currencyFormatter: currencyFormatter,
                  ),
                  const SizedBox(height: 22),
                  if (AuthSession.isSuperAdmin) ...[
                    _AuditLogCard(items: lapProv.activityLogs),
                    const SizedBox(height: 22),
                  ],
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

enum _ReportRange { today, yesterday, last7Days, thisMonth }

enum _ReportOutput { excel, pdf }

class _ReportRangeMenu extends StatelessWidget {
  final ValueChanged<_ReportRange> onSelected;

  const _ReportRangeMenu({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ReportRange>(
      tooltip: 'Pilih periode cepat',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: _ReportRange.today, child: Text('Hari ini')),
        PopupMenuItem(value: _ReportRange.yesterday, child: Text('Kemarin')),
        PopupMenuItem(value: _ReportRange.last7Days, child: Text('7 hari')),
        PopupMenuItem(value: _ReportRange.thisMonth, child: Text('Bulan ini')),
      ],
      child: _HeaderMenuChip(
        icon: Icons.tune,
        label: 'Periode',
        color: AppTheme.primaryTeal,
      ),
    );
  }
}

class _ReportOutputMenu extends StatelessWidget {
  final bool isExporting;
  final bool isPrinting;
  final bool isLoading;
  final VoidCallback onExportExcel;
  final VoidCallback onPrintReport;

  const _ReportOutputMenu({
    required this.isExporting,
    required this.isPrinting,
    required this.isLoading,
    required this.onExportExcel,
    required this.onPrintReport,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = isExporting || isPrinting;
    return PopupMenuButton<_ReportOutput>(
      tooltip: 'Simpan atau cetak laporan',
      onSelected: (value) {
        switch (value) {
          case _ReportOutput.excel:
            onExportExcel();
          case _ReportOutput.pdf:
            onPrintReport();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_ReportOutput>(
          value: _ReportOutput.excel,
          enabled: !isExporting,
          child: Row(
            children: [
              isExporting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined, size: 17),
              const SizedBox(width: 10),
              const Text('Ekspor Excel'),
            ],
          ),
        ),
        PopupMenuItem<_ReportOutput>(
          value: _ReportOutput.pdf,
          enabled: !isPrinting && !isLoading,
          child: Row(
            children: [
              isPrinting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_outlined, size: 17),
              const SizedBox(width: 10),
              const Text('Cetak PDF'),
            ],
          ),
        ),
      ],
      child: _HeaderMenuChip(
        icon: isBusy ? Icons.hourglass_top : Icons.ios_share_outlined,
        label: isBusy ? 'Memproses' : 'Simpan',
        color: AppTheme.primaryTeal,
      ),
    );
  }
}

class _HeaderMenuChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderMenuChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, size: 17, color: color),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final List<SalesPaymentSummary> items;
  final NumberFormat currencyFormatter;
  final DateTime reportDate;

  const _PaymentSummaryCard({
    required this.items,
    required this.currencyFormatter,
    required this.reportDate,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Laporan per Metode Pembayaran',
            subtitle: 'Periode bisnis ditutup setiap hari pukul 15.00',
            trailing: Text(
              DateFormat('dd MMM yyyy').format(reportDate),
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text('Belum ada penjualan pada periode ini.')
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items
                  .map(
                    (item) => Container(
                      width: 210,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSubtle,
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.kodePrefix} | ${item.metodePembayaran}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            currencyFormatter.format(item.total),
                            style: TextStyle(
                              color: AppTheme.primaryTeal,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${item.jumlahTransaksi} transaksi',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  final List<AuditLog> items;

  const _AuditLogCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            icon: Icons.manage_search_outlined,
            title: 'Audit Aktivitas Super Admin',
            subtitle: 'Detail aksi pengguna untuk pemeriksaan kesalahan input',
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text('Belum ada aktivitas tercatat.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final time = DateTime.tryParse(item.createdAt);
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryTealLight,
                    child: Icon(
                      Icons.history,
                      size: 16,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  title: Text(
                    '${item.username ?? 'SISTEM'} | ${item.aksi} | ${item.entitas}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  subtitle: Text(
                    '${time == null ? item.createdAt : DateFormat('dd/MM/yyyy HH:mm:ss').format(time)}'
                    '${item.metodePembayaran == null ? '' : ' | ${item.metodePembayaran}'}'
                    '${item.nominal == null ? '' : ' | Rp ${item.nominal!.toStringAsFixed(0)}'}'
                    '${item.alasan == null ? '' : ' | ${item.alasan}'}'
                    '${item.detail == null ? '' : ' | ${item.detail}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
        ],
      ),
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
            subtitle: 'AWL, MSK, KLR, dan SISA mengikuti snapshot katalog',
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
