import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firdan_farma_windows/application/providers/app_provider.dart';
import 'package:firdan_farma_windows/application/providers/laporan_provider.dart';
import 'package:firdan_farma_windows/application/providers/obat_provider.dart';
import 'package:firdan_farma_windows/application/providers/pembelian_provider.dart';
import 'package:firdan_farma_windows/application/providers/stok_provider.dart';
import 'package:firdan_farma_windows/application/providers/transaksi_provider.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/data/services/backup_service.dart';
import 'package:firdan_farma_windows/data/services/spreadsheet_service.dart';
import 'package:firdan_farma_windows/shared/widgets/app_page.dart';

class BackupExcelScreen extends StatefulWidget {
  const BackupExcelScreen({super.key});

  @override
  State<BackupExcelScreen> createState() => _BackupExcelScreenState();
}

class _BackupExcelScreenState extends State<BackupExcelScreen> {
  final BackupService _backupService = BackupService();
  final SpreadsheetService _spreadsheetService = SpreadsheetService();

  bool _isProcessing = false;
  bool _replaceCatalog = false;
  String? _selectedImportFilePath;
  ImportResult? _lastImportResult;

  Future<void> _handlePickImportFile() async {
    final path = await _spreadsheetService.pickSpreadsheetFile();
    if (!mounted || path == null) return;
    setState(() {
      _selectedImportFilePath = path;
      _lastImportResult = null;
    });
  }

