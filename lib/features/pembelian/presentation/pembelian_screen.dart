import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firdan_farma_windows/application/providers/obat_provider.dart';
import 'package:firdan_farma_windows/application/providers/pembelian_provider.dart';
import 'package:firdan_farma_windows/application/providers/stok_provider.dart';
import 'package:firdan_farma_windows/application/providers/supplier_provider.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';
import 'package:firdan_farma_windows/shared/widgets/app_page.dart';
import 'package:firdan_farma_windows/shared/widgets/medical_card.dart';

class PembelianScreen extends StatefulWidget {
  const PembelianScreen({super.key});

  @override
  State<PembelianScreen> createState() => _PembelianScreenState();
}

class _PembelianScreenState extends State<PembelianScreen> {
  final TextEditingController _nomorFakturController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _diskonController = TextEditingController(
    text: '0',
  );

  int? _selectedSupplierId;
  int? _selectedObatId;
  DateTime _tanggal = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObatProvider>(context, listen: false).fetchObat();
      Provider.of<SupplierProvider>(context, listen: false).fetchSupplier();
      Provider.of<PembelianProvider>(context, listen: false).fetchPembelian();
    });
  }

  @override
  void dispose() {
    _nomorFakturController.dispose();
    _catatanController.dispose();
    _diskonController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _tanggal = DateTime(
          picked.year,
          picked.month,
          picked.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );
      });
    }
  }

  void _addSelectedObat() {
    final obatProv = Provider.of<ObatProvider>(context, listen: false);
    final pembelianProv = Provider.of<PembelianProvider>(
      context,
      listen: false,
    );
    final obat = obatProv.obatList
        .where((item) => item.id == _selectedObatId)
        .cast<Obat?>()
        .firstOrNull;
    if (obat == null) return;
    pembelianProv.addToCart(obat);
  }

  Future<void> _savePembelian() async {
    final pembelianProv = Provider.of<PembelianProvider>(
      context,
      listen: false,
    );
    final obatProv = Provider.of<ObatProvider>(context, listen: false);
    final stokProv = Provider.of<StokProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final diskon = double.tryParse(_diskonController.text.trim()) ?? 0;

    try {
      await pembelianProv.savePembelian(
        supplierId: _selectedSupplierId,
        tanggal: _tanggal,
        nomorFaktur: _nomorFakturController.text,
        diskon: diskon,
        catatan: _catatanController.text,
      );
      await obatProv.fetchObat();
      await stokProv.fetchMutasi();
      _nomorFakturController.clear();
      _catatanController.clear();
      _diskonController.text = '0';
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Pembelian berhasil disimpan dan stok bertambah.',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<PembelianProvider, ObatProvider, SupplierProvider>(
      builder: (context, pembelianProv, obatProv, supplierProv, _) {
        final currencyFormatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        final diskon = double.tryParse(_diskonController.text.trim()) ?? 0;
        final total = pembelianProv.subtotal - diskon;

        return AppPage(
          title: 'Pembelian',
          subtitle:
              'Catat obat datang dari supplier agar stok dan harga beli terdokumentasi',
          icon: Icons.shopping_bag_outlined,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1080;
              if (!isWide) {
                return Column(
                  children: [
                    _buildFormPanel(
                      obatProv,
                      supplierProv,
                      pembelianProv,
                      currencyFormatter,
                      total,
                    ),
                    const SizedBox(height: 16),
                    _buildHistoryPanel(pembelianProv, currencyFormatter),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildFormPanel(
                      obatProv,
                      supplierProv,
                      pembelianProv,
                      currencyFormatter,
                      total,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _buildHistoryPanel(pembelianProv, currencyFormatter),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFormPanel(
    ObatProvider obatProv,
    SupplierProvider supplierProv,
    PembelianProvider pembelianProv,
    NumberFormat currencyFormatter,
    double total,
  ) {
    final validSupplier =
        supplierProv.supplierList.any((s) => s.id == _selectedSupplierId)
        ? _selectedSupplierId
        : null;
    final validObat = obatProv.obatList.any((o) => o.id == _selectedObatId)
        ? _selectedObatId
        : null;

    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            icon: Icons.add_shopping_cart_outlined,
            title: 'Pembelian Baru',
            subtitle: 'Setiap item akan menambah stok dan membuat riwayat',
          ),
          const SizedBox(height: 16),
          const Divider(),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 190,
                child: OutlinedButton.icon(
                  onPressed: _pickTanggal,
                  icon: const Icon(Icons.calendar_today_outlined, size: 17),
                  label: Text(DateFormat('dd MMM yyyy').format(_tanggal)),
                ),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<int?>(
                  initialValue: validSupplier,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('- Tanpa Supplier -'),
                    ),
                    ...supplierProv.supplierList.map(
                      (supplier) => DropdownMenuItem<int?>(
                        value: supplier.id,
                        child: Text(
                          supplier.nama,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedSupplierId = value);
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _nomorFakturController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Faktur',
                    hintText: 'Opsional',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: validObat,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Pilih Obat'),
                  items: obatProv.obatList
                      .map(
                        (obat) => DropdownMenuItem<int?>(
                          value: obat.id,
                          child: Text(
                            '${obat.kodeObat} - ${obat.nama}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedObatId = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: validObat == null ? null : _addSelectedObat,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pembelianProv.cartItems.isEmpty)
            const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Belum ada item',
              subtitle: 'Pilih obat lalu tambahkan ke daftar pembelian.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pembelianProv.cartItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = pembelianProv.cartItems[index];
                return _PurchaseItemRow(
                  item: item,
                  currencyFormatter: currencyFormatter,
                  onQtyChanged: (qty) =>
                      pembelianProv.updateQty(item.obat.id!, qty),
                  onHargaChanged: (harga) =>
                      pembelianProv.updateHargaBeli(item.obat.id!, harga),
                  onBatchChanged: (batch) =>
                      pembelianProv.updateBatch(item.obat.id!, batch),
                  onExpiredChanged: (expired) =>
                      pembelianProv.updateExpiredDate(item.obat.id!, expired),
                  onRemove: () => pembelianProv.removeFromCart(item.obat.id!),
                );
              },
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    hintText: 'Opsional',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _diskonController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Diskon'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total ${currencyFormatter.format(total < 0 ? 0 : total)}',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed:
                    pembelianProv.cartItems.isEmpty || pembelianProv.isLoading
                    ? null
                    : _savePembelian,
                icon: pembelianProv.isLoading
                    ? SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Simpan Pembelian'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel(
    PembelianProvider pembelianProv,
    NumberFormat currencyFormatter,
  ) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            icon: Icons.history_outlined,
            title: 'Riwayat Pembelian',
            subtitle: 'Pembelian terbaru ditampilkan dari yang paling baru',
          ),
          const SizedBox(height: 16),
          const Divider(),
          if (pembelianProv.pembelianList.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada pembelian',
              subtitle: 'Riwayat akan tampil setelah pembelian disimpan.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pembelianProv.pembelianList.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final pembelian = pembelianProv.pembelianList[index];
                final tanggal = DateFormat(
                  'dd MMM yyyy, HH:mm',
                ).format(DateTime.parse(pembelian.tanggal));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTealLight,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: AppTheme.primaryTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pembelian.nomorPembelian,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${pembelian.namaSupplier ?? 'Tanpa supplier'} | ${pembelian.items.length} item | $tanggal',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currencyFormatter.format(pembelian.total),
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PurchaseItemRow extends StatefulWidget {
  final PurchaseCartItem item;
  final NumberFormat currencyFormatter;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<double> onHargaChanged;
  final ValueChanged<String?> onBatchChanged;
  final ValueChanged<String?> onExpiredChanged;
  final VoidCallback onRemove;

  const _PurchaseItemRow({
    required this.item,
    required this.currencyFormatter,
    required this.onQtyChanged,
    required this.onHargaChanged,
    required this.onBatchChanged,
    required this.onExpiredChanged,
    required this.onRemove,
  });

  @override
  State<_PurchaseItemRow> createState() => _PurchaseItemRowState();
}

class _PurchaseItemRowState extends State<_PurchaseItemRow> {
  late final TextEditingController _qtyController;
  late final TextEditingController _hargaController;
  late final TextEditingController _batchController;
  late final TextEditingController _expiredController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.item.qty.toString());
    _hargaController = TextEditingController(
      text: widget.item.hargaBeli.toStringAsFixed(0),
    );
    _batchController = TextEditingController(text: widget.item.batchNo ?? '');
    _expiredController = TextEditingController(
      text: widget.item.expiredDate ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _PurchaseItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.qty != widget.item.qty) {
      _qtyController.text = widget.item.qty.toString();
    }
    if (oldWidget.item.hargaBeli != widget.item.hargaBeli) {
      _hargaController.text = widget.item.hargaBeli.toStringAsFixed(0);
    }
    if (oldWidget.item.batchNo != widget.item.batchNo) {
      _batchController.text = widget.item.batchNo ?? '';
    }
    if (oldWidget.item.expiredDate != widget.item.expiredDate) {
      _expiredController.text = widget.item.expiredDate ?? '';
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _hargaController.dispose();
    _batchController.dispose();
    _expiredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.obat.nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${widget.item.obat.kodeObat} | ${widget.item.obat.satuan}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          );

          final controls = Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 76,
                child: TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (value) {
                    final qty = int.tryParse(value) ?? 0;
                    widget.onQtyChanged(qty);
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 124,
                child: TextField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'HB'),
                  onChanged: (value) {
                    final harga = double.tryParse(value) ?? 0;
                    widget.onHargaChanged(harga);
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 118,
                child: TextField(
                  controller: _batchController,
                  decoration: const InputDecoration(labelText: 'No Batch'),
                  onChanged: widget.onBatchChanged,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 118,
                child: TextField(
                  controller: _expiredController,
                  decoration: const InputDecoration(
                    labelText: 'Expired (YYYY-MM-DD)',
                  ),
                  onChanged: (value) => widget.onExpiredChanged(
                    value.trim().isEmpty ? null : value.trim(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 112,
                child: Text(
                  widget.currencyFormatter.format(widget.item.subtotal),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hapus item',
                onPressed: widget.onRemove,
                icon: Icon(Icons.delete_outline, color: AppTheme.dangerRed),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 10), controls],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: identity),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: controls),
            ],
          );
        },
      ),
    );
  }
}
