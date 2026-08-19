import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/app_provider.dart';
import '../models/spice_item.dart';
import '../theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spice Inventory & QR Cards', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Manage products stock, prices and print package QR tags', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.royalGoldPrimary)),
                      onPressed: () async {
                        await appProvider.seedFirestoreCatalog();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚡ Firebase Firestore Catalog Synced & Seeded successfully!'),
                              backgroundColor: AppTheme.cardamomGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, color: AppTheme.royalGoldPrimary, size: 16),
                      label: const Text('Seed Firebase DB', style: TextStyle(color: AppTheme.royalGoldPrimary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.saffronPrimary),
                      onPressed: () => _showAddEditSpiceDialog(context, appProvider),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add New Spice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Products Table Card
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID / QR', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Spice Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Stock Level', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: appProvider.products.map((spice) {
                    final isLowStock = spice.stock < 50;
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              QrImageView(
                                data: spice.qrPayload,
                                size: 36,
                                foregroundColor: AppTheme.saffronPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(spice.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(spice.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (spice.sinhalaName.isNotEmpty)
                                Text(spice.sinhalaName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        DataCell(Chip(label: Text(spice.category, style: const TextStyle(fontSize: 11)))),
                        DataCell(Text(currencyFormatter.format(spice.price))),
                        DataCell(Text(spice.unit)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLowStock ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${spice.stock} units',
                              style: TextStyle(
                                color: isLowStock ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Print QR Code Tag',
                                icon: const Icon(Icons.qr_code_2, color: AppTheme.saffronPrimary),
                                onPressed: () => _showQrPrintCard(context, spice, currencyFormatter),
                              ),
                              IconButton(
                                tooltip: 'Edit Spice Details',
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () => _showAddEditSpiceDialog(context, appProvider, spice),
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

  void _showQrPrintCard(BuildContext context, SpiceItem spice, NumberFormat formatter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('NAVODYA SPICES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(spice.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.saffronPrimary)),
              Text(spice.sinhalaName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              QrImageView(
                data: spice.qrPayload,
                size: 160,
                foregroundColor: AppTheme.saffronPrimary,
              ),
              const SizedBox(height: 12),
              Text('${formatter.format(spice.price)} per ${spice.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('ID: ${spice.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.saffronPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print job sent for spice tag.')));
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('Print Tag', style: TextStyle(color: Colors.white)),
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
    String category = existing?.category ?? 'Pure Spices';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Edit Spice Product' : 'Add New Spice Product'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Spice English Name')),
                const SizedBox(height: 10),
                TextField(controller: sinhalaCtrl, decoration: const InputDecoration(labelText: 'Sinhala Name (ලංකා කුරුඳු)')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Pure Spices', 'Blended Powders', 'Whole Spices', 'Special Kits']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) category = val;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (LKR)'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g. 100g)'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial Stock Quantity')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.saffronPrimary),
            onPressed: () {
              final id = existing?.id ?? 'SPICE00${provider.products.length + 1}';
              final newSpice = SpiceItem(
                id: id,
                name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'New Spice',
                sinhalaName: sinhalaCtrl.text.trim(),
                category: category,
                price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                unit: unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : '100g',
                stock: int.tryParse(stockCtrl.text.trim()) ?? 50,
                imageUrl: existing?.imageUrl ?? 'https://images.unsplash.com/photo-1509358271058-acd02cc93898?w=500',
                description: 'Authentic Sri Lankan spice from Navodya Spices.',
              );
              provider.addOrUpdateProduct(newSpice);
              Navigator.pop(ctx);
            },
            child: const Text('Save Spice', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
