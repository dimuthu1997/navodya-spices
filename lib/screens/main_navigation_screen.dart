import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_logo_header.dart';
import '../widgets/storefront/customer_checkout_modal.dart';
import 'online_storefront_screen.dart';
import 'pos_terminal_screen.dart';
import 'sales_history_screen.dart';
import 'inventory_screen.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  void _showLoginSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: const LoginScreen(),
      ),
    );
  }

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
    final user = appProvider.currentUser;

    final isAdmin = appProvider.isAdmin;
    final isCashier = appProvider.isCashier;
    final isCustomer = user != null && user.isCustomer;

    // Filter available navigation items based on User Role
    final List<Widget> pages = [];
    final List<WebSidebarItem> sidebarItems = [];
    final List<NavigationDestination> mobileNavDestinations = [];

    // 1. Online Shop (Always visible to everyone)
    pages.add(const OnlineStorefrontScreen());
    sidebarItems.add(
      const WebSidebarItem(
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront,
        label: 'Online Shop',
      ),
    );
    mobileNavDestinations.add(
      const NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront, color: AppTheme.royalGoldPrimary),
        label: 'Store',
      ),
    );

    // 2. POS Terminal (Cashiers & Admins only)
    if (isAdmin || isCashier) {
      pages.add(const PosTerminalScreen());
      sidebarItems.add(
        const WebSidebarItem(
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale,
          label: 'POS Terminal',
        ),
      );
      mobileNavDestinations.add(
        const NavigationDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(
            Icons.point_of_sale,
            color: AppTheme.royalGoldPrimary,
          ),
          label: 'POS',
        ),
      );
    }

    // 3. Sales / Order History (Customers, Cashiers, & Admins)
    if (isAdmin || isCashier || isCustomer) {
      pages.add(const SalesHistoryScreen());
      sidebarItems.add(
        WebSidebarItem(
          icon: Icons.history_outlined,
          selectedIcon: Icons.history,
          label: isCustomer ? 'My Order History' : 'Sales History',
        ),
      );
      mobileNavDestinations.add(
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(
            Icons.history,
            color: AppTheme.royalGoldPrimary,
          ),
          label: isCustomer ? 'Orders' : 'History',
        ),
      );
    }

    // 4. Spice Inventory (Admins only)
    if (isAdmin) {
      pages.add(const InventoryScreen());
      sidebarItems.add(
        const WebSidebarItem(
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          label: 'Spice Inventory',
        ),
      );
      mobileNavDestinations.add(
        const NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(
            Icons.inventory_2,
            color: AppTheme.royalGoldPrimary,
          ),
          label: 'Inventory',
        ),
      );
    }

    // 5. Admin Panel (Admins only)
    if (isAdmin) {
      pages.add(const AdminDashboardScreen());
      sidebarItems.add(
        const WebSidebarItem(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: 'Admin Panel',
        ),
      );
      mobileNavDestinations.add(
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(
            Icons.admin_panel_settings,
            color: AppTheme.royalGoldPrimary,
          ),
          label: 'Admin',
        ),
      );
    }

    final activeIndex = appProvider.currentNavIndex.clamp(0, pages.length - 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: isMobile ? 8 : 16,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AppLogoHeader(size: isMobile ? 32 : 44, showSubtitle: !isMobile),
              if (!isMobile) const SizedBox(width: 12),

              // User Role Badge
              if (user != null && !isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.isAdmin
                        ? AppTheme.royalGoldPrimary.withValues(alpha: 0.12)
                        : (user.isCashier
                              ? AppTheme.cardamomGreen.withValues(alpha: 0.12)
                              : AppTheme.royalGoldAccent.withValues(
                                  alpha: 0.12,
                                )),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: user.isAdmin
                          ? AppTheme.royalGoldPrimary
                          : (user.isCashier
                                ? AppTheme.cardamomGreen
                                : AppTheme.royalGoldAccent),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        user.isAdmin
                            ? Icons.admin_panel_settings
                            : (user.isCashier
                                  ? Icons.point_of_sale
                                  : Icons.person_outline),
                        size: 12,
                        color: user.isAdmin
                            ? AppTheme.royalGoldPrimary
                            : (user.isCashier
                                  ? AppTheme.cardamomGreen
                                  : AppTheme.royalGoldAccent),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.roleDisplayName,
                        style: TextStyle(
                          color: user.isAdmin
                              ? AppTheme.royalGoldPrimary
                              : (user.isCashier
                                    ? AppTheme.cardamomGreen
                                    : AppTheme.royalGoldAccent),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Desktop WhatsApp Badge
              if (isDesktop) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.whatsappGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.whatsappGreen.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 12,
                        color: AppTheme.whatsappGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'WA: 0702308303',
                        style: TextStyle(
                          color: AppTheme.whatsappGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (user == null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.royalGoldPrimary, AppTheme.royalGoldAccent],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.royalGoldPrimary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showLoginSheet(context),
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isMobile ? 'Log In' : 'Log In / Register',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.royalGoldPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.royalGoldPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.royalGoldPrimary,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Logout (${user.name})',
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    onPressed: () => appProvider.logout(),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 4),

          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: appProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
            icon: Icon(
              appProvider.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              size: 20,
            ),
            onPressed: () => appProvider.toggleTheme(),
          ),
          const SizedBox(width: 6),

          // Shopping Cart Pill Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.royalGoldPrimary, AppTheme.royalGoldAccent],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (appProvider.cart.isNotEmpty) {
                    _showCustomerCheckoutModal(context);
                  } else {
                    appProvider.setNavIndex(0);
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${appProvider.cart.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Custom Web Sidebar Navigation for Desktop
          if (isDesktop && sidebarItems.length > 1)
            Container(
              width: 210,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  right: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    width: 1.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...sidebarItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isSelected = activeIndex == idx;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => appProvider.setNavIndex(idx),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.royalGoldPrimary.withValues(
                                      alpha: 0.12,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: AppTheme.royalGoldPrimary
                                          .withValues(alpha: 0.3),
                                      width: 1.0,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  size: 19,
                                  color: isSelected
                                      ? AppTheme.royalGoldPrimary
                                      : (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.royalGoldPrimary
                                          : (isDark
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

          Expanded(
            child: IndexedStack(index: activeIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop && mobileNavDestinations.length > 1
          ? NavigationBar(
              selectedIndex: activeIndex,
              onDestinationSelected: (idx) => appProvider.setNavIndex(idx),
              destinations: mobileNavDestinations,
            )
          : null,
    );
  }
}

class WebSidebarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const WebSidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
