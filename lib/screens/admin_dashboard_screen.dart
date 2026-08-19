import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import '../providers/app_provider.dart';
import '../models/spice_item.dart';
import '../models/banner_model.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Trigger web CSV download directly in browser
  void _downloadCsv(BuildContext context, AppProvider provider) {
    try {
      final csvData = provider.generateCsvReportContent();
      final bytes = utf8.encode(csvData);
      final base64Str = base64Encode(bytes);
      final url = 'data:text/csv;charset=utf-8;base64,$base64Str';

      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = 'Navodya_Spices_Sales_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();

      NotificationService.showInAppAlert(
        context,
        title: 'CSV Report Downloaded',
        message: 'Sales report spreadsheet saved to downloads.',
        icon: Icons.check_circle,
        color: AppTheme.cardamomGreen,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV export note: $e')),
      );
    }
  }

  void _confirmClearDummyData(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear All Dummy Data?'),
          ],
        ),
        content: const Text(
          'This will remove all sample spices, banners, and sample orders so you can add your own real products from scratch.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.clearSampleData();
              Navigator.pop(ctx);
              NotificationService.showInAppAlert(
                context,
                title: 'Sample Data Cleared',
                message: 'You can now add your real spice catalog, prices, and banners.',
                icon: Icons.delete_sweep,
                color: Colors.orange,
              );
            },
            child: const Text('Clear All Dummy Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Web File Picker helper converting selected local image (JPG/PNG) to Data URL
  void _pickLocalImageFile(Function(String) onLoaded) {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = 'image/png, image/jpeg, image/jpg, image/webp';
    input.click();
    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.length > 0) {
        final file = files.item(0)!;
        final reader = web.FileReader();
        reader.readAsDataURL(file);
        reader.onLoadEnd.listen((e) {
          final result = reader.result;
          if (result != null) {
            onLoaded(result.toString());
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.royalGoldPrimary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.royalGoldPrimary,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'KPI Overview'),
              Tab(icon: Icon(Icons.inventory_outlined), text: 'Spice Catalog & Pricing'),
              Tab(icon: Icon(Icons.view_carousel_outlined), text: 'Promotional Banners'),
              Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Order Fulfillment'),
              Tab(icon: Icon(Icons.assessment_outlined), text: 'Reports & Export'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKpiOverviewTab(context, appProvider, currencyFormatter),
          _buildProductCatalogManagerTab(context, appProvider, currencyFormatter),
          _buildBannerManagerTab(context, appProvider),
          _buildOrderFulfillmentTab(context, appProvider, currencyFormatter),
          _buildReportsExportTab(context, appProvider, currencyFormatter),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: KPI OVERVIEW DASHBOARD
  // ---------------------------------------------------------------------------
  Widget _buildKpiOverviewTab(BuildContext context, AppProvider provider, NumberFormat formatter) {
    final totalRevenue = provider.orders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final totalOrders = provider.orders.length;
    final totalProducts = provider.products.length;
    final lowStockItems = provider.products.where((p) => p.stock < 50).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Admin Welcome Bar with Transparent Logo
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.royalGoldPrimary, AppTheme.royalGoldAccent, AppTheme.cinnamonBronze],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.royalGoldPrimary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.dry_cleaning, size: 50, color: AppTheme.royalGoldPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navodya Spices Executive Panel',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'නාවෝද්‍යා කුළුබඩු • Royal Golden Elephant Brand Portal • WHATSAPP: 0702308303',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.royalGoldPrimary,
                  ),
                  onPressed: () => _downloadCsv(context, provider),
                  icon: const Icon(Icons.download),
                  label: const Text('Export Sales CSV'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // KPI Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxis = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxis,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard(
                    title: 'Gross Revenue',
                    value: formatter.format(totalRevenue),
                    icon: Icons.monetization_on,
                    color: AppTheme.cardamomGreen,
                    badgeText: '+14.2% this month',
                  ),
                  _buildStatCard(
                    title: 'Completed Orders',
                    value: '$totalOrders orders',
                    icon: Icons.shopping_bag,
                    color: AppTheme.royalGoldPrimary,
                    badgeText: 'Live Sync Active',
                  ),
                  _buildStatCard(
                    title: 'Spice Catalog Items',
                    value: '$totalProducts Spices',
                    icon: Icons.dry_cleaning,
                    color: AppTheme.royalGoldAccent,
                    badgeText: 'Active Stock',
                  ),
                  _buildStatCard(
                    title: 'Low Stock Alerts',
                    value: '$lowStockItems items',
                    icon: Icons.warning_amber_rounded,
                    color: lowStockItems > 0 ? Colors.redAccent : Colors.grey,
                    badgeText: lowStockItems > 0 ? 'Requires Restock' : 'Stock Healthy',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Quick Action Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Admin Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _confirmClearDummyData(context, provider),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear All Sample Data'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.add_circle,
                  label: 'Add New Spice',
                  color: AppTheme.royalGoldPrimary,
                  onTap: () => _showAddEditSpiceDialog(context, provider),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.add_photo_alternate,
                  label: 'Create Hero Banner',
                  color: AppTheme.royalGoldAccent,
                  onTap: () => _showAddEditBannerDialog(context, provider),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.file_download,
                  label: 'Download CSV Report',
                  color: AppTheme.cardamomGreen,
                  onTap: () => _downloadCsv(context, provider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String badgeText,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 22),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: SPICE CATALOG & PRICING MANAGER
  // ---------------------------------------------------------------------------
  Widget _buildProductCatalogManagerTab(BuildContext context, AppProvider provider, NumberFormat formatter) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.royalGoldPrimary,
        onPressed: () => _showAddEditSpiceDialog(context, provider),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Spice Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spice Products & Prices Manager', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Edit images, descriptions, prices, units, and stock quantities in real time.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    if (provider.products.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () => _confirmClearDummyData(context, provider),
                        icon: const Icon(Icons.delete_sweep, size: 16),
                        label: const Text('Clear Sample Spices'),
                      ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('${provider.products.length} Spices'),
                      backgroundColor: AppTheme.royalGoldPrimary.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            provider.products.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No spice products in store.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Click "Add Spice Product" to add your real products with local images (JPG/PNG) and prices.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGoldPrimary),
                              onPressed: () => _showAddEditSpiceDialog(context, provider),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Add Real Spice Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Image', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ID & Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Price (LKR)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Unit Size', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Stock Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: provider.products.map((spice) {
                          final isLowStock = spice.stock < 50;
                          return DataRow(
                            cells: [
                              DataCell(
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    spice.imageUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 44,
                                      height: 44,
                                      color: AppTheme.royalGoldPrimary.withValues(alpha: 0.1),
                                      child: const Icon(Icons.dry_cleaning, size: 24, color: AppTheme.royalGoldPrimary),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(spice.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${spice.id} • ${spice.sinhalaName}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              DataCell(Chip(label: Text(spice.category, style: const TextStyle(fontSize: 11)))),
                              DataCell(
                                Text(
                                  formatter.format(spice.price),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.royalGoldPrimary),
                                ),
                              ),
                              DataCell(Text(spice.unit)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLowStock ? Colors.red.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${spice.stock} units',
                                    style: TextStyle(color: isLowStock ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit Spice',
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showAddEditSpiceDialog(context, provider, spice),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete Spice',
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _confirmDeleteSpice(context, provider, spice),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: PROMOTIONAL BANNERS & OFFER MANAGER
  // ---------------------------------------------------------------------------
  Widget _buildBannerManagerTab(BuildContext context, AppProvider provider) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.royalGoldAccent,
        onPressed: () => _showAddEditBannerDialog(context, provider),
        icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
        label: const Text('Add Promotional Banner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Homepage Hero Banners & Campaign Offers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Manage store carousel banners, seasonal discount codes, and campaign text.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),

            provider.banners.isEmpty
                ? const Card(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No promotional banners configured.'))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.banners.length,
                    itemBuilder: (context, index) {
                      final banner = provider.banners[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(banner.imageUrl),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppTheme.royalGoldAccent, borderRadius: BorderRadius.circular(12)),
                                    child: Text(banner.discountCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(banner.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text(banner.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Switch(
                                    value: banner.isActive,
                                    activeThumbColor: AppTheme.cardamomGreen,
                                    onChanged: (_) => provider.toggleBannerStatus(banner.id),
                                  ),
                                  Text(banner.isActive ? 'Status: ACTIVE' : 'Status: INACTIVE', style: TextStyle(fontWeight: FontWeight.bold, color: banner.isActive ? AppTheme.cardamomGreen : Colors.grey)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showAddEditBannerDialog(context, provider, banner),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => provider.deleteBanner(banner.id),
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

  // ---------------------------------------------------------------------------
  // TAB 4: ORDER FULFILLMENT PIPELINE
  // ---------------------------------------------------------------------------
  Widget _buildOrderFulfillmentTab(BuildContext context, AppProvider provider, NumberFormat formatter) {
    final statuses = ['Pending', 'Processing', 'Packed', 'Dispatched', 'Completed'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Orders & Fulfillment Pipeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Track customer orders and update status from Pending to Dispatched & Completed.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),

          provider.orders.isEmpty
              ? const Card(child: Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No active orders.'))))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.orders.length,
                  itemBuilder: (context, index) {
                    final order = provider.orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(formatter.format(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.royalGoldPrimary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Customer: ${order.customerName ?? "Walk-in"} • Date: ${DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt)} • Payment: ${order.paymentMethod}'),
                            if (order.notes != null) Text('Address / Notes: ${order.notes}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Text('Fulfillment Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                DropdownButton<String>(
                                  value: order.status,
                                  items: statuses
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ))
                                      .toList(),
                                  onChanged: (newStatus) {
                                    if (newStatus != null) {
                                      provider.updateOrderStatus(order.id, newStatus);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 5: REPORTS & FINANCIAL EXPORT
  // ---------------------------------------------------------------------------
  Widget _buildReportsExportTab(BuildContext context, AppProvider provider, NumberFormat formatter) {
    final totalSales = provider.orders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final totalDiscounts = provider.orders.fold(0.0, (sum, o) => sum + o.discount);
    final netSales = totalSales - totalDiscounts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Downloadable Sales & Financial Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Export order spreadsheets (CSV) or generate printable PDF financial summaries.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),

          Card(
            color: AppTheme.royalGoldPrimary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Report Export Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardamomGreen),
                        onPressed: () => _downloadCsv(context, provider),
                        icon: const Icon(Icons.table_chart, color: Colors.white),
                        label: const Text('Download CSV Sales Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          NotificationService.showInAppAlert(
                            context,
                            title: 'PDF Report Generator',
                            message: 'Print preview for Financial PDF Summary opened.',
                            icon: Icons.picture_as_pdf,
                            color: AppTheme.royalGoldPrimary,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Print PDF Financial Summary'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Financial Summary Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Gross Store Sales'),
                  trailing: Text(formatter.format(totalSales), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Total Promotional Discounts'),
                  trailing: Text('- ${formatter.format(totalDiscounts)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('NET REVENUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  trailing: Text(formatter.format(netSales), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.royalGoldPrimary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditSpiceDialog(BuildContext context, AppProvider provider, [SpiceItem? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final sinhalaCtrl = TextEditingController(text: existing?.sinhalaName ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toString() : '');
    final stockCtrl = TextEditingController(text: existing != null ? existing.stock.toString() : '100');
    final unitCtrl = TextEditingController(text: existing?.unit ?? '100g');
    final imgCtrl = TextEditingController(text: existing?.imageUrl ?? 'https://images.unsplash.com/photo-1509358271058-acd02cc93898?w=500');
    final descCtrl = TextEditingController(text: existing?.description ?? 'Pure authentic Sri Lankan spice from Navodya Spices.');
    String category = existing?.category ?? 'Pure Spices';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Spice Item' : 'Add New Spice Item'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'English Name (e.g. Ceylon Cinnamon)')),
                  const SizedBox(height: 8),
                  TextField(controller: sinhalaCtrl, decoration: const InputDecoration(labelText: 'Sinhala Name (e.g. ලංකා කුරුඳු)')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Pure Spices', 'Blended Powders', 'Whole Spices', 'Special Kits']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) category = val;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (LKR)'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g. 100g)'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Count')),
                  const SizedBox(height: 12),

                  // Image Upload / URL Selector Section
                  const Text('Product Image Source (URL or Upload File):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: imgCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Image Web URL / Data URL',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cardamomGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        onPressed: () {
                          _pickLocalImageFile((dataUrl) {
                            imgCtrl.text = dataUrl;
                            setDialogState(() {});
                          });
                        },
                        icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                        label: const Text('UPLOAD FILE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (imgCtrl.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imgCtrl.text,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Center(child: Text('Image Preview Selected', style: TextStyle(fontSize: 12))),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGoldPrimary),
              onPressed: () {
                final id = existing?.id ?? 'SPICE00${provider.products.length + 1}';
                final spice = SpiceItem(
                  id: id,
                  name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'New Spice',
                  sinhalaName: sinhalaCtrl.text.trim(),
                  category: category,
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  unit: unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : '100g',
                  stock: int.tryParse(stockCtrl.text.trim()) ?? 50,
                  imageUrl: imgCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                provider.addOrUpdateProduct(spice);
                Navigator.pop(ctx);
              },
              child: const Text('Save Spice', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSpice(BuildContext context, AppProvider provider, SpiceItem spice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${spice.name}?'),
        content: const Text('Are you sure you want to remove this spice item from catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteProduct(spice.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditBannerDialog(BuildContext context, AppProvider provider, [BannerModel? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final subCtrl = TextEditingController(text: existing?.subtitle ?? '');
    final imgCtrl = TextEditingController(text: existing?.imageUrl ?? 'https://images.unsplash.com/photo-1509358271058-acd02cc93898?w=1000');
    final codeCtrl = TextEditingController(text: existing?.discountCode ?? 'SPICE15');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Banner' : 'Create New Promotional Banner'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Banner Title')),
                const SizedBox(height: 8),
                TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Subtitle / Offer Details')),
                const SizedBox(height: 8),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Promo Discount Code')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imgCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Banner Image URL / Data URL',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardamomGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      onPressed: () {
                        _pickLocalImageFile((dataUrl) {
                          imgCtrl.text = dataUrl;
                          setDialogState(() {});
                        });
                      },
                      icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
                      label: const Text('UPLOAD FILE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGoldAccent),
              onPressed: () {
                final id = existing?.id ?? 'BANNER00${provider.banners.length + 1}';
                final banner = BannerModel(
                  id: id,
                  title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Special Offer',
                  subtitle: subCtrl.text.trim(),
                  imageUrl: imgCtrl.text.trim(),
                  discountCode: codeCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                provider.addOrUpdateBanner(banner);
                Navigator.pop(ctx);
              },
              child: const Text('Save Banner', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
