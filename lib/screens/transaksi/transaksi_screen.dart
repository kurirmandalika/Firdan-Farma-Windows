import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/obat_provider.dart';
import '../../providers/transaksi_provider.dart';
import '../../theme/app_theme.dart';
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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Product Selector
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Search Bar
                MedicalCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari Nama Obat atau Scan Kode Barcode...',
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
                const SizedBox(height: 16),
                // Products Grid/List
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
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: obatProv.obatList.length,
                        itemBuilder: (context, index) {
                          final obat = obatProv.obatList[index];
                          return Material(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
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
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
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
                                        fontSize: 14,
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
                                            fontSize: 14,
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
                                            size: 16,
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
            ),
          ),

          const SizedBox(width: 24),

          // Right Side: Active Cart & Checkout
          Expanded(
            flex: 4,
            child: MedicalCard(
              child: Consumer<TransaksiProvider>(
                builder: (context, txProv, _) {
                  return Column(
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
                                    Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.textMuted),
                                    SizedBox(height: 12),
                                    Text('Keranjang masih kosong', style: TextStyle(color: AppTheme.textMuted)),
                                    SizedBox(height: 4),
                                    Text('Pilih obat di sebelah kiri untuk menambahkan', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: txProv.cartItems.length,
                                separatorBuilder: (_, __) => const Divider(height: 12),
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
                                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.textSecondary),
                                            onPressed: () => txProv.updateItemQuantity(item.obat.id!, -1),
                                          ),
                                          Text(
                                            '${item.jumlah}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primaryTeal),
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
                                      const SizedBox(width: 8),
                                      Text(
                                        currencyFormatter.format(item.subtotal),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 20),
                      // Totals & Payment Section
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL BELANJA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                currencyFormatter.format(txProv.totalBelanja),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryTeal),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Payment Input & Quick Money Buttons
                          TextField(
                            controller: _bayarController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Uang Pembayaran (Rp)',
                              prefixIcon: Icon(Icons.payments_outlined, color: AppTheme.primaryTeal),
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
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  child: const Text('Uang Pas', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 6),
                                ...[10000, 20000, 50000, 100000].map((amt) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: OutlinedButton(
                                    onPressed: () => _onBayarPreset(amt.toDouble(), txProv),
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                    child: Text(currencyFormatter.format(amt), style: const TextStyle(fontSize: 11)),
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kembalian:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                              Text(
                                currencyFormatter.format(txProv.kembali),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.emeraldGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryTeal,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: (txProv.cartItems.isEmpty || txProv.bayar < txProv.totalBelanja || txProv.isLoading)
                                  ? null
                                  : () => _handleCheckout(txProv),
                              icon: txProv.isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.print, size: 20),
                              label: const Text('PROSES & CETAK STRUK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
