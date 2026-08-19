import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/spice_item.dart';
import '../../theme/app_theme.dart';
import 'product_details_modal.dart';

class ProductCard extends StatelessWidget {
  final SpiceItem spice;
  final int cartQuantity;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;

  const ProductCard({
    super.key,
    required this.spice,
    required this.cartQuantity,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  void _openDetailsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ProductDetailsModal(spice: spice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 2,
    );
    final isInCart = cartQuantity > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openDetailsModal(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isInCart
                ? AppTheme.royalGoldPrimary
                : AppTheme.royalGoldPrimary.withValues(alpha: 0.12),
            width: isInCart ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isInCart
                  ? AppTheme.royalGoldPrimary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isInCart ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header with Top Badges (Unit weight top right & Rating top left)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Image.network(
                    spice.imageUrl,
                    height: MediaQuery.of(context).size.width >= 1100 ? 145 : 125,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackImage(context),
                  ),
                ),

                // Top Left Badge: Rating or Bestseller Tag
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.royalGoldPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          spice.isPopular ? 'HOT' : '${spice.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right Badge: Weight Variants Indicator (50g - 1Kg)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '50g - 1Kg',
                      style: TextStyle(
                        color: AppTheme.royalGoldPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body (English Title, Sinhala Subtitle, Ingredients badge, Price, and Actions)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spice.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spice.sinhalaName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (spice.ingredients.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🌿 ${spice.ingredients.join(", ")}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppTheme.cardamomGreen.withValues(
                                alpha: 0.9,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Price Tag & Actions (Weight Select & Add Button)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currencyFormatter.format(spice.price),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.royalGoldPrimary,
                                ),
                              ),
                              const Text(
                                'Base (100g)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),

                          // Action Buttons: Details / Select Weight vs Quantity Control
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _openDetailsModal(context),
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: AppTheme.royalGoldPrimary,
                                ),
                                tooltip: 'View Ingredients & Weight Options',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                              const SizedBox(width: 2),
                              if (!isInCart)
                                InkWell(
                                  onTap: () => _openDetailsModal(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.royalGoldPrimary,
                                          AppTheme.royalGoldAccent,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.royalGoldPrimary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.royalGoldPrimary,
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: onRemoveFromCart,
                                        child: const Icon(
                                          Icons.remove,
                                          size: 14,
                                          color: AppTheme.royalGoldPrimary,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          '$cartQuantity',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppTheme.royalGoldPrimary,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _openDetailsModal(context),
                                        child: const Icon(
                                          Icons.add,
                                          size: 14,
                                          color: AppTheme.royalGoldPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    final height = MediaQuery.of(context).size.width >= 1100 ? 145.0 : 125.0;
    return Container(
      height: height,
      color: AppTheme.royalGoldPrimary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.dry_cleaning,
          size: 50,
          color: AppTheme.royalGoldPrimary,
        ),
      ),
    );
  }
}
