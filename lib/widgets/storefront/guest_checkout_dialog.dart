import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class GuestCheckoutDialog extends StatefulWidget {
  const GuestCheckoutDialog({super.key});

  @override
  State<GuestCheckoutDialog> createState() => _GuestCheckoutDialogState();
}

class _GuestCheckoutDialogState extends State<GuestCheckoutDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  String _paymentMethod = 'WhatsApp Direct';
  String _errorMessage = '';
  String _couponSuccessMessage = '';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _handleApplyCoupon(AppProvider provider) {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    final ok = provider.applyPromoCoupon(code);
    if (ok) {
      setState(() {
        _couponSuccessMessage = 'Promo Coupon Applied! (${provider.appliedCouponCode})';
        _errorMessage = '';
      });
    } else {
      setState(() {
        _errorMessage = 'Invalid Coupon Code. Try AVURUDU15, CEYLONSPICE, or NAVODYA10';
        _couponSuccessMessage = '';
      });
    }
  }

  void _handleCompleteOrder(AppProvider provider) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Name, Phone Number, and Delivery Address.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    final fullAddressNotes = '$address, $city (Tel: $phone)';
    final order = await provider.processCheckout(
      paymentMethod: _paymentMethod,
      customerName: name,
      notes: fullAddressNotes,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (order != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ORDER PLACED SUCCESSFULLY: ${order.id}! Dispatched to WhatsApp.'),
            backgroundColor: AppTheme.cardamomGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currencyFormatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, color: AppTheme.royalGoldPrimary, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Instant Guest Checkout',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Text('No Login Required • Direct WhatsApp Dispatch (0702308303)', style: TextStyle(fontSize: 11, color: AppTheme.royalGoldPrimary, fontWeight: FontWeight.bold)),
              const Divider(height: 24),

              // Error or Coupon Message Banner
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 11))),
                    ],
                  ),
                ),

              if (_couponSuccessMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppTheme.cardamomGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.cardamomGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_couponSuccessMessage, style: const TextStyle(color: AppTheme.cardamomGreen, fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),

              // Delivery Contact Details Input Form
              const Text('DELIVERY & CONTACT DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone / WhatsApp Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address *',
                  prefixIcon: Icon(Icons.home_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City / District',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Promo Coupon Input
              const Text('HAVE A PROMO COUPON?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. AVURUDU15',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGoldPrimary),
                    onPressed: () => _handleApplyCoupon(provider),
                    child: const Text('APPLY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Method Choices
              const Text('PAYMENT METHOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Column(
                children: [
                  /*
                  RadioListTile<String>(
                    title: const Text('Cash on Delivery (COD)'),
                    subtitle: const Text('Pay cash upon islandwide delivery'),
                    value: 'Cash on Delivery',
                    groupValue: _paymentMethod,
                    onChanged: (val) => setState(() => _paymentMethod = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Bank Transfer'),
                    subtitle: const Text('Transfer to Commercial Bank account'),
                    value: 'Bank Transfer',
                    groupValue: _paymentMethod,
                    onChanged: (val) => setState(() => _paymentMethod = val!),
                  ),
                  */
                  RadioListTile<String>(
                    title: const Text('WhatsApp Order Dispatch'),
                    subtitle: const Text('Send cart directly to WhatsApp 0702308303'),
                    value: 'WhatsApp Direct',
                    groupValue: _paymentMethod,
                    onChanged: (val) => setState(() => _paymentMethod = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Order Summary Breakdown Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgCreamParchment,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.royalGoldPrimary.withValues(alpha: 0.2)),
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
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discount (${provider.appliedCouponCode ?? ""}):', style: const TextStyle(color: AppTheme.cardamomGreen)),
                          Text('-${currencyFormatter.format(provider.discountAmount)}', style: const TextStyle(color: AppTheme.cardamomGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
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
                    */
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GRAND TOTAL:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          currencyFormatter.format(provider.grandTotal),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.royalGoldPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Order Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardamomGreen),
                  onPressed: _isSubmitting ? null : () => _handleCompleteOrder(provider),
                  icon: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'PROCESSING...' : 'CONFIRM & PLACE ORDER',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
