import 'spice_item.dart';

class CartItem {
  final SpiceItem spice;
  int quantity;
  String selectedUnit;

  CartItem({
    required this.spice,
    required this.quantity,
    this.selectedUnit = '100g',
  });

  double get unitPrice => spice.getPriceForWeight(selectedUnit);

  double get itemTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'spiceId': spice.id,
      'spiceName': spice.name,
      'spiceSinhalaName': spice.sinhalaName,
      'price': unitPrice,
      'unit': selectedUnit,
      'quantity': quantity,
      'itemTotal': itemTotal,
      'imageUrl': spice.imageUrl,
    };
  }
}

class OrderModel {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double totalAmount;
  final String paymentMethod; // 'Cash on Delivery', 'Card Direct', 'Bank Transfer', 'WhatsApp Direct', 'QR Payment'
  final DateTime createdAt;
  final String status; // 'Pending', 'Confirmed', 'Processing', 'Dispatched', 'Delivered', 'Cancelled'
  final String? userId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? city;
  final String? notes;

  OrderModel({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    this.status = 'Pending',
    this.userId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.deliveryAddress,
    this.city,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'city': city,
      'notes': notes,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawItems = (map['items'] as List<dynamic>?) ?? [];
    final cartItems = rawItems.map((itemMap) {
      final m = itemMap as Map<String, dynamic>;
      final spice = SpiceItem(
        id: m['spiceId'] ?? '',
        name: m['spiceName'] ?? 'Unknown Spice',
        sinhalaName: m['spiceSinhalaName'] ?? '',
        category: 'Spice',
        price: (m['price'] as num?)?.toDouble() ?? 0.0,
        unit: m['unit'] ?? '100g',
        stock: 100,
        imageUrl: m['imageUrl'] ?? '',
        description: '',
      );
      return CartItem(
        spice: spice,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    return OrderModel(
      id: docId ?? map['id'] ?? '',
      items: cartItems,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash on Delivery',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      status: map['status'] ?? 'Pending',
      userId: map['userId'],
      customerName: map['customerName'],
      customerEmail: map['customerEmail'],
      customerPhone: map['customerPhone'],
      deliveryAddress: map['deliveryAddress'],
      city: map['city'],
      notes: map['notes'],
    );
  }

  // Returns tracking step index (0: Placed, 1: Confirmed, 2: Processing, 3: Dispatched, 4: Delivered)
  int get statusStepIndex {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'processing':
      case 'packing':
        return 2;
      case 'dispatched':
      case 'on the way':
        return 3;
      case 'delivered':
      case 'completed':
        return 4;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }
}

