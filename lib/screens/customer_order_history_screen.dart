import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../widgets/storefront/customer_checkout_modal.dart';
import 'package:web/web.dart' as web;

class CustomerOrderHistoryScreen extends StatefulWidget {
  const CustomerOrderHistoryScreen({super.key});

  @override
  State<CustomerOrderHistoryScreen> createState() => _CustomerOrderHistoryScreenState();
}

class _CustomerOrderHistoryScreenState extends State<CustomerOrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _contactWhatsAppSupport(OrderModel order, String whatsappNumber) {
    try {
      final text = 'Hi Navodya Spices! I need assistance with my Order #${order.id} (Placed on ${DateFormat('yyyy-MM-dd').format(order.createdAt)}).';
      final cleanWa = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final countryWa = cleanWa.startsWith('0') ? '94${cleanWa.substring(1)}' : cleanWa;
      final url = 'https://wa.me/$countryWa?text=${Uri.encodeComponent(text)}';
      web.window.open(url, '_blank');
    } catch (_) {}
  }

  void _handleReorder(BuildContext context, AppProvider provider, OrderModel order) {
    provider.reorderPastOrder(order);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛒 Items from Order ${order.id} re-added to your Cart!'),
        backgroundColor: AppTheme.cardamomGreen,
        action: SnackBarAction(
          label: 'OPEN CHECKOUT',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const CustomerCheckoutModal(),
            );
          },
        ),
      ),
    );
    showDialog(
      context: context,
      builder: (_) => const CustomerCheckoutModal(),
    );
  }

  void _handleCancelOrder(BuildContext context, AppProvider provider, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Cancel Order?'),
          ],
        ),
        content: Text('Are you sure you want to cancel Order ${order.id}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Order')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.cancelOrder(order.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order ${order.id} has been cancelled.'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Cancel Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');

    // Customer-specific orders stream/list
    final customerOrders = appProvider.customerOrders;

    // Filtered orders
    final orders = customerOrders.where((o) {
      final matchesSearch = o.id.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (o.customerName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
          o.items.any((i) => i.spice.name.toLowerCase().contains(_searchController.text.toLowerCase()));

      bool matchesStatus = true;
      if (_selectedStatusFilter == 'Active') {
        matchesStatus = o.status == 'Pending' || o.status == 'Confirmed' || o.status == 'Processing' || o.status == 'Dispatched';
      } else if (_selectedStatusFilter == 'Delivered') {
        matchesStatus = o.status == 'Delivered' || o.status == 'Completed';
      } else if (_selectedStatusFilter == 'Cancelled') {
        matchesStatus = o.status == 'Cancelled';
      }

      return matchesSearch && matchesStatus;
    }).toList();

    final totalSpent = customerOrders.where((o) => o.status != 'Cancelled').fold(0.0, (sum, o) => sum + o.totalAmount);
    final activeOrdersCount = customerOrders.where((o) => o.status == 'Pending' || o.status == 'Confirmed' || o.status == 'Processing' || o.status == 'Dispatched').length;
    final deliveredOrdersCount = customerOrders.where((o) => o.status == 'Delivered' || o.status == 'Completed').length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Title & Subtitle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history_edu, color: AppTheme.royalGoldPrimary, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'My Order History & Live Tracking',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      'Track current orders live, view past spice purchases & reorder with 1-click.',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.royalGoldPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => appProvider.setNavIndex(0),
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
                  label: const Text('SHOP SPICES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top Customer Order Stats Overview
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 2.2 : 1.6,
                  children: [
                    _buildStatCard(
                      context,
                      title: 'Total Orders',
                      value: '${customerOrders.length}',
                      icon: Icons.shopping_bag_outlined,
                      color: AppTheme.royalGoldPrimary,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Active Orders',
                      value: '$activeOrdersCount',
                      icon: Icons.local_shipping_outlined,
                      color: AppTheme.saffronPrimary,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Delivered',
                      value: '$deliveredOrdersCount',
                      icon: Icons.task_alt,
                      color: AppTheme.cardamomGreen,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Total Spent',
                      value: currencyFormatter.format(totalSpent),
                      icon: Icons.payments_outlined,
                      color: Colors.blueAccent,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Search Bar & Filter Pills
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by Order ID (e.g. ORD-1001) or Spice name...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.royalGoldPrimary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchController.clear()))
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Active', 'Delivered', 'Cancelled'].map((status) {
                          final isSelected = _selectedStatusFilter == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedStatusFilter = status),
                              selectedColor: AppTheme.royalGoldPrimary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : AppTheme.textDark),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Orders List
            if (orders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.royalGoldPrimary),
                    const SizedBox(height: 16),
                    const Text('No Orders Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      customerOrders.isEmpty ? 'You have not placed any spice orders yet.' : 'No orders match your filter criteria.',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(context, appProvider, order, currencyFormatter, dateFormatter);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    AppProvider provider,
    OrderModel order,
    NumberFormat currencyFormatter,
    DateFormat dateFormatter,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCancelled = order.status == 'Cancelled';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCancelled
              ? Colors.red.withValues(alpha: 0.3)
              : AppTheme.royalGoldPrimary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.royalGoldPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt, color: AppTheme.royalGoldPrimary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          dateFormatter.format(order.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const Divider(height: 24),

            // LIVE VISUAL TRACKING STEPPER TIMELINE
            if (!isCancelled) ...[
              Text(
                'LIVE ORDER PROGRESS TRACKER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              _buildLiveOrderTimeline(context, order.statusStepIndex),
              const Divider(height: 24),
            ],

            // ITEMS BREAKDOWN
            Text(
              'ORDERED SPICES (${order.items.length})',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.spice.imageUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 36,
                            height: 36,
                            color: AppTheme.royalGoldPrimary.withValues(alpha: 0.12),
                            child: const Icon(Icons.rice_bowl, size: 18, color: AppTheme.royalGoldPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.spice.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${currencyFormatter.format(item.spice.price)} x ${item.quantity}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormatter.format(item.itemTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.royalGoldPrimary),
                      ),
                    ],
                  ),
                )),

            const Divider(height: 24),

            // FOOTER & ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Method: ${order.paymentMethod}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                      Text('Address: ${order.deliveryAddress}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('Total Paid: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          currencyFormatter.format(order.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.cardamomGreen),
                        ),
                      ],
                    ),
                  ],
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // WhatsApp Track Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        side: const BorderSide(color: AppTheme.whatsappGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _contactWhatsAppSupport(order, provider.whatsappNumber),
                      icon: const Icon(Icons.phone, color: AppTheme.whatsappGreen, size: 14),
                      label: const Text('Help / WA', style: TextStyle(color: AppTheme.whatsappGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),

                    // Cancel Order Button (if Pending)
                    if (order.status == 'Pending')
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _handleCancelOrder(context, provider, order),
                        icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 14),
                        label: const Text('Cancel', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),

                    // 1-Click Reorder Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalGoldPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _handleReorder(context, provider, order),
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 14),
                      label: const Text('REORDER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade800;
        icon = Icons.hourglass_top;
        break;
      case 'confirmed':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade800;
        icon = Icons.thumb_up_alt_outlined;
        break;
      case 'processing':
      case 'packing':
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple.shade800;
        icon = Icons.inventory_2_outlined;
        break;
      case 'dispatched':
      case 'on the way':
        bg = Colors.indigo.withValues(alpha: 0.15);
        fg = Colors.indigo.shade800;
        icon = Icons.local_shipping;
        break;
      case 'delivered':
      case 'completed':
        bg = AppTheme.cardamomGreen.withValues(alpha: 0.15);
        fg = AppTheme.cardamomGreen;
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade800;
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade800;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLiveOrderTimeline(BuildContext context, int currentStep) {
    final steps = ['Placed', 'Confirmed', 'Packing', 'Dispatched', 'Delivered'];

    return Row(
      children: List.generate(steps.length, (i) {
        final isCompleted = i <= currentStep;
        final isCurrent = i == currentStep;
        final color = isCompleted ? AppTheme.cardamomGreen : Colors.grey.shade400;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i <= currentStep ? AppTheme.cardamomGreen : Colors.grey.shade300,
                      ),
                    ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppTheme.cardamomGreen : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? AppTheme.royalGoldPrimary : color,
                        width: isCurrent ? 2.5 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text('${i + 1}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < currentStep ? AppTheme.cardamomGreen : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                steps[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? AppTheme.cardamomGreen : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
