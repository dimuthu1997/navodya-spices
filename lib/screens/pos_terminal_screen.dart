import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/spice_item.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';

class PosTerminalScreen extends StatefulWidget {
  const PosTerminalScreen({super.key});

  @override
  State<PosTerminalScreen> createState() => _PosTerminalScreenState();
}

class _PosTerminalScreenState extends State<PosTerminalScreen> {
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';

  @override
  void dispose() {
    _customerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: Row(
        children: [
          // Product Catalog & Filter Panel
          Expanded(
            flex: isDesktop ? 3 : 2,
            child: Column(
              children: [
                // Top Search & Category Filter Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => appProvider.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Search spice by name, ID or Sinhala name...',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.saffronPrimary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    appProvider.setSearchQuery('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.light
                              ? AppTheme.bgCreamParchment
                              : AppTheme.darkBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category Horizontal Scroll List
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: appProvider.categories.length,
                          itemBuilder: (context, index) {
                            final cat = appProvider.categories[index];
                            final isSelected = cat == appProvider.selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                showCheckmark: false,
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: AppTheme.saffronPrimary,
                                backgroundColor: Theme.of(context).brightness == Brightness.light
                                    ? Colors.grey.shade200
                                    : AppTheme.darkCard,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) => appProvider.setCategory(cat),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Spice Products Grid
                Expanded(
                  child: appProvider.filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.no_meals_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No spices found in catalog',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isDesktop ? 3 : 2,
                            childAspectRatio: 0.82,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: appProvider.filteredProducts.length,
                          itemBuilder: (context, index) {
                            final item = appProvider.filteredProducts[index];
                            return _buildSpiceProductCard(context, item, appProvider, currencyFormatter);
                          },
                        ),
                ),
              ],
            ),
          ),

          // POS Cart & Billing Panel (Right Side for Desktop)
          if (isDesktop)
            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(-2, 0),
                  )
                ],
              ),
              child: _buildCartBillingPanel(context, appProvider, currencyFormatter),
            ),
        ],
      ),

      // Mobile / Tablet Floating Cart Sheet Button
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.saffronPrimary,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).cardColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.85,
                    child: _buildCartBillingPanel(context, appProvider, currencyFormatter),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_bag, color: Colors.white),
              label: Text(
                'Cart (${appProvider.cart.length}) - ${currencyFormatter.format(appProvider.grandTotal)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildSpiceProductCard(
    BuildContext context,
    SpiceItem item,
    AppProvider provider,
    NumberFormat formatter,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => provider.addToCart(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badge
            Expanded(
              child: Stack(
                children: [
                  Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.saffronPrimary.withOpacity(0.1),
                      child: const Center(
                        child: Icon(Icons.dry_cleaning, size: 48, color: AppTheme.saffronPrimary),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.unit,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (item.isPopular)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.turmericGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'HOT',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Item Information
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (item.sinhalaName.isNotEmpty)
                    Text(
                      item.sinhalaName,
                      maxLines: 1,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatter.format(item.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.saffronPrimary,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.saffronPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBillingPanel(
    BuildContext context,
    AppProvider provider,
    NumberFormat formatter,
  ) {
    return Column(
      children: [
        // Cart Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.saffronPrimary.withOpacity(0.08),
            border: const Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: AppTheme.saffronPrimary),
              const SizedBox(width: 10),
              const Text(
                'POS Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (provider.cart.isNotEmpty)
                IconButton(
                  tooltip: 'Clear Cart',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => provider.clearCart(),
                ),
            ],
          ),
        ),

        // Customer Name Input
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _customerController,
            decoration: const InputDecoration(
              hintText: 'Customer Name (Optional)',
              prefixIcon: Icon(Icons.person_outline, size: 20),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // Cart Items List
        Expanded(
          child: provider.cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Cart is empty',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click spices on catalog to add to bill',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: provider.cart.length,
                  separatorBuilder: (context, index) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final cartItem = provider.cart[index];
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cartItem.spice.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '${formatter.format(cartItem.spice.price)} / ${cartItem.spice.unit}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),

                        // Quantity Control Buttons
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => provider.updateCartQuantity(cartItem.spice, -1),
                            ),
                            Text(
                              '${cartItem.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () => provider.updateCartQuantity(cartItem.spice, 1),
                            ),
                          ],
                        ),

                        // Item Total
                        Text(
                          formatter.format(cartItem.itemTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    );
                  },
                ),
        ),

        // Billing Footer Details
        if (provider.cart.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Column(
              children: [
                // Quick Discounts
                Row(
                  children: [
                    const Text('Discount:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 4,
                      children: [0.0, 5.0, 10.0, 15.0].map((pct) {
                        final isSel = provider.discountPercent == pct;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text('${pct.toInt()}%'),
                          selected: isSel,
                          selectedColor: AppTheme.turmericGold,
                          onSelected: (_) => provider.setDiscountPercent(pct),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment Method Selector
                Row(
                  children: [
                    const Text('Payment:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPaymentMethod,
                        isDense: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: ['Cash', 'Card', 'QR Payment']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPaymentMethod = val);
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Subtotal & Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text(formatter.format(provider.subtotal)),
                  ],
                ),
                if (provider.discountAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount:', style: TextStyle(color: Colors.green)),
                      Text('- ${formatter.format(provider.discountAmount)}', style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL PAYABLE:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      formatter.format(provider.grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppTheme.saffronPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Complete Sale Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cardamomGreen,
                    ),
                    onPressed: () async {
                      final order = await provider.processCheckout(
                        paymentMethod: _selectedPaymentMethod,
                        customerName: _customerController.text.trim().isNotEmpty
                            ? _customerController.text.trim()
                            : null,
                      );
                      if (order != null && context.mounted) {
                        _customerController.clear();
                        _showReceiptModal(context, order, formatter);
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text('COMPLETE SALE & PRINT RECEIPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showReceiptModal(BuildContext context, OrderModel order, NumberFormat formatter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Column(
            children: [
              Icon(Icons.verified, size: 48, color: AppTheme.cardamomGreen),
              SizedBox(height: 8),
              Text('NAVODYA SPICES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              Text('Point of Sale Receipt', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)}'),
                if (order.customerName != null) Text('Customer: ${order.customerName}'),
                Text('Payment: ${order.paymentMethod}'),
                const Divider(),
                const Text('Items Purchased:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...order.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${i.spice.name} x${i.quantity}')),
                          Text(formatter.format(i.itemTotal)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(formatter.format(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.saffronPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Thank you for buying Navodya Spices!',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.saffronPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt sent to printer simulation.')),
              );
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('Print Receipt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
