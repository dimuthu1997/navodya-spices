import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/spice_item.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class ProductDetailsModal extends StatefulWidget {
  final SpiceItem spice;

  const ProductDetailsModal({super.key, required this.spice});

  @override
  State<ProductDetailsModal> createState() => _ProductDetailsModalState();
}

class _ProductDetailsModalState extends State<ProductDetailsModal> {
  late String _selectedUnit;
  int _quantity = 1;

  final List<String> _availableUnits = ['50g', '100g', '250g', '500g', '1Kg'];

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.spice.unit.isNotEmpty ? widget.spice.unit : '100g';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 2,
    );

    final currentUnitPrice = widget.spice.getPriceForWeight(_selectedUnit);
    final totalPrice = currentUnitPrice * _quantity;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(
            color: AppTheme.royalGoldPrimary.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero Image Header Banner
              Stack(
                children: [
                  Image.network(
                    widget.spice.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: AppTheme.royalGoldPrimary.withValues(alpha: 0.1),
                      child: const Center(
                        child: Icon(
                          Icons.dry_cleaning,
                          size: 80,
                          color: AppTheme.royalGoldPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Top Row: Category Pill & Close Button
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.royalGoldPrimary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Text(
                            widget.spice.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.royalGoldPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom Rating Badge
                  Positioned(
                    bottom: 12,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.spice.rating} (100% Organic Ceylon)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Scrollable Content Section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Titles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.spice.name,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.spice.sinhalaName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.royalGoldPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormatter.format(currentUnitPrice),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.royalGoldPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Weight Variant Selection (50g, 100g, 250g, 500g, 1Kg)
                      const Text(
                        '⚖️ SELECT WEIGHT VARIANT / ප්‍රමාණය තෝරන්න:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: _availableUnits.map((u) {
                          final isSelected = _selectedUnit == u;
                          final priceForUnit = widget.spice.getPriceForWeight(
                            u,
                          );
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: InkWell(
                                onTap: () => setState(() => _selectedUnit = u),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.royalGoldPrimary
                                        : (isDark
                                              ? Colors.grey.shade900
                                              : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.royalGoldPrimary
                                          : (isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade300),
                                      width: isSelected ? 1.8 : 1.0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.royalGoldPrimary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        u,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.grey.shade300
                                                    : Colors.grey.shade800),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Rs. ${priceForUnit.toInt()}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white.withValues(
                                                  alpha: 0.9,
                                                )
                                              : AppTheme.royalGoldPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 📜 Ingredients Section (අඩංගු ද්‍රව්‍ය)
                      const Text(
                        '🌿 INGREDIENTS / අඩංගු ද්‍රව්‍ය:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardamomGreen.withValues(
                            alpha: isDark ? 0.12 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.cardamomGreen.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: widget.spice.ingredients.isNotEmpty
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: widget.spice.ingredients
                                    .map(
                                      (ing) => Chip(
                                        avatar: const Icon(
                                          Icons.check_circle_outline,
                                          size: 14,
                                          color: AppTheme.cardamomGreen,
                                        ),
                                        label: Text(
                                          ing,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        backgroundColor: isDark
                                            ? Colors.grey.shade900
                                            : Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 0,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    )
                                    .toList(),
                              )
                            : const Text(
                                '100% Pure Natural Spice, No Added Preservatives or Artificial Flavors.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        '📝 DESCRIPTION / විස්තරය:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.spice.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar: Quantity Stepper & Add to Cart Button
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Quantity Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Add to Cart Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.royalGoldPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            provider.addToCart(
                              widget.spice,
                              quantity: _quantity,
                              unit: _selectedUnit,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '🛒 Added ${widget.spice.name} ($_selectedUnit x $_quantity) to Cart!',
                                ),
                                backgroundColor: AppTheme.cardamomGreen,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            'ADD TO CART • ${currencyFormatter.format(totalPrice)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
