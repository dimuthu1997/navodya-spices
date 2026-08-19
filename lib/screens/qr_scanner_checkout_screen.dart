import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class QrScannerCheckoutScreen extends StatefulWidget {
  const QrScannerCheckoutScreen({super.key});

  @override
  State<QrScannerCheckoutScreen> createState() => _QrScannerCheckoutScreenState();
}

class _QrScannerCheckoutScreenState extends State<QrScannerCheckoutScreen> {
  final TextEditingController _qrInputController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');

  @override
  void dispose() {
    _qrInputController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title
            Card(
              elevation: 0,
              color: AppTheme.saffronPrimary.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.saffronPrimary,
                      child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QR Code Direct Item Purchase & Scan',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan spice QR codes or click link parameters to purchase items instantly with prefilled quantity!',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Live Simulator / Tester Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Scan & Link Tester',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Simulate scanning a QR Code or opening direct link: e.g. NAV_SPICE:SPICE001:650:100g or SPICE002',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _qrInputController,
                            decoration: const InputDecoration(
                              hintText: 'Enter Spice ID or QR Payload (e.g. SPICE001)',
                              prefixIcon: Icon(Icons.qr_code),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.saffronPrimary),
                          onPressed: () {
                            final code = _qrInputController.text.trim();
                            final qty = int.tryParse(_qtyController.text.trim()) ?? 1;
                            if (code.isNotEmpty) {
                              appProvider.handleQrCodeScanned(code, qty);
                              _qrInputController.clear();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid Spice ID or payload')),
                              );
                            }
                          },
                          icon: const Icon(Icons.bolt, color: Colors.white),
                          label: const Text('SCAN & BUY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Products QR Codes Catalog Generator Grid
            const Text(
              'Spice QR Codes Catalog (Click any QR to Scan & Buy)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxis = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxis,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: appProvider.products.length,
                  itemBuilder: (context, index) {
                    final spice = appProvider.products[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // QR Code
                            InkWell(
                              onTap: () {
                                appProvider.handleQrCodeScanned(spice.id, 2);
                              },
                              child: QrImageView(
                                data: spice.qrPayload,
                                version: QrVersions.auto,
                                size: 110.0,
                                foregroundColor: AppTheme.saffronPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              spice.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${currencyFormatter.format(spice.price)} / ${spice.unit}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cardamomGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              onPressed: () {
                                appProvider.handleQrCodeScanned(spice.id, 1);
                              },
                              child: const Text('Simulate Scan & Buy', style: TextStyle(fontSize: 11, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),

      // Direct Buy Modal overlay sheet if QR scanned
      bottomSheet: appProvider.showDirectBuyDialog && appProvider.scannedSpiceItem != null
          ? _buildDirectBuyModal(context, appProvider, currencyFormatter)
          : null,
    );
  }

  Widget _buildDirectBuyModal(BuildContext context, AppProvider provider, NumberFormat formatter) {
    final spice = provider.scannedSpiceItem!;
    final total = spice.price * provider.scannedQuantity;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.saffronPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_2, color: AppTheme.saffronPrimary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code Item Scanned!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      'Express Quick Checkout',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => provider.closeDirectBuyDialog(),
              ),
            ],
          ),
          const Divider(height: 24),

          // Scanned Spice Details Card
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  spice.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.saffronPrimary.withOpacity(0.1),
                    child: const Icon(Icons.dry_cleaning, color: AppTheme.saffronPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spice.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (spice.sinhalaName.isNotEmpty)
                      Text(spice.sinhalaName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '${formatter.format(spice.price)} per ${spice.unit}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.saffronPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quantity Adjuster
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Scanned Quantity:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => provider.updateScannedQuantity(-1),
                    ),
                    Text(
                      '${provider.scannedQuantity}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => provider.updateScannedQuantity(1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Price Calculation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.saffronPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Scanned Item Subtotal:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  formatter.format(total),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.saffronPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    provider.addToCart(spice, quantity: provider.scannedQuantity);
                    provider.closeDirectBuyDialog();
                    provider.setNavIndex(0); // Navigate to POS Terminal
                  },
                  child: const Text('Add to POS Cart'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardamomGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    provider.clearCart();
                    provider.addToCart(spice, quantity: provider.scannedQuantity);
                    final order = await provider.processCheckout(paymentMethod: 'QR Payment');
                    if (order != null && context.mounted) {
                      provider.closeDirectBuyDialog();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.cardamomGreen,
                          content: Text('Order ${order.id} purchased successfully via QR link!'),
                        ),
                      );
                    }
                  },
                  child: const Text('BUY NOW (EXPRESS)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
