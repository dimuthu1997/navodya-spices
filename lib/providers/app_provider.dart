import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import '../models/spice_item.dart';
import '../models/order_model.dart';
import '../models/banner_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class AppProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  List<SpiceItem> _products = [];
  final List<CartItem> _cart = [];
  final List<OrderModel> _orders = [];
  List<BannerModel> _banners = [];
  List<AppUser> _users = [];

  // Dynamic Store Configuration
  String _storeName = 'Navodya Spices';
  String _storeSinhalaName = 'නාවෝද්‍යා කුළුබඩු';
  String _whatsappNumber = '0702308303';
  double _freeShippingThreshold = 3000.0;
  double _standardDeliveryFee = 350.0;
  Map<String, double> _activePromos = {
    'AVURUDU15': 0.15,
    'CEYLONSPICE': 0.10,
    'NAVODYA10': 0.10,
  };

  AppUser? _currentUser;
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  double _discountPercent = 0.0;
  String? _appliedCouponCode;
  bool _isDarkMode = false;
  int _currentNavIndex = 0;

  // Scanned item modal trigger state
  SpiceItem? _scannedSpiceItem;
  int _scannedQuantity = 1;
  bool _showDirectBuyDialog = false;

  // Firestore Real-Time Stream Subscriptions
  StreamSubscription<List<SpiceItem>>? _spicesSubscription;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<List<BannerModel>>? _bannersSubscription;
  StreamSubscription<List<AppUser>>? _usersSubscription;
  StreamSubscription<Map<String, dynamic>>? _configSubscription;

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCashier => _currentUser?.isCashier ?? false;
  bool get isCustomer => _currentUser == null || (_currentUser?.isCustomer ?? true);

  List<SpiceItem> get products => _products;
  List<CartItem> get cart => List.unmodifiable(_cart);
  List<OrderModel> get orders => List.unmodifiable(_orders);

  // Getter for customer specific orders (linked by user ID, user email, or recent guest placement)
  List<OrderModel> get customerOrders {
    if (_currentUser == null) return List.unmodifiable(_orders);
    final uid = _currentUser!.id.toLowerCase();
    final uemail = _currentUser!.email.toLowerCase();
    return List.unmodifiable(_orders.where((o) {
      final oUid = (o.userId ?? '').toLowerCase();
      final oEmail = (o.customerEmail ?? '').toLowerCase();
      return oUid == uid || (uemail.isNotEmpty && oEmail == uemail);
    }).toList());
  }

  List<BannerModel> get banners => List.unmodifiable(_banners);
  List<AppUser> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  double get discountPercent => _discountPercent;
  String? get appliedCouponCode => _appliedCouponCode;
  bool get isDarkMode => _isDarkMode;
  int get currentNavIndex => _currentNavIndex;

  String get storeName => _storeName;
  String get storeSinhalaName => _storeSinhalaName;
  String get whatsappNumber => _whatsappNumber;
  double get freeShippingThreshold => _freeShippingThreshold;
  double get standardDeliveryFee => _standardDeliveryFee;

  SpiceItem? get scannedSpiceItem => _scannedSpiceItem;
  int get scannedQuantity => _scannedQuantity;
  bool get showDirectBuyDialog => _showDirectBuyDialog;

  List<String> get categories => [
        'All',
        'Pure Spices',
        'Blended Powders',
        'Whole Spices',
        'Special Kits',
      ];

  AppProvider() {
    _restoreUserSession();
    _initDataAndStreams();
    _checkUrlForQrParams();
    _notificationService.requestPermission();
  }

  // --- LOCAL PERSISTENT USER SESSION MANAGEMENT ---
  void _saveUserSession(AppUser user) {
    _currentUser = user;
    try {
      if (kIsWeb) {
        web.window.localStorage.setItem('navodya_spices_user', jsonEncode(user.toMap()));
      }
    } catch (e) {
      debugPrint("Save user session note: $e");
    }
    notifyListeners();
  }

  void _clearUserSession() {
    _currentUser = null;
    try {
      if (kIsWeb) {
        web.window.localStorage.removeItem('navodya_spices_user');
      }
    } catch (e) {
      debugPrint("Clear user session note: $e");
    }
    notifyListeners();
  }

  void _restoreUserSession() {
    try {
      if (kIsWeb) {
        final rawUser = web.window.localStorage.getItem('navodya_spices_user');
        if (rawUser != null && rawUser.isNotEmpty) {
          final Map<String, dynamic> map = jsonDecode(rawUser);
          _currentUser = AppUser.fromMap(map);
          debugPrint("User session auto-restored: ${_currentUser?.email}");
        }
      }
    } catch (e) {
      debugPrint("Restore user session note: $e");
    }
  }

  @override
  void dispose() {
    _spicesSubscription?.cancel();
    _ordersSubscription?.cancel();
    _bannersSubscription?.cancel();
    _usersSubscription?.cancel();
    _configSubscription?.cancel();
    super.dispose();
  }

  // --- INITIALIZE & SUBSCRIBE TO REAL-TIME FIREBASE FIRESTORE STREAMS ---
  Future<void> _initDataAndStreams() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.initializeFirebase();

      // 1. Subscribe to Live Spices Catalog Stream
      _spicesSubscription = _firebaseService.spicesStream().listen((liveSpices) {
        _products = liveSpices;
        notifyListeners();
      }, onError: (err) {
        debugPrint("Spices stream note: $err");
      });

      // 2. Subscribe to Live Orders Stream
      _ordersSubscription = _firebaseService.ordersStream().listen((liveOrders) {
        _orders.clear();
        _orders.addAll(liveOrders);
        notifyListeners();
      }, onError: (err) {
        debugPrint("Orders stream note: $err");
      });

      // 3. Subscribe to Live Hero Banners Stream
      _bannersSubscription = _firebaseService.bannersStream().listen((liveBanners) {
        _banners = liveBanners;
        notifyListeners();
      }, onError: (err) {
        debugPrint("Banners stream note: $err");
      });

      // 4. Subscribe to Live Users Account Stream
      _usersSubscription = _firebaseService.usersStream().listen((liveUsers) {
        _users = liveUsers;
        notifyListeners();
      }, onError: (err) {
        debugPrint("Users stream note: $err");
      });

      // 5. Subscribe to Live Store Settings Stream
      _configSubscription = _firebaseService.storeConfigStream().listen((config) {
        if (config.isNotEmpty) {
          if (config.containsKey('storeName')) _storeName = config['storeName'];
          if (config.containsKey('storeSinhalaName')) _storeSinhalaName = config['storeSinhalaName'];
          if (config.containsKey('whatsappNumber')) _whatsappNumber = config['whatsappNumber'];
          if (config.containsKey('freeShippingThreshold')) {
            _freeShippingThreshold = (config['freeShippingThreshold'] as num).toDouble();
          }
          if (config.containsKey('standardDeliveryFee')) {
            _standardDeliveryFee = (config['standardDeliveryFee'] as num).toDouble();
          }
          if (config.containsKey('activePromos') && config['activePromos'] is Map) {
            _activePromos = (config['activePromos'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
          }
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint("Config stream note: $err");
      });
    } catch (e) {
      debugPrint("Init streams note: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Register New User in Firebase Auth & Firestore DB
  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final user = await _firebaseService.registerUserWithFirebaseAuth(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      if (user != null) {
        if (role == UserRole.admin) {
          _currentNavIndex = 4;
        } else if (role == UserRole.cashier) {
          _currentNavIndex = 1;
        } else {
          _currentNavIndex = 0;
        }

        _saveUserSession(user);
        return true;
      }
    } catch (e) {
      debugPrint("Register user note: $e");
    }
    return false;
  }

  // Social Sign In Handlers (Facebook, Google, Apple ID) via Firebase Auth
  Future<bool> loginWithSocialProvider(String providerName) async {
    try {
      final cleanProvider = providerName.toLowerCase();
      AppUser? user;

      if (cleanProvider == 'facebook') {
        user = await _firebaseService.signInWithFacebookAuth();
      } else if (cleanProvider == 'google') {
        user = await _firebaseService.signInWithGoogleAuth();
      } else {
        final socialEmail = '$cleanProvider@navodyaspices.lk';
        user = await _firebaseService.findUserByEmail(socialEmail);

        if (user == null) {
          user = AppUser(
            id: 'SSO-${DateTime.now().millisecondsSinceEpoch}',
            name: '$providerName Customer',
            email: socialEmail,
            pin: '0000',
            role: UserRole.customer,
            authProvider: cleanProvider,
          );
          await _firebaseService.saveUser(user);
        }
      }

      if (user != null) {
        _currentNavIndex = 0;
        _saveUserSession(user);
        return true;
      }
    } catch (e) {
      debugPrint("Social login error: $e");
    }
    return false;
  }

  // Dynamic Authentication via Firebase Auth & Firestore DB (PIN Code)
  bool loginWithPin(String pin) {
    try {
      final cleanPin = pin.trim();

      final match = _users.where((u) => u.pin == cleanPin);
      if (match.isNotEmpty) {
        final user = match.first;
        if (user.isAdmin) {
          _currentNavIndex = 4;
        } else if (user.isCashier) {
          _currentNavIndex = 1;
        } else {
          _currentNavIndex = 0;
        }
        _saveUserSession(user);
        return true;
      }
    } catch (e) {
      debugPrint("Login with PIN note: $e");
    }
    return false;
  }

  // Dynamic Authentication via Firebase Auth & Firestore DB (Email & Password)
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      final user = await _firebaseService.signInWithFirebaseAuth(
        email: email,
        password: password,
      );

      if (user != null) {
        if (user.isAdmin) {
          _currentNavIndex = 4;
        } else if (user.isCashier) {
          _currentNavIndex = 1;
        } else {
          _currentNavIndex = 0;
        }
        _saveUserSession(user);
        return true;
      }
    } catch (e) {
      debugPrint("Login with Email note: $e");
    }
    return false;
  }

  bool verifyAdminPin(String pin) {
    try {
      final cleanPin = pin.trim();
      final match = _users.where((u) => u.pin == cleanPin && u.isAdmin);
      if (match.isNotEmpty) {
        _currentNavIndex = 4;
        _saveUserSession(match.first);
        return true;
      }
    } catch (e) {
      debugPrint("Verify admin PIN note: $e");
    }
    return false;
  }

  void logout() async {
    try {
      await _firebaseService.signOutFirebaseAuth();
    } catch (_) {}
    _clearUserSession();
    _currentNavIndex = 0;
    _cart.clear();
  }

  void _checkUrlForQrParams() {
    try {
      final Uri uri = Uri.base;
      String? itemId = uri.queryParameters['item'] ?? uri.queryParameters['itemId'] ?? uri.queryParameters['id'];
      String? qtyStr = uri.queryParameters['qty'] ?? uri.queryParameters['quantity'];

      if (itemId != null && itemId.isNotEmpty) {
        int qty = int.tryParse(qtyStr ?? '1') ?? 1;
        handleQrCodeScanned(itemId, qty);
      }
    } catch (e) {
      debugPrint("URL param parsing: $e");
    }
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<SpiceItem> get filteredProducts {
    return _products.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesQuery = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sinhalaName.contains(_searchQuery) ||
          p.id.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  // Cart Operations
  void addToCart(SpiceItem item, {int quantity = 1, String unit = '100g'}) {
    final index = _cart.indexWhere((c) => c.spice.id == item.id && c.selectedUnit == unit);
    if (index >= 0) {
      _cart[index].quantity += quantity;
    } else {
      _cart.add(CartItem(spice: item, quantity: quantity, selectedUnit: unit));
    }
    notifyListeners();
  }

  void updateCartQuantity(SpiceItem item, int delta, {String unit = '100g'}) {
    final index = _cart.indexWhere((c) => c.spice.id == item.id && c.selectedUnit == unit);
    if (index >= 0) {
      _cart[index].quantity += delta;
      if (_cart[index].quantity <= 0) {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  int getCartQuantityForUnit(String itemId, String unit) {
    final index = _cart.indexWhere((c) => c.spice.id == itemId && c.selectedUnit == unit);
    return index >= 0 ? _cart[index].quantity : 0;
  }

  void removeFromCart(SpiceItem item, {String? unit}) {
    if (unit != null) {
      _cart.removeWhere((c) => c.spice.id == item.id && c.selectedUnit == unit);
    } else {
      _cart.removeWhere((c) => c.spice.id == item.id);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _discountPercent = 0.0;
    _appliedCouponCode = null;
    notifyListeners();
  }

  // Real-Time Dynamic Promo Coupon System
  bool applyPromoCoupon(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (_activePromos.containsKey(cleanCode)) {
      final rate = _activePromos[cleanCode]!;
      _discountPercent = rate * 100;
      _appliedCouponCode = '$cleanCode (${(rate * 100).toInt()}% OFF)';
      notifyListeners();
      return true;
    }
    return false;
  }

  void removePromoCoupon() {
    _discountPercent = 0.0;
    _appliedCouponCode = null;
    notifyListeners();
  }

  void setDiscountPercent(double percent) {
    _discountPercent = percent.clamp(0.0, 50.0);
    notifyListeners();
  }

  double get subtotal => _cart.fold(0.0, (sum, item) => sum + item.itemTotal);
  double get discountAmount => subtotal * (_discountPercent / 100);
  double get deliveryFee => (subtotal >= _freeShippingThreshold || _cart.isEmpty) ? 0.0 : _standardDeliveryFee;
  double get grandTotal => (subtotal - discountAmount + deliveryFee).clamp(0.0, double.infinity);

  // Auto Dispatch Order details to WhatsApp
  void dispatchWhatsAppOrder(OrderModel order) {
    try {
      final formatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
      final buffer = StringBuffer();
      buffer.writeln('🌶️ *NEW ONLINE ORDER - $_storeName*');
      buffer.writeln('-----------------------------------');
      buffer.writeln('*Order ID:* ${order.id}');
      buffer.writeln('*Customer Name:* ${order.customerName ?? "Guest Shopper"}');
      if (order.notes != null && order.notes!.isNotEmpty) {
        buffer.writeln('*Address/Notes:* ${order.notes}');
      }
      buffer.writeln('*Payment Method:* ${order.paymentMethod}');
      buffer.writeln('-----------------------------------');
      buffer.writeln('*Spices Ordered:*');

      for (var item in order.items) {
        buffer.writeln('• ${item.spice.name} (${item.spice.unit}) x${item.quantity} = ${formatter.format(item.itemTotal)}');
      }

      buffer.writeln('-----------------------------------');
      buffer.writeln('*Subtotal:* ${formatter.format(order.subtotal)}');
      if (order.discount > 0) {
        buffer.writeln('*Discount:* -${formatter.format(order.discount)}');
      }
      buffer.writeln('*GRAND TOTAL:* ${formatter.format(order.totalAmount)}');

      final cleanWa = _whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final countryWa = cleanWa.startsWith('0') ? '94${cleanWa.substring(1)}' : cleanWa;
      final encodedText = Uri.encodeComponent(buffer.toString());
      final whatsappUrl = 'https://wa.me/$countryWa?text=$encodedText';

      web.window.open(whatsappUrl, '_blank');
    } catch (e) {
      debugPrint("WhatsApp dispatch note: $e");
    }
  }

  // Instant Checkout & Live Firebase Persistence
  Future<OrderModel?> processCheckout({
    required String paymentMethod,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? deliveryAddress,
    String? city,
    String? notes,
  }) async {
    if (_cart.isEmpty) return null;

    final orderId = 'ORD-${1000 + _orders.length + 1}';
    final order = OrderModel(
      id: orderId,
      items: List.from(_cart),
      subtotal: subtotal,
      discount: discountAmount,
      tax: 0.0,
      totalAmount: grandTotal,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      status: 'Pending',
      userId: _currentUser?.id,
      customerName: customerName ?? _currentUser?.name ?? 'Guest Shopper',
      customerEmail: customerEmail ?? _currentUser?.email,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      city: city,
      notes: notes,
    );

    // Save Order directly into Firebase Firestore DB
    await _firebaseService.saveOrder(order);

    // Update stock live in Firestore DB
    for (var cartItem in _cart) {
      final index = _products.indexWhere((p) => p.id == cartItem.spice.id);
      if (index >= 0) {
        final current = _products[index];
        final newStock = (current.stock - cartItem.quantity).clamp(0, 9999);
        final updatedSpice = SpiceItem(
          id: current.id,
          name: current.name,
          sinhalaName: current.sinhalaName,
          category: current.category,
          price: current.price,
          unit: current.unit,
          stock: newStock,
          imageUrl: current.imageUrl,
          description: current.description,
          rating: current.rating,
          isPopular: current.isPopular,
        );

        await _firebaseService.saveProduct(updatedSpice);

        if (newStock < 50) {
          _notificationService.showPushNotification(
            title: '⚠️ LOW STOCK ALERT: ${current.name}',
            body: 'Only $newStock units remaining in inventory.',
          );
        }
      }
    }

    // Trigger Browser Push Notification for New Order
    final formatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
    _notificationService.showPushNotification(
      title: '🔔 NEW ONLINE ORDER: ${order.id}',
      body: 'Customer: ${order.customerName} • Total: ${formatter.format(order.totalAmount)}',
    );

    // Automatically dispatch order details to WhatsApp if requested or COD/WhatsApp Direct
    dispatchWhatsAppOrder(order);

    clearCart();
    notifyListeners();
    return order;
  }

  // 1-Click Reorder feature: populates cart with items from a past order
  void reorderPastOrder(OrderModel pastOrder) {
    _cart.clear();
    for (var item in pastOrder.items) {
      // Find matching current catalog product to get latest price & stock
      final matchIdx = _products.indexWhere((p) => p.id == item.spice.id);
      final SpiceItem currentSpice = matchIdx >= 0 ? _products[matchIdx] : item.spice;
      _cart.add(CartItem(spice: currentSpice, quantity: item.quantity));
    }
    notifyListeners();
  }

  // Cancel Pending Order in Firebase Firestore
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, 'Cancelled');
  }

  // QR Scanning & Direct Item Buy trigger
  void handleQrCodeScanned(String rawData, [int defaultQty = 1]) {
    String itemId = rawData;

    if (rawData.contains('NAV_SPICE:')) {
      final parts = rawData.split(':');
      if (parts.length >= 2) {
        itemId = parts[1];
      }
    } else if (rawData.contains('item=')) {
      final uri = Uri.tryParse(rawData);
      if (uri != null) {
        itemId = uri.queryParameters['item'] ?? rawData;
        if (uri.queryParameters.containsKey('qty')) {
          defaultQty = int.tryParse(uri.queryParameters['qty']!) ?? defaultQty;
        }
      }
    }

    if (_products.isEmpty) return;

    final match = _products.where((p) => p.id.toUpperCase() == itemId.toUpperCase());
    final spice = match.isNotEmpty ? match.first : _products.first;

    _scannedSpiceItem = spice;
    _scannedQuantity = defaultQty;
    _showDirectBuyDialog = true;
    notifyListeners();
  }

  void closeDirectBuyDialog() {
    _showDirectBuyDialog = false;
    _scannedSpiceItem = null;
    notifyListeners();
  }

  void updateScannedQuantity(int delta) {
    if (_scannedSpiceItem != null) {
      _scannedQuantity = (_scannedQuantity + delta).clamp(1, _scannedSpiceItem!.stock.clamp(1, 99));
      notifyListeners();
    }
  }

  Future<void> clearSampleData() async {
    _products.clear();
    _orders.clear();
    _banners.clear();
    notifyListeners();
  }

  // Seed Default Spices & Hero Banners directly into Firebase Firestore DB
  Future<void> seedFirestoreCatalog() async {
    _isLoading = true;
    notifyListeners();

    await _firebaseService.seedInitialSpicesCatalog();
    await _firebaseService.seedInitialBanners();

    _isLoading = false;
    notifyListeners();
  }

  // Product CRUD Operations in Firestore DB
  Future<void> addOrUpdateProduct(SpiceItem product) async {
    await _firebaseService.saveProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await _firebaseService.deleteProduct(productId);
  }

  // Banner CRUD Operations in Firestore DB
  Future<void> addOrUpdateBanner(BannerModel banner) async {
    await _firebaseService.saveBanner(banner);
  }

  Future<void> toggleBannerStatus(String bannerId) async {
    final index = _banners.indexWhere((b) => b.id == bannerId);
    if (index >= 0) {
      final old = _banners[index];
      final updated = BannerModel(
        id: old.id,
        title: old.title,
        subtitle: old.subtitle,
        imageUrl: old.imageUrl,
        discountCode: old.discountCode,
        buttonText: old.buttonText,
        isActive: !old.isActive,
        createdAt: old.createdAt,
      );
      await _firebaseService.saveBanner(updated);
    }
  }

  Future<void> deleteBanner(String bannerId) async {
    await _firebaseService.deleteBanner(bannerId);
  }

  // Order Status Pipeline Update in Firestore DB
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firebaseService.updateOrderStatus(orderId, newStatus);
    _notificationService.showPushNotification(
      title: '🚚 ORDER STATUS UPDATED: $orderId',
      body: 'Status changed to: $newStatus',
    );
  }

  // Store Configuration Update in Firestore DB
  Future<void> updateStoreConfig({
    String? name,
    String? sinhalaName,
    String? whatsapp,
    double? freeShipping,
    double? deliveryFee,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['storeName'] = name;
    if (sinhalaName != null) updates['storeSinhalaName'] = sinhalaName;
    if (whatsapp != null) updates['whatsappNumber'] = whatsapp;
    if (freeShipping != null) updates['freeShippingThreshold'] = freeShipping;
    if (deliveryFee != null) updates['standardDeliveryFee'] = deliveryFee;

    await _firebaseService.updateStoreConfig(updates);
  }

  String generateCsvReportContent() {
    final buffer = StringBuffer();
    buffer.writeln('Order ID,Date Time,Customer Name,Items Purchased,Payment Method,Status,Subtotal (LKR),Discount (LKR),Grand Total (LKR)');

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (var order in _orders) {
      final itemsStr = order.items.map((i) => '${i.spice.name} x${i.quantity}').join(' ; ');
      final customer = (order.customerName ?? 'Guest Shopper').replaceAll(',', ' ');
      final dateStr = dateFormat.format(order.createdAt);

      buffer.writeln('${order.id},"$dateStr","$customer","$itemsStr",${order.paymentMethod},${order.status},${order.subtotal},${order.discount},${order.totalAmount}');
    }
    return buffer.toString();
  }
}
