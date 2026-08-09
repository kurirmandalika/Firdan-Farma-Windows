import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/obat_provider.dart';
import '../../providers/transaksi_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/medical_card.dart';
import '../../widgets/receipt_dialog.dart';
import '../../widgets/custom_badge.dart';

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
        // Refresh obat list stock
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
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 900;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: isCompact
              ? DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: AppTheme.primaryTeal,
                        indicatorColor: AppTheme.primaryTeal,
                        tabs: [
                          Tab(icon: Icon(Icons.medication_outlined), text: 'Katalog Obat'),
                          Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'Keranjang Kasir'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildProductSelector(context, currencyFormatter, width),
                            _buildCartPanel(context, currencyFormatter, txProv: Provider.of<TransaksiProvider>(context)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildProductSelector(context, currencyFormatter, width * 0.6),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: _buildCartPanel(context, currencyFormatter, txProv: Provider.of<TransaksiProvider>(context)),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildProductSelector(BuildContext context, NumberFormat currencyFormatter, double containerWidth) {
    final gridCount = ResponsiveHelper.getObatGridCrossAxisCount(containerWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        MedicalCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari Nama Obat atau Kode Barcode...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              Provider.of<ObatProvider>(context, listen: false).setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    Provider.of<ObatProvider>(context, listen: false).setSearchQuery(val);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Products Grid
        Expanded(
          child: Consumer2<ObatProvider, TransaksiProvider>(
            builder: (context, obatProv, txProv, _) {
              if (obatProv.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal));
              }

              if (obatProv.obatList.isEmpty) {
                return const Center(
                  child: Text('Tidak ada obat ditemukan', style: TextStyle(color: AppTheme.textSecondary)),
                );
              }

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  childAspectRatio: gridCount == 1 ? 2.8 : (gridCount == 2 ? 1.4 : 1.25),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: obatProv.obatList.length,
                itemBuilder: (context, index) {
                  final obat = obatProv.obatList[index];
                  return Material(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: obat.isHabis
                          ? null
                          : () {
                              try {
                                txProv.addToCart(obat);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: AppTheme.warningOrange,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: obat.isHabis ? AppTheme.dangerBg : AppTheme.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    obat.kodeObat,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
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
                            const SizedBox(height: 4),
                            Text(
                              obat.nama,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: obat.isHabis ? AppTheme.textMuted : AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currencyFormatter.format(obat.hargaJual),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: obat.isHabis ? AppTheme.bgLight : AppTheme.primaryTealLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_shopping_cart,
                                    size: 15,
                                    color: obat.isHabis ? AppTheme.textMuted : AppTheme.primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCartPanel(BuildContext context, NumberFormat currencyFormatter, {required TransaksiProvider txProv}) {
    return MedicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryTeal),
                  const SizedBox(width: 8),
                  const Text(
                    'Keranjang Penjualan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  if (txProv.cartItems.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${txProv.totalItemCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              if (txProv.cartItems.isNotEmpty)
                TextButton.icon(
                  onPressed: () => txProv.clearCart(),
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.dangerRed),
                  label: const Text('Kosongkan', style: TextStyle(color: AppTheme.dangerRed, fontSize: 12)),
                ),
            ],
          ),
          const Divider(height: 20),
          // Cart List
          Expanded(
            child: txProv.cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shopping_cart_outlined, size: 44, color: AppTheme.textMuted),
                        SizedBox(height: 10),
                        Text('Keranjang masih kosong', style: TextStyle(color: AppTheme.textMuted)),
                        SizedBox(height: 4),
                        Text('Pilih obat di katalog untuk menambahkan', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: txProv.cartItems.length,
                    separatorBuilder: (context, index) => const Divider(height: 10),
                    itemBuilder: (context, index) {
                      final item = txProv.cartItems[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.obat.nama,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${currencyFormatter.format(item.obat.hargaJual)} / unit',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          // Qty Controls
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppTheme.textSecondary),
                                onPressed: () => txProv.updateItemQuantity(item.obat.id!, -1),
                              ),
                              Text(
                                '${item.jumlah}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 18, color: AppTheme.primaryTeal),
                                onPressed: () {
                                  try {
                                    txProv.updateItemQuantity(item.obat.id!, 1);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currencyFormatter.format(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryTeal),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 16),
          // Totals & Payment Section
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL BELANJA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    currencyFormatter.format(txProv.totalBelanja),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryTeal),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Payment Input
              TextField(
                controller: _bayarController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Uang Pembayaran (Rp)',
                  prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.primaryTeal),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (val) {
                  final doubleVal = double.tryParse(val) ?? 0.0;
                  txProv.setBayar(doubleVal);
                },
              ),
              const SizedBox(height: 8),
              // Preset Cash Money Buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: txProv.totalBelanja > 0 ? () => _onBayarPreset(txProv.totalBelanja, txProv) : null,
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                      child: const Text('Uang Pas', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    ...[10000, 20000, 50000, 100000].map((amt) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: OutlinedButton(
                        onPressed: () => _onBayarPreset(amt.toDouble(), txProv),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                        child: Text(currencyFormatter.format(amt), style: const TextStyle(fontSize: 11)),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kembalian:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  Text(
                    currencyFormatter.format(txProv.kembali),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.emeraldGreen),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: (txProv.cartItems.isEmpty || txProv.bayar < txProv.totalBelanja || txProv.isLoading)
                      ? null
                      : () => _handleCheckout(txProv),
                  icon: txProv.isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.print, size: 18),
                  label: const Text('PROSES & CETAK STRUK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
