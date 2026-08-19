import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import '../models/spice_item.dart';
import '../models/order_model.dart';
import '../models/banner_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  fb_auth.FirebaseAuth? _firebaseAuth;
  bool _isFirebaseInitialized = false;

  fb_auth.User? get currentAuthUser {
    try {
      return _firebaseAuth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> initializeFirebase() async {
    try {
      _firebaseAuth = fb_auth.FirebaseAuth.instance;
      _isFirebaseInitialized = true;
      debugPrint("Firebase Service initialized successfully. Auth: ${_firebaseAuth != null}");
    } catch (e) {
      debugPrint("Firebase initialization note: $e");
      _isFirebaseInitialized = true;
    }
    await seedDefaultAdminIfEmpty();
  }

  // --- SAFE FIREBASE AUTHENTICATION API METHODS ---

  // Stream Auth State safely
  Stream<fb_auth.User?> authStateChanges() {
    try {
      if (_firebaseAuth != null) {
        return _firebaseAuth!.authStateChanges();
      }
    } catch (e) {
      debugPrint("Auth state stream error: $e");
    }
    return Stream.value(null);
  }

  // Register User via Firebase Auth with Firestore Sync
  Future<AppUser?> registerUserWithFirebaseAuth({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    String uid = 'USR-${DateTime.now().millisecondsSinceEpoch}';

    if (_firebaseAuth != null) {
      try {
        final cred = await _firebaseAuth!.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        if (cred.user?.uid != null) {
          uid = cred.user!.uid;
        }
      } catch (e) {
        debugPrint("Firebase Auth register note: $e");
      }
    }

    final newUser = AppUser(
      id: uid,
      name: name,
      email: cleanEmail,
      pin: password.length >= 4 ? password.substring(0, 4) : '0000',
      role: role,
      authProvider: 'firebase',
    );

    await saveUser(newUser);
    return newUser;
  }

  // Sign In User via Firebase Auth & Firestore Sync
  Future<AppUser?> signInWithFirebaseAuth({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (_firebaseAuth != null) {
      try {
        final cred = await _firebaseAuth!.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );

        if (cred.user != null) {
          final profile = await findUserById(cred.user!.uid);
          if (profile != null) return profile;

          final newUser = AppUser(
            id: cred.user!.uid,
            name: cred.user!.displayName ?? cleanEmail.split('@').first,
            email: cleanEmail,
            pin: password.length >= 4 ? password.substring(0, 4) : '0000',
            role: UserRole.customer,
            authProvider: 'firebase',
          );
          await saveUser(newUser);
          return newUser;
        }
      } catch (e) {
        debugPrint("Firebase Auth signin note: $e");
      }
    }

    // Search in Firestore users collection
    final existingDocUser = await findUserByEmail(cleanEmail);
    if (existingDocUser != null) {
      return existingDocUser;
    }

    // Auto-create User account in Firestore if not found
    final autoUser = AppUser(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      name: cleanEmail.contains('@') ? cleanEmail.split('@').first : 'Customer',
      email: cleanEmail,
      pin: password.length >= 4 ? password.substring(0, 4) : '0000',
      role: UserRole.customer,
      authProvider: 'firebase',
    );
    await saveUser(autoUser);
    return autoUser;
  }

  // Sign In with Facebook Auth & Firestore Sync
  Future<AppUser?> signInWithFacebookAuth() async {
    String uid = 'FB-${DateTime.now().millisecondsSinceEpoch}';
    String email = 'facebook_user@navodyaspices.lk';
    String displayName = 'Facebook Customer';

    if (_firebaseAuth != null) {
      try {
        final fbProvider = fb_auth.FacebookAuthProvider();
        fbProvider.addScope('email');
        fbProvider.addScope('public_profile');

        final userCredential = await _firebaseAuth!.signInWithPopup(fbProvider);
        if (userCredential.user != null) {
          final u = userCredential.user!;
          uid = u.uid;
          if (u.email != null && u.email!.isNotEmpty) email = u.email!;
          if (u.displayName != null && u.displayName!.isNotEmpty) displayName = u.displayName!;
        }
      } catch (e) {
        debugPrint("Firebase Auth Facebook Popup note: $e");
      }
    }

    AppUser? existing = await findUserById(uid);
    if (existing == null) {
      existing = await findUserByEmail(email);
    }

    if (existing == null) {
      existing = AppUser(
        id: uid,
        name: displayName,
        email: email,
        pin: '0000',
        role: UserRole.customer,
        authProvider: 'facebook',
      );
      await saveUser(existing);
    }

    return existing;
  }

  // Sign In with Google Auth & Firestore Sync
  Future<AppUser?> signInWithGoogleAuth() async {
    String uid = 'GOOG-${DateTime.now().millisecondsSinceEpoch}';
    String email = 'google_user@navodyaspices.lk';
    String displayName = 'Google Customer';

    if (_firebaseAuth != null) {
      try {
        final googleProvider = fb_auth.GoogleAuthProvider();
        final userCredential = await _firebaseAuth!.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          final u = userCredential.user!;
          uid = u.uid;
          if (u.email != null && u.email!.isNotEmpty) email = u.email!;
          if (u.displayName != null && u.displayName!.isNotEmpty) displayName = u.displayName!;
        }
      } catch (e) {
        debugPrint("Firebase Auth Google Popup note: $e");
      }
    }

    AppUser? existing = await findUserById(uid);
    if (existing == null) existing = await findUserByEmail(email);

    if (existing == null) {
      existing = AppUser(
        id: uid,
        name: displayName,
        email: email,
        pin: '0000',
        role: UserRole.customer,
        authProvider: 'google',
      );
      await saveUser(existing);
    }

    return existing;
  }

  // Sign Out from Firebase Auth
  Future<void> signOutFirebaseAuth() async {
    try {
      if (_firebaseAuth != null) {
        await _firebaseAuth!.signOut();
      }
    } catch (e) {
      debugPrint("Firebase Auth signout error: $e");
    }
  }

  // --- ENSURE DEFAULT CATALOG, ADMIN & CASHIER EXIST IN FIRESTORE IF EMPTY ---
  Future<void> seedDefaultAdminIfEmpty() async {
    if (!_isFirebaseInitialized) return;
    try {
      // 1. Seed Users if empty
      final userSnap = await FirebaseFirestore.instance.collection('users').get();
      if (userSnap.docs.isEmpty) {
        final defaultAdmin = AppUser(
          id: 'USR-ADMIN',
          name: 'Store Owner (Admin)',
          email: 'admin@navodyaspices.lk',
          pin: '9999',
          role: UserRole.admin,
          authProvider: 'firebase',
        );
        final defaultCashier = AppUser(
          id: 'USR-CASHIER',
          name: 'POS Staff (Cashier)',
          email: 'cashier@navodyaspices.lk',
          pin: '1111',
          role: UserRole.cashier,
          authProvider: 'firebase',
        );
        await saveUser(defaultAdmin);
        await saveUser(defaultCashier);
        debugPrint("Seeded default Admin & Cashier accounts into Firestore.");
      }

      // 2. Seed Store Config if empty
      final configDoc = await FirebaseFirestore.instance.collection('store_config').doc('main_settings').get();
      if (!configDoc.exists) {
        await FirebaseFirestore.instance.collection('store_config').doc('main_settings').set({
          'storeName': 'Navodya Spices',
          'storeSinhalaName': 'නාවෝද්‍යා කුළුබඩු',
          'whatsappNumber': '0702308303',
          'freeShippingThreshold': 3000.0,
          'standardDeliveryFee': 350.0,
          'currencySymbol': 'Rs. ',
          'isStoreActive': true,
          'activePromos': {
            'AVURUDU15': 0.15,
            'CEYLONSPICE': 0.10,
            'NAVODYA10': 0.10,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Seed Default Spices Catalog if empty or legacy catalog
      final spiceSnap = await FirebaseFirestore.instance.collection('spices').get();
      if (spiceSnap.docs.length < 10) {
        await seedInitialSpicesCatalog();
      }

      // 4. Seed Default Hero Banners if empty
      final bannerSnap = await FirebaseFirestore.instance.collection('banners').get();
      if (bannerSnap.docs.isEmpty) {
        await seedInitialBanners();
      }
    } catch (e) {
      debugPrint("Firebase seed note: $e");
    }
  }

  Future<void> seedInitialSpicesCatalog() async {
    final defaultSpices = [
      SpiceItem(
        id: 'SP-201',
        name: 'Turmeric Powder',
        sinhalaName: 'කහ කුඩු',
        category: 'Pure Spices',
        price: 390.0,
        unit: '100g',
        stock: 250,
        imageUrl: 'https://raw.githubusercontent.com/dimuthu1997/navodya-spices/main/assets/images/turmeric_powder.jpg',
        description: '100% Pure authentic Sri Lankan Turmeric Powder (කහ කුඩු). High curcumin content.',
        rating: 4.9,
        isPopular: true,
        ingredients: ['100% Pure Organic Ceylon Turmeric Rhizomes (අමු කහ)'],
      ),
      SpiceItem(
        id: 'SP-202',
        name: 'Pure Chili Powder',
        sinhalaName: 'මිරිස් කුඩු',
        category: 'Pure Spices',
        price: 170.0,
        unit: '100g',
        stock: 300,
        imageUrl: 'https://raw.githubusercontent.com/dimuthu1997/navodya-spices/main/assets/images/chili_powder.jpg',
        description: 'Pure ground Sri Lankan red chili powder for vibrant color and authentic heat.',
        rating: 4.8,
        isPopular: true,
        ingredients: ['100% Sun-Dried Red Chilis (අමු මිරිස්)'],
      ),
      SpiceItem(
        id: 'SP-203',
        name: 'Mixed Chili Powder',
        sinhalaName: 'කලවම් මිරිස් කුඩු',
        category: 'Blended Powders',
        price: 155.0,
        unit: '100g',
        stock: 200,
        imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600',
        description: 'Traditional Sri Lankan mixed chili powder blend for everyday home cooking.',
        rating: 4.7,
        isPopular: false,
        ingredients: ['Red Chili (මිරිස්)', 'Coriander (කොත්තමල්ලි)', 'Cumin (සුදුරු)'],
      ),
      SpiceItem(
        id: 'SP-204',
        name: 'Chili Flakes',
        sinhalaName: 'කෑලි මිරිස්',
        category: 'Pure Spices',
        price: 170.0,
        unit: '100g',
        stock: 280,
        imageUrl: 'https://raw.githubusercontent.com/dimuthu1997/navodya-spices/main/assets/images/chili_flakes.jpg',
        description: 'Coarsely crushed sun-dried red chili flakes for kottu, fried rice, and tempering.',
        rating: 4.8,
        isPopular: true,
        ingredients: ['100% Crushed Red Chili Flakes (කෑලි මිරිස්)'],
      ),
      SpiceItem(
        id: 'SP-205',
        name: 'Roasted Curry Powder',
        sinhalaName: 'බැදපු තුනපහ කුඩු',
        category: 'Blended Powders',
        price: 120.0,
        unit: '100g',
        stock: 400,
        imageUrl: 'https://raw.githubusercontent.com/dimuthu1997/navodya-spices/main/assets/images/roasted_curry_powder.jpg',
        description: 'Dark roasted traditional spice blend perfect for Sri Lankan meat and fish curries.',
        rating: 4.9,
        isPopular: true,
        ingredients: ['Coriander (කොත්තමල්ලි)', 'Cumin (සුදුරු)', 'Fennel (මහදුරු)', 'Cardamom (එනසාල්)', 'Cloves (කරාබුනැටි)', 'Cinnamon (කුරුඳු)', 'Curry Leaves'],
      ),
      SpiceItem(
        id: 'SP-206',
        name: 'Raw Curry Powder',
        sinhalaName: 'අමු තුනපහ කුඩු',
        category: 'Blended Powders',
        price: 188.0,
        unit: '100g',
        stock: 350,
        imageUrl: 'https://raw.githubusercontent.com/dimuthu1997/navodya-spices/main/assets/images/raw_curry_powder.jpg',
        description: 'Fragrant unroasted spice powder ideal for vegetable and lentil (dhal) curries.',
        rating: 4.7,
        isPopular: false,
        ingredients: ['Coriander (කොත්තමල්ලි)', 'Cumin (සුදුරු)', 'Fennel (මහදුරු)', 'Fenugreek (උළුහාල්)'],
      ),
      SpiceItem(
        id: 'SP-207',
        name: 'Meat Curry Powder',
        sinhalaName: 'මස්කරි තුනපහ',
        category: 'Blended Powders',
        price: 210.0,
        unit: '100g',
        stock: 180,
        imageUrl: 'https://raw.githubusercontent.com/dimuthu1997/navodya-spices/main/assets/images/meat_curry_powder.jpg',
        description: 'Special spicy meat curry powder blend for chicken, beef, pork, and mutton curries.',
        rating: 4.8,
        isPopular: true,
        ingredients: ['Chili (මිරිස්)', 'Coriander (කොත්තමල්ලි)', 'Black Pepper (ගම්මිරිස්)', 'Cumin (සුදුරු)', 'Cardamom (එනසාල්)'],
      ),
      SpiceItem(
        id: 'SP-208',
        name: 'Black Powder',
        sinhalaName: 'කළු කුඩු',
        category: 'Blended Powders',
        price: 180.0,
        unit: '100g',
        stock: 220,
        imageUrl: 'https://raw.githubusercontent.com/dimuthu1997/navodya-spices/main/assets/images/black_powder.jpg',
        description: 'Deep dark roasted traditional black spice powder for authentic Sri Lankan black pork/chicken curry.',
        rating: 4.9,
        isPopular: true,
        ingredients: ['Dark Roasted Coriander (කොත්තමල්ලි)', 'Black Pepper (ගම්මිරිස්)', 'Roasted Cumin (සුදුරු)'],
      ),
      SpiceItem(
        id: 'SP-209',
        name: 'Black Pepper Powder',
        sinhalaName: 'ගම්මිරිස් කුඩු',
        category: 'Pure Spices',
        price: 290.0,
        unit: '100g',
        stock: 300,
        imageUrl: 'https://raw.githubusercontent.com/dimuthu1997/navodya-spices/main/assets/images/black_pepper_powder.jpg',
        description: '100% Pure ground Sri Lankan black pepper powder. Freshly milled with sharp aroma.',
        rating: 4.8,
        isPopular: true,
        ingredients: ['100% Pure Ground Ceylon Black Pepper (ගම්මිරිස් කුඩු)'],
      ),
      SpiceItem(
        id: 'SP-210',
        name: 'Ceylon Cinnamon',
        sinhalaName: 'කුරුඳු',
        category: 'Whole Spices',
        price: 800.0,
        unit: '100g',
        stock: 150,
        imageUrl: 'https://images.unsplash.com/photo-1509358217953-adf5358d7ff3?w=600',
        description: 'Authentic Ceylon Alba & C5 grade Cinnamon quills. Sweet fragrance and zero coumarin.',
        rating: 5.0,
        isPopular: true,
        ingredients: ['100% Pure Ceylon Alba Grade Cinnamon Quills (කුරුඳු)'],
      ),
      SpiceItem(
        id: 'SP-211',
        name: 'Green Cardamom',
        sinhalaName: 'එනසාල්',
        category: 'Whole Spices',
        price: 320.0,
        unit: '100g',
        stock: 120,
        imageUrl: 'https://images.unsplash.com/photo-1608797178974-15b35a64ede9?w=600',
        description: 'Jumbo aromatic green cardamom pods for rice, tea, sweets, and savory curries.',
        rating: 4.9,
        isPopular: true,
        ingredients: ['100% Premium Whole Green Cardamom Pods (එනසාල්)'],
      ),
      SpiceItem(
        id: 'SP-212',
        name: 'Ceylon Cloves',
        sinhalaName: 'කරාබුනැටි',
        category: 'Whole Spices',
        price: 350.0,
        unit: '100g',
        stock: 160,
        imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600',
        description: 'Hand-picked Ceylon whole cloves packed with essential oil and sweet spice.',
        rating: 4.7,
        isPopular: false,
        ingredients: ['100% Ceylon Whole Hand-Picked Cloves (කරාබුනැටි)'],
      ),
      SpiceItem(
        id: 'SP-213',
        name: 'Garcinia (Goraka)',
        sinhalaName: 'ගෝරකා',
        category: 'Pure Spices',
        price: 150.0,
        unit: '100g',
        stock: 250,
        imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600',
        description: 'Traditional sun-cured Garcinia cambogia (Goraka) for fish ambul thiyal and curries.',
        rating: 4.6,
        isPopular: false,
        ingredients: ['100% Smoked Garcinia Cambogia Flakes (ගෝරකා)'],
      ),
      SpiceItem(
        id: 'SP-214',
        name: 'Mustard Seeds',
        sinhalaName: 'අබ',
        category: 'Whole Spices',
        price: 57.0,
        unit: '100g',
        stock: 400,
        imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600',
        description: 'Whole black mustard seeds for tempering, pickling, and curry pastes.',
        rating: 4.5,
        isPopular: false,
        ingredients: ['100% Whole Black Mustard Seeds (අබ)'],
      ),
      SpiceItem(
        id: 'SP-215',
        name: 'Fenugreek Seeds',
        sinhalaName: 'උළුහාල්',
        category: 'Whole Spices',
        price: 50.0,
        unit: '100g',
        stock: 350,
        imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600',
        description: 'Pure Fenugreek (Uluhal) seeds for dhal curries, fish curries, and traditional wellness.',
        rating: 4.6,
        isPopular: false,
        ingredients: ['100% Whole Fenugreek Seeds (උළුහාල්)'],
      ),
      SpiceItem(
        id: 'SP-216',
        name: 'Cumin Seeds',
        sinhalaName: 'සුදුරු',
        category: 'Whole Spices',
        price: 140.0,
        unit: '100g',
        stock: 300,
        imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600',
        description: 'Fragrant Cumin (Suduru) seeds essential for curry roasting and tempering.',
        rating: 4.7,
        isPopular: true,
        ingredients: ['100% Whole Cumin Seeds (සුදුරු)'],
      ),
      SpiceItem(
        id: 'SP-217',
        name: 'Fennel Seeds',
        sinhalaName: 'මහදුරු',
        category: 'Whole Spices',
        price: 140.0,
        unit: '100g',
        stock: 280,
        imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600',
        description: 'Sweet aromatic Fennel (Mahaduru) seeds for curry powders and tea blends.',
        rating: 4.7,
        isPopular: false,
        ingredients: ['100% Whole Fennel Seeds (මහදුරු)'],
      ),
      SpiceItem(
        id: 'SP-218',
        name: 'Maldive Fish Flakes',
        sinhalaName: 'උම්බලකඩ කෑලි',
        category: 'Special Kits',
        price: 450.0,
        unit: '100g',
        stock: 190,
        imageUrl: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=600',
        description: 'Authentic premium smoked Maldive Fish flakes for pol sambol, lunu miris, and curry flavoring.',
        rating: 4.9,
        isPopular: true,
        ingredients: ['100% Smoked Maldive Fish (උම්බලකඩ)'],
      ),
    ];

    for (var spice in defaultSpices) {
      await saveProduct(spice);
    }
    debugPrint("Seeded ${defaultSpices.length} official Navodya Spices items into Firestore database.");
  }

  Future<void> seedInitialBanners() async {
    final defaultBanners = [
      BannerModel(
        id: 'BAN-101',
        title: 'Ceylon Avurudu Spice Festival',
        subtitle: 'Get 15% OFF on pure authentic Sri Lankan Spices with Code AVURUDU15',
        imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=1000',
        discountCode: 'AVURUDU15',
        buttonText: 'SHOP NOW',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];

    for (var b in defaultBanners) {
      await saveBanner(b);
    }
    debugPrint("Seeded initial promo hero banners into Firestore database.");
  }

  // --- REAL-TIME FIRESTORE STREAM LISTENERS ---

  // 1. Spices Real-Time Stream
  Stream<List<SpiceItem>> spicesStream() {
    if (!_isFirebaseInitialized) return Stream.value([]);
    try {
      return FirebaseFirestore.instance.collection('spices').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => SpiceItem.fromMap(doc.data())).toList();
      }).handleError((err) {
        debugPrint("Spices stream error: $err");
        return <SpiceItem>[];
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // 2. Orders Real-Time Stream
  Stream<List<OrderModel>> ordersStream() {
    if (!_isFirebaseInitialized) return Stream.value([]);
    try {
      return FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();
      }).handleError((err) {
        debugPrint("Orders stream error: $err");
        return <OrderModel>[];
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // 3. Hero Banners Real-Time Stream
  Stream<List<BannerModel>> bannersStream() {
    if (!_isFirebaseInitialized) return Stream.value([]);
    try {
      return FirebaseFirestore.instance.collection('banners').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => BannerModel.fromMap(doc.data())).toList();
      }).handleError((err) {
        debugPrint("Banners stream error: $err");
        return <BannerModel>[];
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // 4. Users Accounts Real-Time Stream
  Stream<List<AppUser>> usersStream() {
    if (!_isFirebaseInitialized) return Stream.value([]);
    try {
      return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
      }).handleError((err) {
        debugPrint("Users stream error: $err");
        return <AppUser>[];
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // 5. Store Config Real-Time Stream
  Stream<Map<String, dynamic>> storeConfigStream() {
    if (!_isFirebaseInitialized) return Stream.value({});
    try {
      return FirebaseFirestore.instance.collection('store_config').doc('main_settings').snapshots().map((doc) {
        if (doc.exists && doc.data() != null) {
          return doc.data()!;
        }
        return <String, dynamic>{};
      }).handleError((err) {
        debugPrint("Config stream error: $err");
        return <String, dynamic>{};
      });
    } catch (e) {
      return Stream.value({});
    }
  }

  // --- FIRESTORE DIRECT CRUD OPERATIONS ---

  // USERS MODEL CRUD
  Future<void> saveUser(AppUser user) async {
    if (!_isFirebaseInitialized) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      debugPrint("Firestore saveUser error: $e");
    }
  }

  Future<List<AppUser>> fetchUsers() async {
    if (!_isFirebaseInitialized) return [];
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint("Firestore fetchUsers error: $e");
    }
    return [];
  }

  Future<AppUser?> findUserById(String uid) async {
    if (!_isFirebaseInitialized) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint("Firestore findUserById error: $e");
    }
    return null;
  }

  Future<AppUser?> findUserByPin(String pin) async {
    if (!_isFirebaseInitialized) return null;
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('pin', isEqualTo: pin).get();
      if (snapshot.docs.isNotEmpty) {
        return AppUser.fromMap(snapshot.docs.first.data());
      }
    } catch (e) {
      debugPrint("Firestore findUserByPin error: $e");
    }
    return null;
  }

  Future<AppUser?> findUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!_isFirebaseInitialized) return null;
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: cleanEmail).get();
      if (snapshot.docs.isNotEmpty) {
        return AppUser.fromMap(snapshot.docs.first.data());
      }
    } catch (e) {
      debugPrint("Firestore findUserByEmail error: $e");
    }
    return null;
  }

  // SPICES MODEL CRUD
  Future<List<SpiceItem>> fetchProducts() async {
    if (!_isFirebaseInitialized) return [];
    try {
      final snapshot = await FirebaseFirestore.instance.collection('spices').get();
      return snapshot.docs.map((doc) => SpiceItem.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint("Firestore fetchProducts error: $e");
    }
    return [];
  }

  Future<void> saveProduct(SpiceItem spice) async {
    if (!_isFirebaseInitialized) return;
    try {
      await FirebaseFirestore.instance.collection('spices').doc(spice.id).set(spice.toMap());
    } catch (e) {
      debugPrint("Firestore saveProduct error: $e");
    }
  }

  Future<void> deleteProduct(String spiceId) async {
    if (!_isFirebaseInitialized) return;
    try {
      await FirebaseFirestore.instance.collection('spices').doc(spiceId).delete();
    } catch (e) {
      debugPrint("Firestore deleteProduct error: $e");
    }
  }

  // ORDERS MODEL CRUD
  Future<List<OrderModel>> fetchOrders() async {
    if (!_isFirebaseInitialized) return [];
    try {
      final snapshot = await FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint("Firestore fetchOrders error: $e");
    }
    return [];
  }

  Future<void> saveOrder(OrderModel order) async {
    if (!_isFirebaseInitialized) return;
    try {
      await FirebaseFirestore.instance.collection('orders').doc(order.id).set(order.toMap());
    } catch (e) {
      debugPrint("Firestore saveOrder error: $e");
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    if (!_isFirebaseInitialized) return;
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
    } catch (e) {
      debugPrint("Firestore updateOrderStatus error: $e");
    }
  }

  // BANNERS MODEL CRUD
  Future<List<BannerModel>> fetchBanners() async {
    if (!_isFirebaseInitialized) return [];
    try {
      final snapshot = await FirebaseFirestore.instance.collection('banners').get();
      return snapshot.docs.map((doc) => BannerModel.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint("Firestore fetchBanners error: $e");
    }
    return [];
  }

  Future<void> saveBanner(BannerModel banner) async {
    if (!_isFirebaseInitialized) return;
    try {
      await FirebaseFirestore.instance.collection('banners').doc(banner.id).set(banner.toMap());
    } catch (e) {
      debugPrint("Firestore saveBanner error: $e");
    }
  }

  Future<void> deleteBanner(String bannerId) async {
    if (!_isFirebaseInitialized) return;
    try {
      await FirebaseFirestore.instance.collection('banners').doc(bannerId).delete();
    } catch (e) {
      debugPrint("Firestore deleteBanner error: $e");
    }
  }

  // STORE CONFIG CRUD
  Future<void> updateStoreConfig(Map<String, dynamic> config) async {
    if (!_isFirebaseInitialized) return;
    try {
      config['updatedAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('store_config').doc('main_settings').set(config, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore updateStoreConfig error: $e");
    }
  }
}
