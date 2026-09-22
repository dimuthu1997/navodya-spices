import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';

class CustomerCheckoutModal extends StatefulWidget {
  const CustomerCheckoutModal({super.key});

  @override
  State<CustomerCheckoutModal> createState() => _CustomerCheckoutModalState();
}

class _CustomerCheckoutModalState extends State<CustomerCheckoutModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = 'WhatsApp Direct';
  String _errorMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.currentUser != null) {
        _nameController.text = provider.currentUser!.name;
        _emailController.text = provider.currentUser!.email;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleCompleteOrder(AppProvider provider) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final notes = _notesController.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Full Name, Phone Number, and Delivery Address.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    final order = await provider.processCheckout(
      paymentMethod: _paymentMethod,
      customerName: name,
      customerEmail: email.isNotEmpty ? email : null,
      customerPhone: phone,
      deliveryAddress: address,
      city: city.isNotEmpty ? city : null,
      notes: notes.isNotEmpty ? notes : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (order != null) {
        Navigator.pop(context);
        _showOrderSuccessDialog(context, provider, order);
      }
    }
  }

  void _showOrderSuccessDialog(BuildContext context, AppProvider provider, OrderModel order) {
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardamomGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 54, color: AppTheme.cardamomGreen),
              ),
              const SizedBox(height: 16),
              const Text(
                'ORDER PLACED SUCCESSFULLY!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Firebase Order ID: ${order.id}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.royalGoldPrimary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid:', style: TextStyle(fontSize: 13)),
                        Text(currencyFormatter.format(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Method:', style: TextStyle(fontSize: 13)),
                        Text(order.paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cardamomGreen)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Est. Delivery:', style: TextStyle(fontSize: 13)),
                        Text('1 - 2 Business Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.saffronPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text('Continue Shopping', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalGoldPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.setNavIndex(3); // Navigate to Order History screen
                      },
                      icon: const Icon(Icons.history, color: Colors.white, size: 16),
                      label: const Text('Track Order', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    // final remainingForFreeDelivery = (provider.freeShippingThreshold - provider.subtotal).clamp(0.0, double.infinity);

    if (provider.currentUser != null) {
      if (_nameController.text.isEmpty) _nameController.text = provider.currentUser!.name;
      if (_emailController.text.isEmpty) _emailController.text = provider.currentUser!.email;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 580,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        child: Column(
          children: [
            // Modal Top Title Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_checkout, color: AppTheme.royalGoldPrimary, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cart Checkout & Delivery',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error Banner
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12))),
                          ],
                        ),
                      ),

                    // SECTION 1: CART ITEMS REVIEW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOUR SELECTED ITEMS (${provider.cart.length})',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                        ),
                        TextButton(
                          onPressed: () => provider.clearCart(),
                          child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (provider.cart.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('Your shopping cart is empty.', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.cart.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final item = provider.cart[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCard : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        item.spice.imageUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 48,
                                          height: 48,
                                          color: AppTheme.royalGoldPrimary.withValues(alpha: 0.15),
                                          child: const Icon(Icons.rice_bowl, size: 24, color: AppTheme.royalGoldPrimary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.spice.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (item.spice.sinhalaName.isNotEmpty)
                                            Text(
                                              item.spice.sinhalaName,
                                              style: const TextStyle(fontSize: 11.5, color: AppTheme.royalGoldPrimary, fontWeight: FontWeight.w600),
                                            ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${currencyFormatter.format(item.unitPrice)} (${item.selectedUnit})',
                                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      currencyFormatter.format(item.itemTotal),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.royalGoldPrimary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Quantity:',
                                      style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                    Container(
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 16),
                                            onPressed: () => provider.updateCartQuantity(item.spice, -1, unit: item.selectedUnit),
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            constraints: const BoxConstraints(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 16, color: AppTheme.royalGoldPrimary),
                                            onPressed: () => provider.updateCartQuantity(item.spice, 1, unit: item.selectedUnit),
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // SECTION 2: CUSTOMER CONTACT & DELIVERY DETAILS
                    Text(
                      'DELIVERY & CONTACT INFORMATION',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isMobile) ...[
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone / WhatsApp *',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address (Optional)',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone / WhatsApp *',
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address (Optional)',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (isMobile) ...[
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Street Address *',
                          prefixIcon: Icon(Icons.home_outlined),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City / District',
                          prefixIcon: Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Delivery Street Address *',
                                prefixIcon: Icon(Icons.home_outlined),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City / District',
                                prefixIcon: Icon(Icons.location_city_outlined),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Special Delivery Instructions (Optional)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 4: PAYMENT METHOD SELECTION
                    Text(
                      'PAYMENT METHOD',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          /*
                          // Temporarily disabled other payment methods
                          RadioListTile<String>(
                            title: const Row(
                              children: [
                                Icon(Icons.local_shipping, color: AppTheme.cardamomGreen, size: 18),
                                SizedBox(width: 8),
                                Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            subtitle: const Text('Pay with cash when order arrives at your address', style: TextStyle(fontSize: 11)),
                            value: 'Cash on Delivery',
                            groupValue: _paymentMethod,
                            onChanged: (val) => setState(() => _paymentMethod = val!),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Row(
                              children: [
                                Icon(Icons.credit_card, color: Colors.blueAccent, size: 18),
                                SizedBox(width: 8),
                                Text('Online Direct Card Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            subtitle: const Text('Simulated Instant Visa / Mastercard payment', style: TextStyle(fontSize: 11)),
                            value: 'Card Direct',
                            groupValue: _paymentMethod,
                            onChanged: (val) => setState(() => _paymentMethod = val!),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Row(
                              children: [
                                Icon(Icons.account_balance, color: AppTheme.saffronPrimary, size: 18),
                                SizedBox(width: 8),
                                Text('Bank Transfer (Commercial Bank)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            subtitle: const Text('Transfer to Navodya Spices Acc: 8009124001', style: TextStyle(fontSize: 11)),
                            value: 'Bank Transfer',
                            groupValue: _paymentMethod,
                            onChanged: (val) => setState(() => _paymentMethod = val!),
                          ),
                          const Divider(height: 1),
                          */
                          RadioListTile<String>(
                            title: const Row(
                              children: [
                                Icon(Icons.phone_android, color: AppTheme.whatsappGreen, size: 18),
                                SizedBox(width: 8),
                                Text('WhatsApp Direct Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            subtitle: const Text('Send cart directly to WhatsApp 0702308303', style: TextStyle(fontSize: 11)),
                            value: 'WhatsApp Direct',
                            groupValue: _paymentMethod,
                            onChanged: (val) => setState(() => _paymentMethod = val!),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SECTION 5: GRAND TOTAL BREAKDOWN BOX
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.royalGoldPrimary.withValues(alpha: 0.08),
                            AppTheme.royalGoldAccent.withValues(alpha: 0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.royalGoldPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Items Subtotal:'),
                              Text(currencyFormatter.format(provider.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (provider.discountAmount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount (${provider.appliedCouponCode ?? ""}):', style: const TextStyle(color: AppTheme.cardamomGreen)),
                                Text('-${currencyFormatter.format(provider.discountAmount)}', style: const TextStyle(color: AppTheme.cardamomGreen, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 6),
                          /*
                          // Temporarily commented out delivery fee cost row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Islandwide Delivery Fee:'),
                              Text(
                                provider.deliveryFee == 0 ? 'FREE' : currencyFormatter.format(provider.deliveryFee),
                                style: TextStyle(fontWeight: FontWeight.bold, color: provider.deliveryFee == 0 ? AppTheme.cardamomGreen : AppTheme.textDark),
                              ),
                            ],
                          ),

                          if (remainingForFreeDelivery > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.cardamomGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.local_shipping, size: 14, color: AppTheme.cardamomGreen),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add ${currencyFormatter.format(remainingForFreeDelivery)} more for FREE Delivery!',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.cardamomGreen, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          */

                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('GRAND TOTAL:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(
                                currencyFormatter.format(provider.grandTotal),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.royalGoldPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Modal Bottom Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cardamomGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: (_isSubmitting || provider.cart.isEmpty) ? null : () => _handleCompleteOrder(provider),
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'PLACING FIREBASE ORDER...' : 'CONFIRM & PLACE ORDER',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
