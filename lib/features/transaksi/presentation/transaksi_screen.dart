import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firdan_farma_windows/data/models/obat_model.dart';
import 'package:firdan_farma_windows/application/providers/obat_provider.dart';
import 'package:firdan_farma_windows/application/providers/transaksi_provider.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/core/utils/responsive_helper.dart';
import 'package:firdan_farma_windows/shared/widgets/app_page.dart';
import 'package:firdan_farma_windows/shared/widgets/custom_badge.dart';
import 'package:firdan_farma_windows/shared/widgets/medical_card.dart';
import 'package:firdan_farma_windows/shared/widgets/receipt_dialog.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _bayarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObatProvider>(context, listen: false).fetchObat();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bayarController.dispose();
    super.dispose();
  }

  void _onBayarPreset(double amount, TransaksiProvider txProv) {
    txProv.setBayar(amount);
    _bayarController.text = amount.toStringAsFixed(0);
  }

  Future<void> _handleCheckout(TransaksiProvider txProv) async {
    try {
      final tx = await txProv.processCheckout();
      _bayarController.clear();
      if (tx != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => ReceiptDialog(transaksi: tx),
        );
        Provider.of<ObatProvider>(context, listen: false).fetchObat();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppPageHeader(
            title: 'Kasir Penjualan',
            subtitle: 'Pilih obat, cek stok, dan proses pembayaran tunai',
            icon: Icons.point_of_sale,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isCompact = width < 900;

                if (isCompact) {
                  return DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: TabBar(
                            labelColor: AppTheme.primaryTeal,
                            unselectedLabelColor: AppTheme.textSecondary,
                            indicatorColor: AppTheme.primaryTeal,
                            tabs: [
                              Tab(
                                icon: Icon(Icons.medication_outlined),
                                text: 'Katalog',
                              ),
                              Tab(
                                icon: Icon(Icons.shopping_cart_outlined),
                                text: 'Keranjang',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildProductSelector(
                                context,
                                currencyFormatter,
                                width,
                              ),
                              _buildCartPanel(context, currencyFormatter),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildProductSelector(
                        context,
                        currencyFormatter,
                        width * 0.58,
                      ),
                    ),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: width < 1180 ? 390 : 430,
                      child: _buildCartPanel(context, currencyFormatter),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector(
    BuildContext context,
    NumberFormat currencyFormatter,
    double containerWidth,
  ) {
    final gridCount = ResponsiveHelper.getObatGridCrossAxisCount(
      containerWidth,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MedicalCard(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama obat atau kode',
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryTeal),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(_searchController.clear);
                        Provider.of<ObatProvider>(
                          context,
                          listen: false,
                        ).setSearchQuery('');
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              setState(() {});
              Provider.of<ObatProvider>(
                context,
                listen: false,
              ).setSearchQuery(val);
            },
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Consumer<ObatProvider>(
            builder: (context, obatProv, _) {
              if (obatProv.isLoading && obatProv.obatList.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                );
              }

              if (obatProv.obatList.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off,
                  title: 'Obat tidak ditemukan',
                  subtitle: 'Coba kata kunci lain atau periksa katalog obat.',
                );
              }

              return Column(
                children: [
                  if (obatProv.isLoading)
                    LinearProgressIndicator(
                      minHeight: 3,
                      color: AppTheme.primaryTeal,
                      backgroundColor: AppTheme.primaryTealLight,
                    ),
                  Expanded(
                    child: GridView.builder(
                      cacheExtent: 700,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCount,
                        childAspectRatio: gridCount == 1
                            ? 2.75
                            : (gridCount == 2 ? 1.45 : 1.25),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: obatProv.obatList.length,
                      itemBuilder: (context, index) {
                        final obat = obatProv.obatList[index];
                        return _ProductTile(
                          obat: obat,
                          currencyFormatter: currencyFormatter,
                          onTap: obat.isHabis
                              ? null
                              : () {
                                  try {
                                    Provider.of<TransaksiProvider>(
                                      context,
                                      listen: false,
                                    ).addToCart(obat);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                        backgroundColor: AppTheme.warningOrange,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCartPanel(BuildContext context, NumberFormat currencyFormatter) {
    return Consumer<TransaksiProvider>(
      builder: (context, txProv, _) {
        return MedicalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                icon: Icons.shopping_cart_outlined,
                title: 'Keranjang',
                subtitle: txProv.cartItems.isEmpty
                    ? 'Belum ada item penjualan'
                    : '${txProv.totalItemCount} item dalam transaksi ini',
                trailing: txProv.cartItems.isNotEmpty
                    ? TextButton.icon(
                        onPressed: () {
                          txProv.clearCart();
                          _bayarController.clear();
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppTheme.dangerRed,
                        ),
                        label: Text(
                          'Kosongkan',
                          style: TextStyle(
                            color: AppTheme.dangerRed,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              const Divider(),
              Expanded(
                child: txProv.cartItems.isEmpty
                    ? const EmptyState(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Keranjang kosong',
                        subtitle:
                            'Pilih obat dari katalog untuk mulai transaksi.',
                      )
                    : ListView.separated(
                        itemCount: txProv.cartItems.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = txProv.cartItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.obat.nama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${currencyFormatter.format(item.obat.hargaJual)} / unit',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _QuantityStepper(
                                  value: item.jumlah,
                                  onDecrease: () => txProv.updateItemQuantity(
                                    item.obat.id!,
                                    -1,
                                  ),
                                  onIncrease: () {
                                    try {
                                      txProv.updateItemQuantity(
                                        item.obat.id!,
                                        1,
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceAll(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 92,
                                  child: Text(
                                    currencyFormatter.format(item.subtotal),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: AppTheme.primaryTeal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(),
              _PaymentPanel(
                txProv: txProv,
                bayarController: _bayarController,
                currencyFormatter: currencyFormatter,
                onPreset: _onBayarPreset,
                onCheckout: () => _handleCheckout(txProv),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Obat obat;
  final NumberFormat currencyFormatter;
  final VoidCallback? onTap;

  const _ProductTile({
    required this.obat,
    required this.currencyFormatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Material(
      color: disabled ? AppTheme.bgLight : AppTheme.cardBg,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: disabled ? AppTheme.dangerBg : AppTheme.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      obat.kodeObat,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (obat.isHabis)
                    CustomBadge.danger('Habis')
                  else if (obat.isStokMenipis)
                    CustomBadge.warning('Stok ${obat.stokTersedia}')
                  else
                    CustomBadge.success('Stok ${obat.stokTersedia}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                obat.nama,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: disabled ? AppTheme.textMuted : AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      currencyFormatter.format(obat.hargaJual),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryTeal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: disabled
                          ? AppTheme.borderLight
                          : AppTheme.primaryTealLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      Icons.add_shopping_cart,
                      size: 16,
                      color: disabled
                          ? AppTheme.textMuted
                          : AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.bgSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.remove, size: 16, color: AppTheme.textSecondary),
            onPressed: onDecrease,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add, size: 16, color: AppTheme.primaryTeal),
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _PaymentPanel extends StatelessWidget {
  final TransaksiProvider txProv;
  final TextEditingController bayarController;
  final NumberFormat currencyFormatter;
  final void Function(double amount, TransaksiProvider txProv) onPreset;
  final VoidCallback onCheckout;

  const _PaymentPanel({
    required this.txProv,
    required this.bayarController,
    required this.currencyFormatter,
    required this.onPreset,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final canCheckout =
        txProv.cartItems.isNotEmpty &&
        (txProv.metodePembayaran != 'TUNAI' ||
            txProv.bayar >= txProv.totalBelanja) &&
        !txProv.isLoading;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Belanja',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            Flexible(
              child: Text(
                currencyFormatter.format(txProv.totalBelanja),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.primaryTeal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: txProv.metodePembayaran,
          decoration: InputDecoration(
            labelText: 'Metode Pembayaran',
            prefixIcon: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppTheme.primaryTeal,
            ),
          ),
          items: TransaksiProvider.paymentMethods
              .map(
                (method) => DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            txProv.setMetodePembayaran(value);
            if (value != 'TUNAI') {
              bayarController.text = txProv.totalBelanja.toStringAsFixed(0);
            }
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: bayarController,
          enabled: txProv.metodePembayaran == 'TUNAI',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: txProv.metodePembayaran == 'TUNAI'
                ? 'Uang Pembayaran (Rp)'
                : 'Nominal otomatis mengikuti total',
            prefixIcon: Icon(
              Icons.payments_outlined,
              color: AppTheme.primaryTeal,
            ),
          ),
          onChanged: (val) {
            final doubleVal = double.tryParse(val) ?? 0.0;
            txProv.setBayar(doubleVal);
          },
        ),
        if (txProv.metodePembayaran == 'TUNAI') ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: txProv.totalBelanja > 0
                      ? () => onPreset(txProv.totalBelanja, txProv)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                  ),
                  child: const Text('Uang Pas', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 6),
                ...[10000, 20000, 50000, 100000].map(
                  (amt) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: OutlinedButton(
                      onPressed: () => onPreset(amt.toDouble(), txProv),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                      ),
                      child: Text(
                        currencyFormatter.format(amt),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kembalian',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            Flexible(
              child: Text(
                currencyFormatter.format(txProv.kembali),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppTheme.emeraldGreen,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: canCheckout ? onCheckout : null,
            icon: txProv.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text(
              'Proses Transaksi',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
