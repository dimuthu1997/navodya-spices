import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/storefront/product_card.dart';
import '../widgets/storefront/customer_checkout_modal.dart';

class OnlineStorefrontScreen extends StatelessWidget {
  const OnlineStorefrontScreen({super.key});

  void _showCustomerCheckoutModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CustomerCheckoutModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isMobile = screenWidth < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Campaign Banner Section
            if (appProvider.banners.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(12),
                height: isDesktop ? 220 : (isMobile ? 195 : 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.royalGoldPrimary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Image.network(
                        appProvider.banners.first.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.royalGoldPrimary, AppTheme.royalGoldAccent],
                            ),
                          ),
                          child: const Center(child: Icon(Icons.workspace_premium, size: 80, color: Colors.white)),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.25),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.royalGoldPrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PROMO CODE: ${appProvider.banners.first.discountCode}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              appProvider.banners.first.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appProvider.banners.first.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white70, fontSize: isMobile ? 11 : 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Search Bar & Free Shipping Alert Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: isMobile
                  ? Column(
                      children: [
                        TextField(
                          onChanged: (q) => appProvider.setSearchQuery(q),
                          style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
                          decoration: InputDecoration(
                            hintText: 'Search spices, Sinhala names...',
                            hintStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            prefixIcon: const Icon(Icons.search, color: AppTheme.royalGoldPrimary),
                            suffixIcon: appProvider.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => appProvider.setSearchQuery(''),
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.royalGoldPrimary.withValues(alpha: 0.3)
                                    : AppTheme.royalGoldPrimary.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardamomGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.cardamomGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_shipping_outlined, color: AppTheme.cardamomGreen, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'FREE Delivery > Rs. ${appProvider.freeShippingThreshold.toInt()}',
                                style: const TextStyle(color: AppTheme.cardamomGreen, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (q) => appProvider.setSearchQuery(q),
                            style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
                            decoration: InputDecoration(
                              hintText: 'Search spices, Sinhala names, categories...',
                              hintStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              prefixIcon: const Icon(Icons.search, color: AppTheme.royalGoldPrimary),
                              suffixIcon: appProvider.searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => appProvider.setSearchQuery(''),
                                    )
                                  : null,
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppTheme.royalGoldPrimary.withValues(alpha: 0.3)
                                      : AppTheme.royalGoldPrimary.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardamomGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardamomGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined, color: AppTheme.cardamomGreen, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'FREE Delivery > Rs. ${appProvider.freeShippingThreshold.toInt()}',
                                style: const TextStyle(color: AppTheme.cardamomGreen, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            // Category Chips Selector Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: appProvider.categories.map((cat) {
                  final isSelected = appProvider.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => appProvider.setCategory(cat),
                      selectedColor: AppTheme.royalGoldPrimary,
                      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.royalGoldPrimary
                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade200 : AppTheme.textDark),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Spices Grid View or Empty State
            if (appProvider.filteredProducts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.royalGoldPrimary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rice_bowl, size: 64, color: AppTheme.royalGoldPrimary),
                    const SizedBox(height: 16),
                    const Text(
                      'No Spices Found in Firestore Database',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Cloud Firestore database catalog is currently empty. Click below to load initial Sri Lankan spice catalog into Firebase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalGoldPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        await appProvider.seedFirestoreCatalog();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚡ Initial Spice Catalog successfully loaded into Firebase Firestore!'),
                              backgroundColor: AppTheme.cardamomGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                      label: const Text(
                        'INITIALIZE FIREBASE SPICES CATALOG',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appProvider.filteredProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : (screenWidth >= 600 ? 3 : 2),
                    childAspectRatio: isDesktop ? 0.88 : (screenWidth >= 600 ? 0.76 : 0.64),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, idx) {
                    final spice = appProvider.filteredProducts[idx];
                    final cartItemIndex = appProvider.cart.indexWhere((c) => c.spice.id == spice.id);
                    final quantityInCart = cartItemIndex >= 0 ? appProvider.cart[cartItemIndex].quantity : 0;

                    return ProductCard(
                      spice: spice,
                      cartQuantity: quantityInCart,
                      onAddToCart: () => appProvider.addToCart(spice),
                      onRemoveFromCart: () => appProvider.updateCartQuantity(spice, -1),
                    );
                  },
                ),
              ),
          ],
        ),
      ),

      // Instant Guest Checkout Floating Pill Bar
      bottomNavigationBar: appProvider.cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${appProvider.cart.length} Spices Selected',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                      ),
                      Text(
                        currencyFormatter.format(appProvider.grandTotal),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.royalGoldPrimary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalGoldPrimary,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _showCustomerCheckoutModal(context),
                    icon: const Icon(Icons.shopping_bag, color: Colors.white, size: 16),
                    label: Text(
                      isMobile ? 'CHECKOUT' : 'PROCEED TO CHECKOUT',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
