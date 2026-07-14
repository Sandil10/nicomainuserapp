import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import 'app_notification.dart';
import 'app_localization.dart';
import 'user_panel.dart';
import 'stripe_payment_screen.dart';
import 'order_status_screen.dart';
import 'location_picker_screen.dart';
import 'widgets/small_wave_loader.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final double total;
  final String currency;
  final Map<String, dynamic> metadata;
  final Function(bool success, String? paymentIntentId,
      Map<String, dynamic>? deliveryDetails) onPaymentResult;

  const DeliveryDetailsScreen({
    Key? key,
    required this.total,
    required this.currency,
    required this.metadata,
    required this.onPaymentResult,
  }) : super(key: key);

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  late LatLng _currentLatLng;
  String _currentAddress = '';
  bool _isProcessing = false;
  bool _isLoading = false;
  bool _loadingOverlayVisible = false;
  bool _isMapLoading = true;
  GoogleMapController? _mapController;
  BitmapDescriptor? _markerIcon;
  // No default: the user must actively choose how to pay.
  String? _selectedPaymentMethod;
  List<Map<String, dynamic>> _savedCards = [];
  bool _isLoadingCards = false;

  late AnimationController _popupAnimationController;
  late AnimationController _checkAnimationController;
  late Animation<double> _popupScaleAnimation;
  late Animation<double> _checkScaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentLatLng = LatLng(
      widget.metadata['latitude'] as double? ?? 6.9271,
      widget.metadata['longitude'] as double? ?? 79.8612,
    );
    _currentAddress = widget.metadata['selectedAddress'] as String? ?? '';
    _loadStoredUserData();
    _loadSavedCards();
    _initializeAnimations();
    _buildMarkerIcon();

    // Fetch address if empty but coords are available
    if (_currentAddress.isEmpty) {
      _getAddressFromCoords(_currentLatLng);
    }
  }

  // Draw a small, clean circular marker so the pin is compact (not the
  // oversized default red balloon) and renders crisply.
  Future<void> _buildMarkerIcon() async {
    const double size = 64; // logical px of the bitmap (small marker)
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    // Soft outer halo
    canvas.drawCircle(
      center,
      size / 2,
      Paint()..color = const Color(0x334A22A8),
    );
    // White ring
    canvas.drawCircle(
      center,
      size / 4 + 4,
      Paint()..color = Colors.white,
    );
    // Solid purple dot
    canvas.drawCircle(
      center,
      size / 4,
      Paint()..color = const Color(0xFF4A22A8),
    );

    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;

    if (mounted) {
      setState(() {
        // ignore: deprecated_member_use
        _markerIcon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
      });
    }
  }

  Future<void> _getAddressFromCoords(LatLng location) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        String addr = '';
        if (place.street != null && place.street!.isNotEmpty)
          addr += '${place.street}, ';
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          addr += '${place.subLocality}, ';
        if (place.locality != null && place.locality!.isNotEmpty)
          addr += '${place.locality}';

        setState(() {
          _currentAddress = addr;
        });
      }
    } catch (e) {
      debugPrint('Geocoding Error in Delivery Details: $e');
    }
  }

  Future<void> _loadStoredUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted && doc.exists) {
          final data = doc.data();
          final details =
              data?['defaultDeliveryDetails'] as Map<String, dynamic>?;
          if (details != null) {
            String phone = details['phone'] ?? '';
            if (phone.startsWith('+94')) {
              _phoneController.text = phone.substring(3).trim();
            } else {
              _phoneController.text = phone;
            }
            _notesController.text = details['notes'] ?? '';
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    _popupAnimationController.dispose();
    _checkAnimationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) setState(() => _isLoadingCards = true);
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('payment_methods')
            .orderBy('createdAt', descending: true)
            .get();
        if (mounted) {
          setState(() {
            _savedCards = snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
            _isLoadingCards = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingCards = false);
      }
    }
  }

  Future<void> _saveNewCard(String last4, String brand,
      {String? currency}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cardData = {
        'last4': last4,
        'brand': brand,
        'currency': currency ?? 'LKR',
        'createdAt': Timestamp.now(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .add(cardData);
      await _loadSavedCards();
    }
  }

  Future<void> _deleteCard(String cardId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .doc(cardId)
          .delete();
      await _loadSavedCards();
    }
  }

  void _initializeAnimations() {
    _popupAnimationController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _checkAnimationController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _popupScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _popupAnimationController, curve: Curves.elasticOut));
    _checkScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _checkAnimationController, curve: Curves.elasticOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _popupAnimationController, curve: Curves.easeInOut));
  }

  void _editLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (result != null && result['location'] != null && mounted) {
      setState(() {
        _currentLatLng = result['location'];
        if (result['address'] != null) {
          _currentAddress = result['address'];
        }
      });
      // Smoothly glide the camera to the new pin location
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentLatLng),
      );
      // Update persistent location
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'last_delivery_location': {
            'latitude': _currentLatLng.latitude,
            'longitude': _currentLatLng.longitude,
            'address': _currentAddress,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));
      }
    }
  }

  // True if the user already has an order that hasn't been delivered yet.
  Future<bool> _hasOngoingOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    const active = [
      'confirmed',
      'processing',
      'received',
      'preparing',
      'ready',
      'finding_rider',
      'picked_up',
      'on_the_way',
    ];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders_sl')
          .where('userId', isEqualTo: user.uid)
          .where('orderStatus', whereIn: active)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false; // don't block on a query error
    }
  }

  Future<void> _placeOrder() async {
    if (_phoneController.text.trim().isEmpty) {
      showAppNotification(
        title: AppLocalization.getText('required'),
        message: AppLocalization.getText('phoneNumberRequired'),
        type: NotificationType.error,
      );
      return;
    }

    // The user must actively pick how to pay — auto-open the selector.
    if (_selectedPaymentMethod == null) {
      showAppNotification(
        title: 'Payment method',
        message: 'Please choose how you want to pay for this order.',
        type: NotificationType.info,
      );
      _showPaymentPopup();
      return;
    }

    // Block a second order while one is still ongoing.
    if (await _hasOngoingOrder()) {
      if (!mounted) return;
      showAppNotification(
        title: 'Order in progress',
        message:
            'You already have an ongoing order. Please wait until it is delivered before placing a new one.',
        type: NotificationType.error,
      );
      return;
    }

    final deliveryDetails = {
      'customer_name':
          FirebaseAuth.instance.currentUser?.displayName ?? 'Customer',
      'customer_phone': '+94${_phoneController.text.trim()}',
      'delivery_address': _currentAddress,
      'delivery_notes': _notesController.text.trim(),
      'latitude': _currentLatLng.latitude,
      'longitude': _currentLatLng.longitude,
      'paymentMethod': _selectedPaymentMethod,
    };

    // Remember these details so the next checkout is prefilled end-to-end
    // (location is already saved separately) and the user can go straight
    // to Place Order without re-entering anything.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(FirebaseFirestore.instance.collection('users').doc(uid).set({
        'defaultDeliveryDetails': {
          'phone': '+94${_phoneController.text.trim()}',
          'notes': _notesController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true)));
    }

    if (_selectedPaymentMethod == 'Cash on Delivery') {
      await _processOrder(deliveryDetails);
    } else {
      // For Card payments, trigger Stripe
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StripePaymentScreen(
            amount: widget.total,
            currency: widget.currency,
            metadata: {
              ...widget.metadata,
              ...deliveryDetails,
            },
            onPaymentResult: (success, paymentIntentId) async {
              if (success) {
                // Navigate to status screen if payment handled order creation
                // We'll trust StripePaymentScreen navigates or we push here
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _processOrder(Map<String, dynamic> details) async {
    setState(() => _isProcessing = true);
    _showLoadingOverlay();

    try {
      final orderId = await _createOrderInFirestore(details);

      if (mounted) {
        _hideLoadingOverlay();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OrderStatusScreen(orderId: orderId),
            ),
          );
        });
      }
    } catch (e) {
      _hideLoadingOverlay();
      if (mounted)
        showAppNotification(
            title: AppLocalization.getText('orderCreationFailed'),
            message: e.toString(),
            type: NotificationType.error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Helper methods borrowed/adapted from original code

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  Map<String, double>? _extractRestaurantLocation(Map<String, dynamic> data) {
    final location = data['location'];
    final lat = _asDouble(data['latitude']) ??
        (location is Map
            ? _asDouble(location['latitude'] ?? location['lat'])
            : location is GeoPoint
                ? location.latitude
                : null);
    final lng = _asDouble(data['longitude']) ??
        (location is Map
            ? _asDouble(location['longitude'] ?? location['lng'])
            : location is GeoPoint
                ? location.longitude
                : null);

    if (lat == null || lng == null) return null;
    return {
      'latitude': lat,
      'longitude': lng,
    };
  }

  Future<Map<String, double>?> _loadRestaurantLocation(
      String restaurantId) async {
    if (restaurantId.isEmpty) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();
      final data = snap.data();
      if (data == null) return null;
      return _extractRestaurantLocation(data);
    } catch (e) {
      debugPrint('Could not load restaurant location: $e');
      return null;
    }
  }

  /// Cart items only carry `restaurantId` (a foreign key) — no product ever
  /// has `restaurantName` set — so the order's restaurant name must be
  /// looked up from the `restaurants` doc, otherwise the tracking map falls
  /// back to the literal placeholder "Restaurant".
  Future<String?> _loadRestaurantName(String restaurantId) async {
    if (restaurantId.isEmpty) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();
      final data = snap.data();
      if (data == null) return null;
      final name = (data['name'] ?? data['restaurantName'] ?? '').toString().trim();
      return name.isEmpty ? null : name;
    } catch (e) {
      debugPrint('Could not load restaurant name: $e');
      return null;
    }
  }

  Future<String> _createOrderInFirestore(Map<String, dynamic> details) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final orderId =
        'ORDC${List.generate(4, (index) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[math.Random().nextInt(36)]).join()}';
    final now = Timestamp.now();
    final batch = FirebaseFirestore.instance.batch();

    final List<dynamic> cartItems =
        List<Map<String, dynamic>>.from(widget.metadata['cart_items'] ?? []);

    final deliveryFee = widget.metadata['delivery_fee']?.toDouble() ?? 0.0;

    // Derive the restaurant this order belongs to from the cart items.
    // Carts in this app are single-restaurant, so the first item's restaurant
    // applies to the whole order. This top-level field lets the restaurant app
    // query its incoming orders in real time.
    String restaurantId = '';
    String restaurantName = '';
    if (cartItems.isNotEmpty && cartItems.first is Map) {
      final firstItem = cartItems.first as Map;
      restaurantId = (firstItem['restaurantId'] ?? '').toString();
      restaurantName = (firstItem['restaurantName'] ??
              firstItem['shopName'] ??
              firstItem['storeName'] ??
              '')
          .toString();
    }

    final restaurantLocation = await _loadRestaurantLocation(restaurantId);
    // The cart-item guess above is almost always empty (products don't carry
    // a restaurant name) — the restaurants doc is the source of truth.
    restaurantName = await _loadRestaurantName(restaurantId) ?? restaurantName;

    final orderData = {
      'orderId': orderId,
      'userId': user.uid,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      if (restaurantLocation != null) 'restaurantLocation': restaurantLocation,
      'orderDate': now,
      'createdAt': now,
      'updatedAt': now,
      'customerName':
          details['customer_name'] ?? user.displayName ?? 'Customer',
      'customerPhone': details['customer_phone'],
      'deliveryAddress': {
        'streetAddress': details['delivery_address'],
        'city': '',
        'zipCode': '',
        'province': '',
        'notes': details['delivery_notes'],
        'latitude': details['latitude'],
        'longitude': details['longitude'],
      },
      'paymentMethod': details['paymentMethod'] ?? 'Cash on Delivery',
      'paymentStatus': 'pending',
      'currency': widget.currency,
      // Use the real cart subtotal from the checkout metadata; deriving it
      // as total - deliveryFee breaks once service charge / tax are added.
      'subtotal': (widget.metadata['subtotal'] as num?)?.toDouble() ??
          (widget.total - deliveryFee),
      'deliveryFee': deliveryFee,
      'serviceCharge':
          (widget.metadata['service_charge'] as num?)?.toDouble() ?? 0.0,
      'tax': (widget.metadata['tax'] as num?)?.toDouble() ?? 0.0,
      'storeDiscount':
          (widget.metadata['store_discount'] as num?)?.toDouble() ?? 0.0,
      'totalAmount': widget.total,
      'orderStatus': 'confirmed',
      'orderItems': cartItems,
    };

    batch.set(FirebaseFirestore.instance.collection('orders_sl').doc(orderId),
        orderData);
    batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId),
        {
          'orderId': orderId,
          'orderDate': now,
          'totalAmount': widget.total,
          'orderStatus': 'confirmed',
        });

    // Also save default details for next time
    batch.set(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {
          'defaultDeliveryDetails': {
            'phone': details['customer_phone'],
            'notes': details['delivery_notes'],
            'updatedAt': now,
          }
        },
        SetOptions(merge: true));

    await batch.commit();
    return orderId;
  }

  void _showLoadingOverlay() {
    _loadingOverlayVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => const Center(child: SmallWaveLoader(color: Colors.white)),
    );
  }

  void _hideLoadingOverlay() {
    if (!mounted || !_loadingOverlayVisible) return;
    _loadingOverlayVisible = false;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _showSuccessPopup(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _popupAnimationController.forward();
        _checkAnimationController.forward();
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: ScaleTransition(
              scale: _popupScaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                              color: Color(0xFF4A22A8), shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 48)),
                      const SizedBox(height: 24),
                      const Text('Order Confirmed!',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text('Order ID: $orderId',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const UserPanel()),
                              (r) => false);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirm Order',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 22),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Mini Map Header
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                children: [
                  AnimatedOpacity(
                    opacity: _isMapLoading ? 0.0 : 1.0,
                    duration:
                        const Duration(milliseconds: 600), // Smooth fade-in
                    child: GoogleMap(
                      buildingsEnabled: false,
                      tiltGesturesEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      trafficEnabled: false,
                      initialCameraPosition:
                          CameraPosition(target: _currentLatLng, zoom: 16),
                      markers: {
                        Marker(
                          markerId: const MarkerId('delivery'),
                          position: _currentLatLng,
                          icon: _markerIcon ?? BitmapDescriptor.defaultMarker,
                          anchor: const Offset(0.5, 0.5),
                        )
                      },
                      liteModeEnabled: false,
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      onMapCreated: (c) {
                        _mapController = c;
                        c.setMapStyle(_mapStyle);
                        if (mounted) setState(() => _isMapLoading = false);
                      },
                    ),
                  ),
                  if (_isMapLoading)
                    Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                          child: SmallWaveLoader(color: Colors.black54)),
                    ),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5))
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _editLocation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.location_pin,
                                    size: 18, color: Colors.black),
                                SizedBox(width: 8),
                                Text('Edit pin',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              child: Column(
                children: [
                  // Address Tile
                  _buildUberTile(
                    icon: Icons.location_on,
                    title: _currentAddress.split(',').first.trim(),
                    subtitle: _currentAddress,
                    onTap: _editLocation,
                  ),
                  const Divider(indent: 64, height: 1.5, thickness: 0.5),

                  // Delivery Instructions Tile
                  _buildUberTile(
                    icon: Icons.person,
                    title: 'Meet at my door',
                    subtitle: _notesController.text.isEmpty
                        ? 'Add delivery instructions'
                        : _notesController.text,
                    subtitleColor: _notesController.text.isEmpty
                        ? Color(0xFF4A22A8)
                        : Colors.black54,
                    onTap: () =>
                        _showEditDialog('Instructions', _notesController),
                  ),
                  const Divider(indent: 64, height: 1.5, thickness: 0.5),

                  // Phone Number Tile
                  _buildUberTile(
                    icon: Icons.phone,
                    title: _phoneController.text.isEmpty
                        ? 'No phone added'
                        : '+94 ${_phoneController.text}',
                    subtitle: 'Add phone number to contact',
                    onTap: () => _showEditDialog(
                        'Phone Number', _phoneController,
                        isNumeric: true),
                  ),
                  const Divider(indent: 64, height: 1.5, thickness: 0.5),
                ],
              ),
            ),

            // Placeholder for Delivery Time
            ListTile(
              leading: const Icon(Icons.access_time_filled,
                  color: Colors.black, size: 24),
              title: const Text('Delivery time',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              trailing: const Text('Standard (15-25 min)',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),

            // Price Breakdown Section
            _buildPriceBreakdown(),
            const Divider(height: 1),

            // Payment Selector
            _buildPaymentSelector(),
            const SizedBox(height: 32), // Reduced gap for better balance
          ],
        ),
      ),
      bottomNavigationBar: _buildUberBottomBar(),
    );
  }

  Widget _buildPriceBreakdown() {
    final double deliveryFee =
        widget.metadata['delivery_fee']?.toDouble() ?? 0.0;
    final double serviceCharge =
        (widget.metadata['service_charge'] as num?)?.toDouble() ?? 0.0;
    final double taxes = (widget.metadata['tax'] as num?)?.toDouble() ?? 0.0;
    final double storeDiscount =
        (widget.metadata['store_discount'] as num?)?.toDouble() ?? 0.0;
    // Real cart subtotal (already includes product discounts); fall back to
    // deriving it only for orders placed by older app versions.
    final double subtotal = (widget.metadata['subtotal'] as num?)?.toDouble() ??
        (widget.total - deliveryFee - serviceCharge - taxes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Price Breakdown',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black)),
          const SizedBox(height: 12),
          _buildPriceRow('Subtotal', subtotal),
          if (storeDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Store Discount', -storeDiscount),
          ],
          const SizedBox(height: 8),
          _buildPriceRow('Delivery Fee', deliveryFee),
          if (serviceCharge > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Service Charge', serviceCharge),
          ],
          if (taxes > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Tax', taxes),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text('Rs ${widget.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        Text('Rs ${value.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPaymentSelector() {
    final method = _selectedPaymentMethod;
    final IconData paymentIcon = method == null
        ? Icons.account_balance_wallet_outlined
        : (method == 'Cash on Delivery' ? Icons.money : Icons.credit_card);

    return ListTile(
      leading: Icon(paymentIcon,
          color: method == null ? Colors.redAccent : const Color(0xFF4A22A8)),
      title: Text(method ?? 'Choose a payment method',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color:
                  method == null ? Colors.redAccent : const Color(0xFF4A22A8))),
      subtitle: const Text('Select Payment Method',
          style: TextStyle(fontSize: 11, color: Colors.black54)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF4A22A8)),
      onTap: _showPaymentPopup,
    );
  }

  void _showPaymentPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pay With',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A22A8))),
              const SizedBox(height: 16),

              // Cash Option
              _buildPaymentPopupOption(
                icon: Icons.money,
                title: 'Cash on Delivery',
                isSelected: _selectedPaymentMethod == 'Cash on Delivery',
                onTap: () {
                  setState(() => _selectedPaymentMethod = 'Cash on Delivery');
                  Navigator.pop(context);
                },
              ),

              // Add Payment Method Option
              _buildPaymentPopupOption(
                icon: Icons.add_circle_outline,
                title: 'Add Payment Method',
                isSelected: false,
                color: const Color(0xFF4A22A8),
                onTap: () {
                  Navigator.pop(context); // Close selection
                  _showAddCardForm(); // Open form
                },
              ),

              const Divider(height: 24),

              // Saved Cards
              if (_savedCards.isNotEmpty) ...[
                const Text('Saved Cards',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._savedCards
                    .map((card) => _buildPaymentPopupOption(
                          icon: Icons.credit_card,
                          title: '${card['brand']} •••• ${card['last4']}',
                          isSelected: _selectedPaymentMethod ==
                              '${card['brand']} •••• ${card['last4']}',
                          onTap: () {
                            setState(() => _selectedPaymentMethod =
                                '${card['brand']} •••• ${card['last4']}');
                            Navigator.pop(context);
                          },
                          onDelete: () async {
                            await _deleteCard(card['id']);
                            setPopupState(() {}); // Refresh popup
                          },
                        ))
                    .toList(),
              ] else if (_isLoadingCards)
                const Center(child: CircularProgressIndicator())
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No saved cards found.',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentPopupOption(
      {required IconData icon,
      required String title,
      required bool isSelected,
      Color? color,
      required VoidCallback onTap,
      VoidCallback? onDelete}) {
    return ListTile(
      leading: Icon(icon,
          color: isSelected || color != null
              ? (color ?? const Color(0xFF4A22A8))
              : Colors.black54),
      title: Text(title,
          style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
              color: color ??
                  (isSelected ? const Color(0xFF4A22A8) : Colors.black87))),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF4A22A8))
          : (onDelete != null
              ? IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  onPressed: onDelete)
              : (title == 'Add Payment Method'
                  ? const Icon(Icons.add, size: 18)
                  : null)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showAddCardForm() {
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final nameController = TextEditingController();

    // ignore: unused_local_variable
    final List<Map<String, String>> currencies = [
      {'code': 'LKR', 'flag': '🇱🇰', 'name': 'Sri Lankan Rupee'},
      {'code': 'USD', 'flag': '🇺🇸', 'name': 'US Dollar'},
      {'code': 'EUR', 'flag': '🇪🇺', 'name': 'Euro'},
      {'code': 'GBP', 'flag': '🇬🇧', 'name': 'British Pound'},
      {'code': 'INR', 'flag': '🇮🇳', 'name': 'Indian Rupee'},
      {'code': 'AUD', 'flag': '🇦🇺', 'name': 'Australian Dollar'},
      {'code': 'CAD', 'flag': '🇨🇦', 'name': 'Canadian Dollar'},
      {'code': 'JPY', 'flag': '🇯🇵', 'name': 'Japanese Yen'},
      {'code': 'CNY', 'flag': '🇨🇳', 'name': 'Chinese Yuan'},
      {'code': 'NZD', 'flag': '🇳🇿', 'name': 'New Zealand Dollar'},
      {'code': 'SGD', 'flag': '🇸🇬', 'name': 'Singapore Dollar'},
      {'code': 'HKD', 'flag': '🇭🇰', 'name': 'Hong Kong Dollar'},
      {'code': 'CHF', 'flag': '🇨🇭', 'name': 'Swiss Franc'},
      {'code': 'AED', 'flag': '🇦🇪', 'name': 'UAE Dirham'},
      {'code': 'SAR', 'flag': '🇸🇦', 'name': 'Saudi Riyal'},
      {'code': 'QAR', 'flag': '🇶🇦', 'name': 'Qatari Riyal'},
      {'code': 'MYR', 'flag': '🇲🇾', 'name': 'Malaysian Ringgit'},
      {'code': 'THB', 'flag': '🇹🇭', 'name': 'Thai Baht'},
      {'code': 'ZAR', 'flag': '🇿🇦', 'name': 'South African Rand'},
      {'code': 'BRL', 'flag': '🇧🇷', 'name': 'Brazilian Real'},
      {'code': 'MXN', 'flag': '🇲🇽', 'name': 'Mexican Peso'},
      {'code': 'RUB', 'flag': '🇷🇺', 'name': 'Russian Ruble'},
      {'code': 'KRW', 'flag': '🇰🇷', 'name': 'South Korean Won'},
      {'code': 'TRY', 'flag': '🇹🇷', 'name': 'Turkish Lira'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // Smoother safe area interaction
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSubState) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 12),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // Smoother scroll
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2)))),
                const Text('Add Card',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A22A8))),
                const SizedBox(height: 24),
                _buildField('Card Number', cardNumberController,
                    isNumeric: true,
                    hint: '0000 0000 0000 0000',
                    icon: Icons.credit_card),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildField('Expiry Date', expiryController,
                            isNumeric: false,
                            hint: 'MM/YY',
                            icon: Icons.calendar_today)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildField('CVC/CVV', cvvController,
                            isNumeric: true,
                            hint: '123',
                            icon: Icons.lock_outline)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('Cardholder Name', nameController,
                    isNumeric: false,
                    hint: 'Full Name',
                    icon: Icons.person_outline),
                const SizedBox(height: 16),

                // Keep currency fixed to LKR in the add-card form.
                const Text('Currency',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Text('🇱🇰', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 12),
                      Text(
                        'LKR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A22A8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (cardNumberController.text.length < 4) return;
                    _saveNewCard(
                        cardNumberController.text
                            .substring(cardNumberController.text.length - 4),
                        'Visa',
                        currency: 'LKR');
                    Navigator.pop(context);
                    showAppNotification(
                        title: 'Success',
                        message: 'Card added successfully',
                        type: NotificationType.success);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A22A8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                    elevation: 0,
                  ),
                  child: const Text('Save Card',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4A22A8).withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isSelected ? const Color(0xFF4A22A8) : Colors.transparent),
      ),
      child: Text(label,
          style: TextStyle(
              color: isSelected ? const Color(0xFF4A22A8) : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 12)),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {required bool isNumeric, required String hint, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon:
                icon != null ? Icon(icon, color: Colors.black, size: 20) : null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Adding the same map style for consistency
  final String _mapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "on"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#eeeeee"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#c9c9c9"}]}
  ]
  ''';

  Widget _buildUberTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      Color? subtitleColor,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: Colors.black87, size: 22), // Smaller icon
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black)), // Smaller font
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(subtitle,
              style: TextStyle(
                  color: subtitleColor ?? Colors.black54,
                  fontSize: 11,
                  height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis), // Smaller font
        ),
        trailing: const Icon(Icons.chevron_right,
            color: Colors.black26, size: 18), // Smaller icon
        onTap: onTap,
      ),
    );
  }

  void _showEditDialog(String title, TextEditingController controller,
      {bool isNumeric = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Please provide your ${title.toLowerCase()} for delivery.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  isNumeric ? TextInputType.phone : TextInputType.text,
              maxLines: isNumeric ? 1 : 3,
              inputFormatters: isNumeric
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10)
                    ]
                  : null,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                hintText: isNumeric
                    ? '71 234 5678'
                    : 'e.g. Apartment number, floor, or landmarks',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(isNumeric ? Icons.phone_android : Icons.notes,
                    color: Colors.black54),
                prefixText: isNumeric ? '+94 ' : null,
                prefixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Colors.black12, width: 1)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (isNumeric) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'phone_number': controller.text.trim(),
                    });
                  }
                }
                setState(() {});
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A22A8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                elevation: 0,
              ),
              child: const Text('Save and Continue',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUberBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12))),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Order Total Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Total',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A22A8))),
                Row(
                  children: [
                    const Text('Rs',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A22A8))),
                    const SizedBox(width: 4),
                    Text(widget.total.toStringAsFixed(2),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A22A8))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Place Order Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A22A8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  elevation: 0,
                ),
                child: const Text('Place order',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
