import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/obat_provider.dart';
import '../../services/backup_service.dart';
import '../../services/spreadsheet_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/medical_card.dart';

class BackupExcelScreen extends StatefulWidget {
  const BackupExcelScreen({super.key});

  @override
  State<BackupExcelScreen> createState() => _BackupExcelScreenState();
}

class _BackupExcelScreenState extends State<BackupExcelScreen> {
  final BackupService _backupService = BackupService();
  final SpreadsheetService _spreadsheetService = SpreadsheetService();

  bool _isProcessing = false;

  Future<void> _handleExportDatabase() async {
    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final savedPath = await _backupService.exportDatabase();
      if (savedPath != null && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Backup database berhasil disimpan di: $savedPath'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImportDatabase() async {
    final path = await _backupService.pickBackupFile();
    if (path == null) return;

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final obatProv = Provider.of<ObatProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Restore Database'),
        content: const Text(
          'Restore database akan menimpa seluruh data saat ini dengan data dari file backup. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final success = await _backupService.importDatabase(path);
      if (success && mounted) {
        await obatProv.fetchObat();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Database berhasil dipulihkan dari backup!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal restore: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleExportExcel() async {
    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    final appProv = Provider.of<AppProvider>(context, listen: false);

    try {
      final path = await _spreadsheetService.exportDatabaseToSpreadsheet();
      if (path != null && mounted) {
        appProv.updateSpreadsheetPath(path);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Data obat berhasil diekspor ke Excel: $path'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal ekspor Excel: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImportExcel() async {
    final messenger = ScaffoldMessenger.of(context);
    final appProv = Provider.of<AppProvider>(context, listen: false);
    final obatProv = Provider.of<ObatProvider>(context, listen: false);

    final path = await _spreadsheetService.pickSpreadsheetFile();
    if (path == null) return;

    setState(() => _isProcessing = true);

    try {
      final count = await _spreadsheetService.importSpreadsheetToDb(path);
      if (mounted) {
        appProv.updateSpreadsheetPath(path);
        await obatProv.fetchObat();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil mengimpor/memperbarui $count data obat dari Excel!',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal impor Excel: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRefreshObat() async {
    final messenger = ScaffoldMessenger.of(context);
    final obatProv = Provider.of<ObatProvider>(context, listen: false);

    setState(() => _isProcessing = true);
    try {
      await obatProv.fetchObat();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Data obat berhasil dimuat ulang.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal memuat ulang data obat: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProv, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backup & Integrasi Spreadsheet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kelola file cadangan database lokal (.db) dan ekspor/impor data obat ke Excel (.xlsx)',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_isProcessing) ...[
                    const LinearProgressIndicator(color: AppTheme.primaryTeal),
                    const SizedBox(height: 16),
                  ],

                  if (isCompact)
                    Column(
                      children: [
                        _buildDatabaseBackupBox(),
                        const SizedBox(height: 20),
                        _buildSpreadsheetBox(appProv),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDatabaseBackupBox()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildSpreadsheetBox(appProv)),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatabaseBackupBox() {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.sd_storage_outlined,
                color: AppTheme.primaryTeal,
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                'Backup Database Lokal (.db)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          const Text(
            'Simpan seluruh database obat, transaksi, dan mutasi stok ke dalam file .db yang dapat dibagikan atau dipindahkan ke komputer lain.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleExportDatabase,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Ekspor File Backup Database (.db)'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _handleImportDatabase,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Import / Restore File Database'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpreadsheetBox(AppProvider appProv) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.table_chart_outlined,
                color: AppTheme.emeraldGreen,
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                'Integrasi Spreadsheet Excel (.xlsx)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            appProv.connectedSpreadsheetPath != null
                ? 'Status: Terhubung ke Excel'
                : 'Status: Belum Terhubung',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: appProv.connectedSpreadsheetPath != null
                  ? AppTheme.emeraldGreen
                  : AppTheme.warningOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appProv.connectedSpreadsheetPath ??
                'Pilih file .xlsx untuk sinkronisasi otomatis.',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
              ),
              onPressed: _isProcessing ? null : _handleExportExcel,
              icon: const Icon(Icons.file_download, size: 18),
              label: const Text('Ekspor Katalog Obat ke Excel (.xlsx)'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.emeraldGreen,
                side: const BorderSide(color: AppTheme.emeraldGreen),
              ),
              onPressed: _isProcessing ? null : _handleImportExcel,
              icon: const Icon(Icons.file_upload, size: 18),
              label: const Text('Impor Data Obat dari File Excel'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryTeal,
                side: const BorderSide(color: AppTheme.primaryTeal),
              ),
              onPressed: _isProcessing ? null : _handleRefreshObat,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Muat Ulang Data Obat'),
            ),
          ),
        ],
      ),
    );
  }
}
