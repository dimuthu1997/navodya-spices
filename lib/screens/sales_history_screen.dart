import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import 'customer_order_history_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _paymentFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    // If user is a customer, show customer-centric Order History screen
    if (appProvider.isCustomer) {
      return const CustomerOrderHistoryScreen();
    }

    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

    // Filter calculations for POS/Admin
    final orders = appProvider.orders.where((o) {
      final matchesSearch = o.id.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (o.customerName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
      final matchesPayment = _paymentFilter == 'All' || o.paymentMethod == _paymentFilter;
      return matchesSearch && matchesPayment;
    }).toList();

    final totalRevenue = orders.where((o) => o.status != 'Cancelled').fold(0.0, (sum, o) => sum + o.totalAmount);
    final avgRevenue = orders.isNotEmpty ? totalRevenue / orders.length : 0.0;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Analytics Metrics Header Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.8 : 1.1,
                  children: [
                    _buildMetricCard(
                      context,
                      title: 'Total Sales Revenue',
                      value: currencyFormatter.format(totalRevenue),
                      icon: Icons.account_balance_wallet,
                      color: AppTheme.cardamomGreen,
                    ),
                    _buildMetricCard(
                      context,
                      title: 'Total Orders Placed',
                      value: '${orders.length}',
                      icon: Icons.shopping_bag_outlined,
                      color: AppTheme.saffronPrimary,
                    ),
                    _buildMetricCard(
                      context,
                      title: 'Avg Order Value',
                      value: currencyFormatter.format(avgRevenue),
                      icon: Icons.trending_up,
                      color: AppTheme.turmericGold,
                    ),
                    _buildMetricCard(
                      context,
                      title: 'QR & Online Sales',
                      value: '${orders.where((o) => o.paymentMethod == "QR Payment" || o.paymentMethod == "Card Direct").length}',
                      icon: Icons.qr_code,
                      color: Colors.blueAccent,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Search & Payment Filter Bar
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search order by ID, Customer...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _paymentFilter,
                      items: ['All', 'Cash on Delivery', 'Card Direct', 'Bank Transfer', 'WhatsApp Direct', 'QR Payment']
                          .map((m) => DropdownMenuItem(value: m, child: Text('Payment: $m')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentFilter = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sales Orders History Table / List
            const Text(
              'Store Order Management & Fulfillment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            orders.isEmpty
                ? Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'No Order Records Found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.royalGoldPrimary.withValues(alpha: 0.15),
                            child: const Icon(Icons.receipt, color: AppTheme.royalGoldPrimary),
                          ),
                          title: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                order.id,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardamomGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  order.status,
                                  style: const TextStyle(
                                    color: AppTheme.cardamomGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${dateFormatter.format(order.createdAt)} • ${order.paymentMethod}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          trailing: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currencyFormatter.format(order.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.saffronPrimary,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  // Update Status Dropdown for Admin
                                  Row(
                                    children: [
                                      const Text('Update Live Firebase Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 10),
                                      DropdownButton<String>(
                                        value: ['Pending', 'Confirmed', 'Processing', 'Dispatched', 'Delivered', 'Cancelled'].contains(order.status)
                                            ? order.status
                                            : 'Pending',
                                        items: ['Pending', 'Confirmed', 'Processing', 'Dispatched', 'Delivered', 'Cancelled']
                                            .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                                            .toList(),
                                        onChanged: (newStatus) {
                                          if (newStatus != null) {
                                            appProvider.updateOrderStatus(order.id, newStatus);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                                    Text('Delivery Address: ${order.deliveryAddress} ${order.city != null ? "(${order.city})" : ""}'),
                                  if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                                    Text('Contact Phone: ${order.customerPhone}'),
                                  const SizedBox(height: 10),
                                  const Text('Items Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ...order.items.map((i) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('• ${i.spice.name} (${i.spice.unit}) x${i.quantity}'),
                                            Text(currencyFormatter.format(i.itemTotal)),
                                          ],
                                        ),
                                      )),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        _showReceiptModal(context, order, currencyFormatter);
                                      },
                                      icon: const Icon(Icons.print, size: 16),
                                      label: const Text('Reprint Receipt'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptModal(BuildContext context, OrderModel order, NumberFormat formatter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text('NAVODYA SPICES - RECEIPT', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order ID: ${order.id}'),
              Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)}'),
              Text('Payment: ${order.paymentMethod}'),
              if (order.customerName != null) Text('Customer: ${order.customerName}'),
              const Divider(),
              ...order.items.map((i) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${i.spice.name} x${i.quantity}'),
                      Text(formatter.format(i.itemTotal)),
                    ],
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Paid:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatter.format(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.saffronPrimary)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