  Future<void> _handleRunImport() async {
    final path = _selectedImportFilePath;
    if (path == null || _isProcessing) return;
    final obatProvider = Provider.of<ObatProvider>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (_replaceCatalog) {
      final confirmed = await _showConfirmDialog(
        title: 'Ganti isi katalog?',
        content:
            'Data yang tidak ada di file baru akan diarsipkan dari katalog aktif. Riwayat transaksi dan stok tetap aman.',
        confirmLabel: 'Ganti Katalog',
        isDanger: true,
      );
      if (confirmed != true) return;
    }

    setState(() {
      _isProcessing = true;
      _lastImportResult = null;
    });

    try {
      final result = await _spreadsheetService.importSpreadsheetToDb(
        path,
        replaceCatalog: _replaceCatalog,
      );
      if (!mounted) return;

      await obatProvider.fetchObat();
      await obatProvider.fetchDashboardSummary();
      if (!mounted) return;
      setState(() => _lastImportResult = result);
      await _showImportResultDialog(result, appProvider);
    } on Object catch (error) {
      if (mounted) _showError('Impor gagal: ${_cleanError(error)}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleExportExcel() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final path = await _spreadsheetService.exportDatabaseToSpreadsheet();
      if (!mounted) return;
      if (path == null) {
        _showInfo('Ekspor dibatalkan.');
      } else {
        _showSuccess('Excel berhasil disimpan.');
      }
    } on Object catch (error) {
      if (mounted) _showError('Ekspor gagal: ${_cleanError(error)}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDownloadTemplate() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final path = await _spreadsheetService.downloadTemplateExcel();
      if (!mounted) return;
      path == null
          ? _showInfo('Download template dibatalkan.')
          : _showSuccess('Template Excel berhasil disimpan.');
    } on Object catch (error) {
      if (mounted) _showError('Template gagal dibuat: ${_cleanError(error)}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleExportDatabase() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final path = await _backupService.exportDatabase();
      if (!mounted) return;
      path == null
          ? _showInfo('Backup dibatalkan.')
          : _showSuccess('Backup database berhasil disimpan.');
    } on Object catch (error) {
      if (mounted) _showError('Backup gagal: ${_cleanError(error)}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImportDatabase() async {
    if (_isProcessing) return;
    final obatProvider = Provider.of<ObatProvider>(context, listen: false);
    final path = await _backupService.pickBackupFile();
    if (!mounted || path == null) return;
    final confirmed = await _showConfirmDialog(
      title: 'Pulihkan database?',
      content:
          'Database saat ini akan diganti dengan file backup. Aplikasi membuat salinan otomatis sebelum proses dimulai.',
      confirmLabel: 'Pulihkan',
      isDanger: true,
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final success = await _backupService.importDatabase(path);
      if (success) {
        await obatProvider.fetchObat();
        await obatProvider.fetchDashboardSummary();
        if (mounted) _showSuccess('Database berhasil dipulihkan.');
      }
    } on Object catch (error) {
      if (mounted) _showError('Restore gagal: ${_cleanError(error)}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleResetOperationalData() async {
    if (_isProcessing) return;
    final confirmed = await _showResetConfirmationDialog();
    if (!mounted || !confirmed) return;

    final obatProvider = Provider.of<ObatProvider>(context, listen: false);
    final stokProvider = Provider.of<StokProvider>(context, listen: false);
    final transaksiProvider = Provider.of<TransaksiProvider>(
      context,
      listen: false,
    );
    final pembelianProvider = Provider.of<PembelianProvider>(
      context,
      listen: false,
    );
    final laporanProvider = Provider.of<LaporanProvider>(
      context,
      listen: false,
    );

    setState(() => _isProcessing = true);
    try {
      final backupPath = await _backupService.resetOperationalData();
      transaksiProvider.clearCart();
      pembelianProvider.clearCart();
      await Future.wait([
        obatProvider.fetchObat(),
        obatProvider.fetchDashboardSummary(),
        stokProvider.fetchMutasi(),
        transaksiProvider.fetchHistory(),
        pembelianProvider.fetchPembelian(),
        pembelianProvider.fetchSummary(),
        laporanProvider.fetchLaporan(),
      ]);
      if (!mounted) return;
      setState(() {
        _selectedImportFilePath = null;
        _lastImportResult = null;
      });
      _showSuccess('Data operasional direset. Backup: $backupPath');
    } on Object catch (error) {
      if (mounted) _showError('Reset dibatalkan: ${_cleanError(error)}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _showResetConfirmationDialog() async {
    final controller = TextEditingController();
    var matches = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset Data Operasional'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tindakan ini menghapus obat, stok, transaksi, pembelian, dan data laporan turunan. Kategori dan supplier tetap tersedia. Backup database dibuat otomatis sebelum reset.',
                ),
                const SizedBox(height: 16),
                const Text('Ketik RESET DATA untuk melanjutkan.'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'RESET DATA'),
                  onChanged: (value) => setDialogState(
                    () => matches = value.trim() == 'RESET DATA',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
              ),
              onPressed: matches
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: const Text('Backup dan Reset'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result ?? false;
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger
                  ? AppTheme.dangerRed
                  : AppTheme.primaryTeal,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportResultDialog(
    ImportResult result,
    AppProvider appProvider,
  ) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.hasErrors
                  ? Icons.info_outline_rounded
                  : Icons.check_circle_rounded,
              color: result.hasErrors
                  ? AppTheme.warningOrange
                  : AppTheme.successGreen,
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Impor selesai')),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _resultLine(
                  Icons.add_circle_outline,
                  AppTheme.successGreen,
                  '${result.inserted} data baru',
                ),
                _resultLine(
                  Icons.sync_rounded,
                  AppTheme.primaryTeal,
                  '${result.updated} data diperbarui',
                ),
                if (result.archived > 0)
                  _resultLine(
                    Icons.archive_outlined,
                    AppTheme.warningOrange,
                    '${result.archived} data lama diarsipkan',
                  ),
                if (result.skipped > 0)
                  _resultLine(
                    Icons.remove_circle_outline,
                    AppTheme.textSecondary,
                    '${result.skipped} baris dilewati',
                  ),
                if (result.errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Perlu diperiksa',
                    style: TextStyle(
                      color: AppTheme.dangerRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 140),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerBg,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        result.errors.join('\n'),
                        style: TextStyle(
                          color: AppTheme.dangerRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
          if (result.total > 0)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                appProvider.setNavIndex(2);
              },
              icon: const Icon(Icons.medication_outlined, size: 17),
              label: const Text('Katalog'),
            ),
        ],
      ),
    );
  }

  Widget _resultLine(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();

  void _showSuccess(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppTheme.successGreen),
    );
  }

  void _showError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppTheme.dangerRed),
    );
  }

  void _showInfo(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ObatProvider>(
      builder: (context, obatProvider, _) {
        return AppPage(
          title: 'Data, Impor & Backup',
          subtitle:
              'SQLite adalah data utama; Excel hanya diproses saat Anda memilih aksi',
          icon: Icons.table_chart_outlined,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1180;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isProcessing) ...[
                    LinearProgressIndicator(
                      minHeight: 3,
                      color: AppTheme.primaryTeal,
                      backgroundColor: AppTheme.primaryTealLight,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildImportPanel()),
                        const SizedBox(width: 14),
                        Expanded(child: _buildExportPanel(obatProvider)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildImportPanel(),
                        const SizedBox(height: 14),
                        _buildExportPanel(obatProvider),
                      ],
                    ),
                  const SizedBox(height: 14),
                  _buildDatabasePanel(),
                  const SizedBox(height: 14),
                  _buildAdminPanel(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImportPanel() {
    final path = _selectedImportFilePath;
    final fileName = path == null ? null : File(path).uri.pathSegments.last;
    final hasFile = path != null;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.upload_file_rounded,
            color: AppTheme.primaryTeal,
            title: 'Impor atau ganti Excel',
            subtitle: 'Header kolom dibaca otomatis dari file .xlsx',
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _isProcessing ? null : _handlePickImportFile,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasFile
                    ? AppTheme.primaryTealLight.withValues(alpha: 0.5)
                    : AppTheme.bgSubtle,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: hasFile ? AppTheme.primaryTeal : AppTheme.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasFile
                        ? Icons.description_outlined
                        : Icons.folder_open_outlined,
                    color: hasFile
                        ? AppTheme.primaryTeal
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileName ?? 'Pilih file Excel dari komputer',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    hasFile ? Icons.check_circle : Icons.chevron_right,
                    color: hasFile ? AppTheme.successGreen : AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _replaceCatalog,
            onChanged: _isProcessing
                ? null
                : (value) => setState(() => _replaceCatalog = value),
            title: Text(
              'Ganti isi katalog',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              'Arsipkan data lama yang tidak ada di file baru',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: hasFile && !_isProcessing ? _handleRunImport : null,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(hasFile ? 'Impor sekarang' : 'Pilih file dulu'),
              ),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _handlePickImportFile,
                icon: const Icon(Icons.folder_open_outlined, size: 17),
                label: Text(hasFile ? 'Ganti file' : 'Pilih file'),
              ),
            ],
          ),
          if (_lastImportResult != null) ...[
            const SizedBox(height: 12),
            _ImportSummary(result: _lastImportResult!),
          ],
          const SizedBox(height: 12),
          Text(
            'Bisa membaca nama kolom Indonesia/Inggris, judul tambahan, angka Rp, titik, atau koma.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _isProcessing ? null : _handleDownloadTemplate,
            icon: const Icon(Icons.download_outlined, size: 17),
            label: const Text('Unduh template contoh'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportPanel(ObatProvider obatProvider) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.file_download_outlined,
            color: AppTheme.successGreen,
            title: 'Ekspor katalog',
            subtitle: 'Simpan data aktif dengan format yang siap dibaca ulang',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.successBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.medication_outlined,
                  color: AppTheme.successGreen,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${obatProvider.obatList.length} obat aktif siap diekspor',
                    style: TextStyle(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleExportExcel,
              icon: const Icon(Icons.save_alt_outlined, size: 18),
              label: const Text('Ekspor ke Excel'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Provider.of<AppProvider>(
                context,
                listen: false,
              ).setNavIndex(2),
              icon: const Icon(Icons.medication_outlined, size: 17),
              label: const Text('Buka katalog obat'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'File ekspor berisi kode, nama, kategori, harga beli, harga jual, stok, dan deskripsi.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabasePanel() {
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleExportDatabase,
                icon: const Icon(Icons.download_outlined, size: 17),
                label: const Text('Backup database'),
              ),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _handleImportDatabase,
                icon: const Icon(Icons.restore_outlined, size: 17),
                label: const Text('Restore database'),
              ),
            ],
          );
          final description = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sd_storage_outlined, color: AppTheme.indigo, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup database lokal',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Untuk memindahkan atau memulihkan seluruh data aplikasi.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [description, const SizedBox(height: 12), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: description),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdminPanel() {
    return _Panel(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        leading: Icon(
          Icons.admin_panel_settings_outlined,
          color: AppTheme.dangerRed,
        ),
        title: Text(
          'Area Admin',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          'Peralatan pemeliharaan database untuk pengembangan atau instalasi baru',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.dangerBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: AppTheme.dangerRed.withValues(alpha: 0.25),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    'Reset mengosongkan data operasional satu kali. Aplikasi tidak pernah mereset data saat startup atau pergantian hari.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerRed,
                  ),
                  onPressed: _isProcessing ? null : _handleResetOperationalData,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('Reset Data Operasional'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(
              alpha: AppTheme.isDark ? 0.28 : 0.08,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _PanelTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImportSummary extends StatelessWidget {
  final ImportResult result;

  const _ImportSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.hasErrors
        ? AppTheme.warningOrange
        : AppTheme.successGreen;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            result.hasErrors
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${result.inserted} baru, ${result.updated} diperbarui'
              '${result.archived > 0 ? ', ${result.archived} diarsipkan' : ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
