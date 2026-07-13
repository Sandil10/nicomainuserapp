import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'dart:async';
import 'cart.dart';
import 'settings_user.dart';
import 'about.dart';
import 'app_localization.dart';
import 'ads_banner_widget.dart';
import 'shop_detail_page.dart';
import 'location_picker_screen.dart';
import 'models/restaurant_model.dart';
import 'order_status_screen.dart';
import 'services/user_location.dart';
import 'widgets/app_image.dart';

class UserPanel extends StatefulWidget {
  final List<Map<String, dynamic>>? initialCartItems;
  final int? initialIndex;

  const UserPanel({
    Key? key,
    this.initialCartItems,
    this.initialIndex,
  }) : super(key: key);

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _darkMode = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ===== PURPLE THEME TOKENS (only visual change) =====
  static const Color primaryPurple = Color(0xFF4A22A8);
  static const Color softPurple = Color(0xFFF0ECF8);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> cartItems = [];

  // ===== Real-time Menu data =====
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSubCategory = 'All';

  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;
  StreamSubscription<QuerySnapshot>? _categoriesSub;

  List<Restaurant> _restaurants = [];
  bool _loadingRestaurants = true;
  StreamSubscription<QuerySnapshot>? _restaurantsSub;

  // ===== Ongoing order tracking =====
  // Statuses that count as an active/ongoing order (not yet delivered).
  static const List<String> _activeStatuses = [
    'confirmed',
    'processing',
    'received',
    'preparing',
    'ready',
    'finding_rider',
    'picked_up',
    'on_the_way',
  ];
  String? _ongoingOrderId;
  Map<String, dynamic>? _ongoingOrderData;
  StreamSubscription<QuerySnapshot>? _ordersSub;

