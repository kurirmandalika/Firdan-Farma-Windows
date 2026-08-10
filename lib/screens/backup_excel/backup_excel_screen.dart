import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/obat_provider.dart';
import '../../services/backup_service.dart';
import '../../services/spreadsheet_service.dart';
import '../../theme/app_theme.dart';

class BackupExcelScreen extends StatefulWidget {
  const BackupExcelScreen({super.key});

  @override
  State<BackupExcelScreen> createState() => _BackupExcelScreenState();
}

class _BackupExcelScreenState extends State<BackupExcelScreen> {
  final BackupService _backupService = BackupService();
  final SpreadsheetService _spreadsheetService = SpreadsheetService();

  bool _isProcessing = false;
  String? _selectedImportFilePath;
  ImportResult? _lastImportResult;

  // ──────────────────────────────────────────────
  // BACKUP DATABASE (.db)
  // ──────────────────────────────────────────────

  Future<void> _handleExportDatabase() async {
    setState(() => _isProcessing = true);
    try {
      final savedPath = await _backupService.exportDatabase();
      if (savedPath != null && mounted) {
        _showSuccess('Backup database berhasil disimpan:\n$savedPath');
      } else if (mounted) {
        _showInfo('Ekspor dibatalkan.');
      }
    } catch (e) {
      if (mounted) _showError('Gagal ekspor database: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImportDatabase() async {
    final path = await _backupService.pickBackupFile();
    if (path == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final obatProv = Provider.of<ObatProvider>(context, listen: false);

    final confirm = await _showConfirmDialog(
      title: 'Konfirmasi Restore Database',
      content:
          'Restore database akan MENIMPA SELURUH data saat ini dengan data dari file backup.\n\nTindakan ini tidak dapat dibatalkan. Lanjutkan?',
      confirmLabel: 'Ya, Restore Sekarang',
      isDanger: true,
    );
    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final success = await _backupService.importDatabase(path);
      if (success && mounted) {
        await obatProv.fetchObat();
        messenger.showSnackBar(SnackBar(
          content: const Text('✅ Database berhasil dipulihkan dari backup!'),
          backgroundColor: AppTheme.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) _showError('Gagal restore: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ──────────────────────────────────────────────
  // EXCEL — EXPORT
  // ──────────────────────────────────────────────

  Future<void> _handleExportExcel() async {
    setState(() => _isProcessing = true);
    final appProv = Provider.of<AppProvider>(context, listen: false);
    try {
      final path = await _spreadsheetService.exportDatabaseToSpreadsheet();
      if (path != null && mounted) {
        appProv.updateSpreadsheetPath(path);
        _showSuccess('Data obat berhasil diekspor ke:\n$path');
      } else if (mounted) {
        _showInfo('Ekspor dibatalkan.');
      }
    } catch (e) {
      if (mounted) _showError('Gagal ekspor Excel: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDownloadTemplate() async {
    setState(() => _isProcessing = true);
    try {
      final path = await _spreadsheetService.downloadTemplateExcel();
      if (path != null && mounted) {
        _showSuccess('Template berhasil disimpan di:\n$path');
      } else if (mounted) {
        _showInfo('Download template dibatalkan.');
      }
    } catch (e) {
      if (mounted) _showError('Gagal download template: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ──────────────────────────────────────────────
  // EXCEL — IMPORT (2 langkah: pilih file → jalankan)
  // ──────────────────────────────────────────────

  Future<void> _handlePickImportFile() async {
    final path = await _spreadsheetService.pickSpreadsheetFile();
    if (path != null && mounted) {
      setState(() {
        _selectedImportFilePath = path;
        _lastImportResult = null;
      });
    }
  }

  Future<void> _handleRunImport() async {
    if (_selectedImportFilePath == null) return;

    final obatProv = Provider.of<ObatProvider>(context, listen: false);
    final appProv = Provider.of<AppProvider>(context, listen: false);

    setState(() {
      _isProcessing = true;
      _lastImportResult = null;
    });

    try {
      final result = await _spreadsheetService.importSpreadsheetToDb(_selectedImportFilePath!);

      if (mounted) {
        appProv.updateSpreadsheetPath(_selectedImportFilePath);
        await obatProv.fetchObat();

        setState(() => _lastImportResult = result);

        // Tampilkan dialog hasil import
        await _showImportResultDialog(result, appProv);
      }
    } catch (e) {
      if (mounted) _showError('Gagal impor Excel: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ──────────────────────────────────────────────
  // DIALOGS & SNACKBARS
  // ──────────────────────────────────────────────

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.successGreen,
      duration: const Duration(seconds: 5),
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.dangerRed,
      duration: const Duration(seconds: 6),
    ));
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.textSecondary,
    ));
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    String confirmLabel = 'Lanjutkan',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppTheme.dangerRed : AppTheme.primaryTeal,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportResultDialog(ImportResult result, AppProvider appProv) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Import Selesai!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ringkasan statistik
            _buildResultStatRow(
              Icons.add_circle_outline,
              AppTheme.successGreen,
              '${result.inserted} obat baru ditambahkan',
            ),
            const SizedBox(height: 8),
            _buildResultStatRow(
              Icons.update,
              AppTheme.primaryTeal,
              '${result.updated} obat diperbarui',
            ),
            if (result.skipped > 0) ...[
              const SizedBox(height: 8),
              _buildResultStatRow(
                Icons.skip_next,
                AppTheme.warningOrange,
                '${result.skipped} baris dilewati (kosong/error)',
              ),
            ],
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const Text(
                'Detail Error:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.dangerRed),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppTheme.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    result.errors.join('\n'),
                    style: const TextStyle(fontSize: 11, color: AppTheme.dangerRed),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (result.total > 0)
              Text(
                'Total ${result.total} data obat berhasil dimuat ke katalog!',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          if (result.total > 0)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                appProv.setNavIndex(2);
              },
              icon: const Icon(Icons.medication_outlined, size: 18),
              label: const Text('Lihat Katalog Obat'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultStatRow(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────

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
                  // ── Page Header ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryTeal.withValues(alpha: 0.15),
                              AppTheme.emeraldGreen.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: AppTheme.primaryTeal, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Backup & Sinkronisasi Data',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Kelola backup database dan ekspor/impor data obat Excel',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        color: AppTheme.primaryTeal,
                        backgroundColor: AppTheme.primaryTealLight,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Sedang memproses, harap tunggu...',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (isCompact)
                    Column(
                      children: [
                        _buildExcelImportCard(),
                        const SizedBox(height: 20),
                        _buildExcelExportCard(appProv),
                        const SizedBox(height: 20),
                        _buildDatabaseBackupCard(),
                      ],
                    )
                  else
                    Column(
                      children: [
                        // Baris atas: Import & Export Excel (berdampingan)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildExcelImportCard()),
                            const SizedBox(width: 20),
                            Expanded(child: _buildExcelExportCard(appProv)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Baris bawah: Database Backup (full width)
                        _buildDatabaseBackupCard(),
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

  // ──────────────────────────────────────────────
  // CARD: Import Excel
  // ──────────────────────────────────────────────

  Widget _buildExcelImportCard() {
    final hasFile = _selectedImportFilePath != null;
    final fileName = hasFile ? _selectedImportFilePath!.split(Platform.pathSeparator).last : null;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _buildCardHeader(
            icon: Icons.upload_file_rounded,
            color: AppTheme.emeraldGreen,
            title: 'Import Data Obat dari Excel',
            subtitle: 'Upload file .xlsx untuk memasukkan data ke katalog',
          ),
          const SizedBox(height: 20),

          // Step 1: Pilih file
          _buildStepLabel('1', 'Pilih File Excel dari Komputer'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isProcessing ? null : _handlePickImportFile,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasFile
                    ? AppTheme.emeraldGreen.withValues(alpha: 0.06)
                    : AppTheme.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasFile ? AppTheme.emeraldGreen : AppTheme.borderLight,
                  width: hasFile ? 1.5 : 1,
                  style: hasFile ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: hasFile
                  ? Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded,
                            color: AppTheme.emeraldGreen, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'File dipilih — klik untuk ganti',
                                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 20),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded,
                            color: AppTheme.textMuted, size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          'Klik untuk memilih file .xlsx',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Step 2: Jalankan import
          _buildStepLabel('2', 'Jalankan Import'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasFile ? AppTheme.emeraldGreen : AppTheme.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (hasFile && !_isProcessing) ? _handleRunImport : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                hasFile ? 'Mulai Import Data Obat' : 'Pilih file dahulu',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),

          // Tampilkan ringkasan hasil import terakhir
          if (_lastImportResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Import selesai: ${_lastImportResult!.inserted} ditambah, ${_lastImportResult!.updated} diperbarui',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Info format Excel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryTealLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.primaryTeal),
                    SizedBox(width: 6),
                    Text(
                      'Format Excel yang Didukung:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Kolom: Kode Obat, Nama Obat, Harga Beli, Harga Jual, Stok Tersedia, Stok Minimal, Deskripsi\n'
                  '• Baris pertama = header (akan dilewati otomatis)\n'
                  '• Kode obat kosong = digenerate otomatis\n'
                  '• Gunakan tombol "Download Template" untuk contoh format',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryTeal, height: 1.6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryTeal,
                side: const BorderSide(color: AppTheme.primaryTeal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isProcessing ? null : _handleDownloadTemplate,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download Template Excel', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // CARD: Export Excel
  // ──────────────────────────────────────────────

  Widget _buildExcelExportCard(AppProvider appProv) {
    return Consumer<ObatProvider>(
      builder: (context, obatProv, _) {
        final jumlahObat = obatProv.obatList.length;
        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(
                icon: Icons.file_download_rounded,
                color: AppTheme.primaryTeal,
                title: 'Ekspor Katalog Obat ke Excel',
                subtitle: 'Unduh seluruh data obat sebagai file .xlsx',
              ),
              const SizedBox(height: 20),

              // Info jumlah obat
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryTeal.withValues(alpha: 0.08),
                      AppTheme.emeraldGreen.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_outlined, color: AppTheme.primaryTeal, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$jumlahObat Obat',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                        const Text(
                          'siap diekspor dari katalog',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tombol ekspor utama
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isProcessing ? null : _handleExportExcel,
                  icon: const Icon(Icons.save_alt_rounded, size: 20),
                  label: const Text(
                    'Ekspor ke Excel (Pilih Lokasi Simpan)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Status spreadsheet terakhir
              if (appProv.connectedSpreadsheetPath != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: AppTheme.successGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Terakhir: ${appProv.connectedSpreadsheetPath!.split(Platform.pathSeparator).last}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.successGreen),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 4),

              // Navigasi ke katalog
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryTeal,
                    side: const BorderSide(color: AppTheme.primaryTeal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => appProv.setNavIndex(2),
                  icon: const Icon(Icons.medication_outlined, size: 16),
                  label: const Text('Lihat Katalog Obat', style: TextStyle(fontSize: 13)),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Info kolom yang diekspor
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.table_chart_outlined, size: 14, color: AppTheme.textSecondary),
                        SizedBox(width: 6),
                        Text(
                          'Kolom yang diekspor:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final col in [
                          'ID', 'Kode Obat', 'Nama Obat', 'Kategori',
                          'Supplier', 'Harga Beli', 'Harga Jual',
                          'Stok Tersedia', 'Stok Minimal', 'Deskripsi'
                        ])
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTealLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              col,
                              style: const TextStyle(fontSize: 10, color: AppTheme.primaryTeal, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
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

  // ──────────────────────────────────────────────
  // CARD: Database Backup
  // ──────────────────────────────────────────────

  Widget _buildDatabaseBackupCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.sd_storage_outlined,
            color: const Color(0xFF6366F1),
            title: 'Backup Database Lokal (.db)',
            subtitle: 'Simpan atau pulihkan seluruh database sistem apotek',
          ),
          const SizedBox(height: 16),
          const Text(
            'Backup menyimpan SEMUA data: obat, transaksi, stok, kategori, dan supplier. '
            'File .db dapat dipindahkan ke komputer lain atau disimpan sebagai arsip.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isProcessing ? null : _handleExportDatabase,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Ekspor Backup (.db)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isProcessing ? null : _handleImportDatabase,
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Restore Database', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warningBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Restore database akan MENIMPA semua data yang ada. Pastikan Anda sudah backup terlebih dahulu!',
                    style: TextStyle(fontSize: 11, color: AppTheme.warningOrange, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SHARED WIDGETS
  // ──────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepLabel(String step, String label) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