  bool get _hasOngoingOrder => _ongoingOrderId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialCartItems != null) {
      cartItems = List<Map<String, dynamic>>.from(widget.initialCartItems!);
    }
    if (widget.initialIndex != null) {
      _currentIndex = widget.initialIndex!;
    }
    _subscribeCategories();
    _subscribeRestaurants();
    _subscribeOngoingOrder();
    // First launch: ask for location permission and detect the user's area;
    // afterwards this just loads the saved location. The listener keeps the
    // top-bar city label and service-area gating in sync.
    UserLocation.current.addListener(_onLocationChanged);
    UserLocation.init();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutBack));
    _animationController.forward();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    // This function remains unchanged
    try {
      print('🔧 Testing Firebase connection...');
      final snapshot =
          await _firestore.collection('products_sl').limit(1).get();
      print('✅ Firebase connection successful: ${snapshot.docs.isNotEmpty}');
    } catch (e) {
      print('❌ Firebase connection failed: $e');
    }
  }

  // Real-time categories from the 'categories' collection (name + image)
  void _subscribeCategories() {
    _categoriesSub = _firestore.collection('categories').snapshots().listen(
      (snapshot) {
        if (!mounted) return;
        final cats = snapshot.docs.map((doc) {
          final data = doc.data();
          final rawSubs = data['subCategories'] ??
              data['subcategories'] ??
              data['subCategory'];
          final type = (data['type'] ?? '').toString().toLowerCase();
          final subs = (rawSubs is List)
              ? rawSubs.map((e) => e.toString()).toList()
              : <String>[];
          return {
            'id': doc.id,
            'name': (data['name'] ?? data['title'] ?? 'Category').toString(),
            'type': type,
            'imageUrl': resolveImageSource(data),
            'order': (data['order'] as num?)?.toInt() ?? 999,
            'subCategories': subs,
          };
        }).toList();
        final visibleCats = cats
            .where((cat) => (cat['type'] as String? ?? '') != 'sub')
            .toList();
        final sortedCats = visibleCats.isNotEmpty ? visibleCats : cats;
        sortedCats.sort((a, b) {
          final aOrder = (a['order'] as num?)?.toInt() ?? 999;
          final bOrder = (b['order'] as num?)?.toInt() ?? 999;
          final orderCompare = aOrder.compareTo(bOrder);
          if (orderCompare != 0) return orderCompare;

          final aHasImage =
              ((a['imageUrl'] as String? ?? '').isNotEmpty) ? 0 : 1;
          final bHasImage =
              ((b['imageUrl'] as String? ?? '').isNotEmpty) ? 0 : 1;
          final imageCompare = aHasImage.compareTo(bHasImage);
          if (imageCompare != 0) return imageCompare;

          final aName = (a['name'] ?? '').toString();
          final bName = (b['name'] ?? '').toString();
          return aName.compareTo(bName);
        });
        setState(() {
          _categories = sortedCats;
          _loadingCategories = false;
        });
      },
      onError: (e) {
        debugPrint('❌ Error loading categories: $e');
        if (mounted) setState(() => _loadingCategories = false);
      },
    );
  }

  // Real-time restaurants for the Popular section
  void _subscribeRestaurants() {
    _restaurantsSub = _firestore.collection('restaurants').snapshots().listen(
      (snapshot) {
        if (!mounted) return;
        setState(() {
          _restaurants = snapshot.docs
              .map((doc) => Restaurant.fromFirestore(doc))
              .toList();
          _loadingRestaurants = false;
        });
      },
      onError: (e) {
        debugPrint('❌ Error loading restaurants: $e');
        if (mounted) setState(() => _loadingRestaurants = false);
      },
    );
  }

  // Watch the signed-in user's orders for any still-active (ongoing) order.
  void _subscribeOngoingOrder() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _ordersSub = _firestore
        .collection('orders_sl')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      // Find the most recent order whose status is still active.
      QueryDocumentSnapshot? active;
      DateTime? newest;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['orderStatus'] ?? '').toString();
        if (!_activeStatuses.contains(status)) continue;
        final ts = data['updatedAt'] ?? data['orderDate'] ?? data['createdAt'];
        final dt = ts is Timestamp ? ts.toDate() : DateTime(1970);
        if (newest == null || dt.isAfter(newest)) {
          newest = dt;
          active = doc;
        }
      }
      setState(() {
        _ongoingOrderId = active?.id;
        _ongoingOrderData =
            active != null ? active.data() as Map<String, dynamic> : null;
      });
    }, onError: (e) => debugPrint('❌ Error loading ongoing order: $e'));
  }

  void _openOrderStatus() {
    if (_ongoingOrderId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(orderId: _ongoingOrderId!),
      ),
    );
  }

  void _openRestaurant(Restaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailPage(
          shopData: {
            'id': restaurant.id,
            'name': restaurant.name,
            'category': restaurant.category,
            'imageUrl': restaurant.imageUrl,
            'rating': restaurant.rating,
          },
          onAddToCart: _addToCart,
          initialCartItems: cartItems,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoriesSub?.cancel();
    _restaurantsSub?.cancel();
    _ordersSub?.cancel();
    _animationController.dispose();
    UserLocation.current.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  /// Builds a home section defensively: an unexpected data shape in one
  /// section (e.g. a malformed category doc) must never blank the whole home
  /// screen — it renders an inline error card instead.
  Widget _safeSection(String name, Widget Function() builder) {
    try {
      return builder();
    } catch (e, st) {
      debugPrint('❌ Home section "$name" failed to build: $e\n$st');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'This section could not be displayed.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      );
    }
  }

  // ===== Delivery location: top bar + bottom sheet =====

  Widget _buildLocationBar() {
    final loc = UserLocation.current.value;
    final label = (loc?.city.isNotEmpty == true)
        ? loc!.city
        : (loc != null ? 'Pinned location' : 'Set your location');

    return GestureDetector(
      onTap: _showLocationSheet,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: primaryPurple, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.black, size: 20),
        ],
      ),
    );
  }

  void _showLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final loc = UserLocation.current.value;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Delivery location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F1FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: primaryPurple, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc == null
                              ? 'No location set yet'
                              : (loc.address.isNotEmpty
                                  ? loc.address
                                  : '${loc.city} (${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (loc != null && UserLocation.outsideServiceArea) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Our restaurants are not available near this location yet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final ok = await UserLocation.detectCurrentLocation();
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Could not get your location. Please allow location access or set it manually.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Use current location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationPickerScreen(
                            initialLocation: loc?.latLng,
                          ),
                        ),
                      );
                      if (result is Map &&
                          result['location'] != null) {
                        final picked = result['location'];
                        await UserLocation.save(
                          latitude: picked.latitude,
                          longitude: picked.longitude,
                          address: (result['address'] ?? '').toString(),
                        );
                      }
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Choose on map / search address'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryPurple,
                      side: const BorderSide(color: primaryPurple),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    if (!mounted) return;

    // Defensive copy and ID cleanup
    final String productId = product['id']?.toString() ?? '';
    final String productUnit = product['selectedUnit']?.toString() ?? '';
    final int delta = (product['quantity'] as num).toInt();

    setState(() {
      int existingIndex = cartItems.indexWhere((item) =>
          item['id']?.toString() == productId &&
          item['selectedUnit']?.toString() == productUnit);

      if (existingIndex != -1) {
        final existingItem = cartItems[existingIndex];
        int currentQty = (existingItem['quantity'] as num).toInt();
        int newQuantity = currentQty + delta;

        if (newQuantity <= 0) {
          cartItems.removeAt(existingIndex);
          print("🗑️ Removed $productId from cart (qty <= 0)");
        } else {
          existingItem['quantity'] = newQuantity;
          double unitPrice = (existingItem['unitPrice'] as num).toDouble();
          existingItem['finalPrice'] = unitPrice * newQuantity;
          print("🔄 Updated $productId qty to: $newQuantity");
        }
      } else if (delta > 0) {
        final newItem = Map<String, dynamic>.from(product);
        newItem['id'] = productId; // Ensure it's a string
        newItem['selectedUnit'] = productUnit;
        newItem['quantity'] = delta;
        cartItems.add(newItem);
        print("📥 Added new item $productId to cart with qty: $delta");
      }
    });
  }

  void _removeFromCart(int index) {
    if (!mounted) return;
    setState(() {
      cartItems.removeAt(index);
    });
  }

  // --- ✅ NEW FUNCTION: This handles updates from the Cart page ---
  void _onUpdateCartItem(int index, Map<String, dynamic> updatedItem) {
    if (!mounted) return;
    setState(() {
      if (index >= 0 && index < cartItems.length) {
        cartItems[index] = updatedItem;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, primaryPurple.withOpacity(0.04)],
              ),
            ),
            child: SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _getCurrentScreen(),
                ),
              ),
            ),
          ),
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
                highlightColor: Colors.grey.shade200,
                splashColor: Colors.transparent),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: primaryPurple,
                unselectedItemColor: Colors.grey.shade500,
                selectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                iconSize: 22.0,
                items: [
                  BottomNavigationBarItem(
                      icon: const Icon(Icons.shopping_bag_outlined),
                      activeIcon: const Icon(Icons.shopping_bag),
                      label: AppLocalization.getText('products')),
                  BottomNavigationBarItem(
                    icon: _buildCartIcon(isActive: false),
                    activeIcon: _buildCartIcon(isActive: true),
                    label: AppLocalization.getText('cart'),
                  ),
                  BottomNavigationBarItem(
                      icon: const Icon(Icons.settings_outlined),
                      activeIcon: const Icon(Icons.settings),
                      label: AppLocalization.getText('settings')),
                  BottomNavigationBarItem(
                      icon: const Icon(Icons.info_outline),
                      activeIcon: const Icon(Icons.info),
                      label: AppLocalization.getText('about')),
                ],
              ),
            ),
          ),
          floatingActionButton: null,
        );
      },
    );
  }

  // --- ✅ NEW HELPER WIDGET for a clean cart icon with a badge ---
  Widget _buildCartIcon({required bool isActive}) {
    // When an order is ongoing, the badge shows the live order indicator
    // (a "1" in purple) instead of the cart-item count.
    final showOngoing = _hasOngoingOrder;
    final badgeCount = showOngoing ? 1 : cartItems.length;
    final badgeColor = showOngoing ? primaryPurple : Colors.red;

    return Stack(
      clipBehavior: Clip.none, // Allow badge to overflow
      children: [
        Icon(isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardHome(context);
      case 1:
        // While an order is ongoing, the cart tab shows its live status.
        if (_hasOngoingOrder) return _buildOngoingOrderView();
        return Cart(
          cartItems: cartItems,
          onRemoveFromCart: _removeFromCart,
          onUpdateCartItem: _onUpdateCartItem,
          onBack: null,
        );
      case 2:
        return SettingsUser(
          darkMode: _darkMode,
          onDarkModeChanged: (value) => setState(() => _darkMode = value),
        );
      case 3:
        return const About();
      default:
        return Container(); // Should not happen
    }
  }

  // Maps an order status to a friendly label + step (1..4).
  ({String label, String sub, int step}) _statusInfo(String status) {
    switch (status) {
      case 'preparing':
        return (
          label: 'Preparing your order',
          sub: 'Restaurant is getting it ready',
          step: 2
        );
      case 'finding_rider':
        return (
          label: 'Heading your way',
          sub: 'Rider is picking up your order',
          step: 3
        );
      case 'on_the_way':
        return (
          label: 'Almost here!',
          sub: 'Rider is on the way to you',
          step: 3
        );
      default:
        return (
          label: 'Order placed',
          sub: 'Waiting for restaurant to accept',
          step: 1
        );
    }
  }

  // The cart tab content while an order is ongoing: an "Ongoing" heading and
  // a live status card that opens the full tracking screen on tap.
  Widget _buildOngoingOrderView() {
    final status =
        (_ongoingOrderData?['orderStatus'] ?? 'processing').toString();
    final info = _statusInfo(status);
    final total = _ongoingOrderData?['totalAmount'];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ongoing',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 4),
            Text('You have an active order in progress',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _openOrderStatus,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: softPurple,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD8CFF0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: primaryPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delivery_dining,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(info.label,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryPurple)),
                              const SizedBox(height: 2),
                              Text(info.sub,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: primaryPurple),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Mini segmented progress (4 steps).
                    Row(
                      children: List.generate(4, (i) {
                        final filled = i < info.step;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i == 3 ? 0 : 6),
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: filled ? primaryPurple : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    if (total != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order Total',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700)),
                          Text('Rs ${total.toString()}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: primaryPurple)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openOrderStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                        ),
                        child: const Text('Track Order',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFB97700), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You can place a new order once this one is delivered.',
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.brown.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Restaurants filtered by the selected category chip + search query
  List<Restaurant> get _filteredRestaurants {
    return _restaurants.where((r) {
      final matchesCategory = _selectedCategory == 'All' ||
          r.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSub = _selectedSubCategory == 'All' ||
          r.category.toLowerCase() == _selectedSubCategory.toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty || r.name.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSub && matchesSearch;
    }).toList();
  }

  Widget _buildDashboardHome(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Uber-style delivery location (tap to change) =====
          _buildLocationBar(),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              GestureDetector(
                // Profile shortcut: opens the Settings/profile tab.
                onTap: () => setState(() => _currentIndex = 2),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: softPurple,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.person, color: primaryPurple, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // ===== Real-time Categories =====
          _safeSection('categories', _buildCategoriesRow),
          // ===== Sub-categories for the selected category =====
          _safeSection('subCategories', _buildSubCategoriesRow),
          const SizedBox(height: 22),
          const Text(
            'Promotions',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          // ===== Real-time Promotions (ads_sl) =====
          // Slightly wider than the page padding so the banner pops.
          LayoutBuilder(
            builder: (context, constraints) => OverflowBox(
              maxWidth: constraints.maxWidth + 20,
              child: SizedBox(
                width: constraints.maxWidth + 20,
                child: const AdsBannerWidget(height: 130),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Popular',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          // ===== Real-time Popular restaurants =====
          _safeSection('popular', _buildPopularGrid),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow() {
    if (_loadingCategories) {
      return SizedBox(
        height: 84,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 18),
          itemBuilder: (_, __) => _categoryShimmer(),
        ),
      );
    }

    // "All" chip is always first, then up to 5 dynamic categories
    final items = <Map<String, dynamic>>[
      {'name': 'All', 'imageUrl': ''},
      ..._categories.take(5),
    ];

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final cat = items[index];
          final name = (cat['name'] ?? 'Category').toString();
          final selected = _selectedCategory == name;
          return _buildCategoryChip(
            name: name,
            imageUrl: cat['imageUrl'] as String? ?? '',
            selected: selected,
            onTap: () => setState(() {
              _selectedCategory = name;
              _selectedSubCategory = 'All';
            }),
          );
        },
      ),
    );
  }

  // Sub-category chips for the currently selected category (small black pills)
  Widget _buildSubCategoriesRow() {
    if (_selectedCategory == 'All') return const SizedBox.shrink();

    final cat = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => <String, dynamic>{'subCategories': <String>[]},
    );
    final subs = (cat['subCategories'] as List?)?.cast<String>() ?? <String>[];
    if (subs.isEmpty) return const SizedBox.shrink();

    final items = ['All', ...subs];

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final sub = items[index];
            final selected = _selectedSubCategory == sub;
            return GestureDetector(
              onTap: () => setState(() => _selectedSubCategory = sub),
              child: Container(
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? Colors.black : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  sub,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _categoryShimmer() {
    return Shimmer(
      duration: const Duration(milliseconds: 1500),
      color: Colors.grey.shade300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: 36,
            height: 8,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String name,
    required String imageUrl,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final fallback = Container(
      color: selected ? primaryPurple : softPurple,
      child: Icon(
        Icons.restaurant_menu,
        color: selected ? Colors.white : const Color(0xFF8A80A5),
        size: 24,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: selected ? primaryPurple : softPurple,
              borderRadius: BorderRadius.circular(16),
              border:
                  selected ? Border.all(color: primaryPurple, width: 2) : null,
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: AppImage(
                imageSource: imageUrl,
                fit: BoxFit.cover,
                width: 50,
                height: 50,
                placeholder: Container(color: Colors.grey.shade100),
                fallback: fallback,
              ),
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 60,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? primaryPurple : const Color(0xFF4D465A),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularGrid() {
    if (_loadingRestaurants) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.95,
        children: List.generate(2, (_) => _popularShimmer()),
      );
    }

    // Outside our delivery towns: hide restaurants and explain why.
    if (UserLocation.outsideServiceArea) {
      final towns =
          UserLocation.serviceAreas.map((a) => a.name).join(', ');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1FB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(Icons.location_off_outlined,
                size: 44, color: primaryPurple),
            const SizedBox(height: 12),
            const Text(
              'Our restaurants are not in this location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We currently deliver around: $towns.\nChange your delivery location to browse restaurants.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade700, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _showLocationSheet,
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: const Text('Change location'),
              style: TextButton.styleFrom(foregroundColor: primaryPurple),
            ),
          ],
        ),
      );
    }

    final restaurants = _filteredRestaurants;

    if (restaurants.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.storefront_outlined,
                size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No restaurants found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: restaurants.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final r = restaurants[index];
        return _buildPopularCard(r);
      },
    );
  }

  Widget _popularShimmer() {
    return Shimmer(
      duration: const Duration(milliseconds: 1500),
      color: Colors.grey.shade300,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildPopularCard(Restaurant restaurant) {
    return GestureDetector(
      onTap: () => _openRestaurant(restaurant),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppImage(
                  imageSource: restaurant.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: Container(color: softPurple),
                  fallback: Container(
                    color: softPurple,
                    child: const Icon(Icons.restaurant,
                        color: Color(0xFF9B91B5), size: 34),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              restaurant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      restaurant.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xFFE8A600),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1FAE5A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
