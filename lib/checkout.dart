import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'delivery_details.dart';
import 'app_localization.dart';
import 'location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double deliveryFee;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.subtotal,
    required this.deliveryFee,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late double _deliveryFee;
  StreamSubscription? _feeSubscription;
  bool _isNavigating = false;

  static const double _freeDeliveryThreshold = 10.0;

  @override
  void initState() {
    super.initState();

    _deliveryFee = widget.deliveryFee;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();

    _subscribeToDeliveryFee();
  }

  void _subscribeToDeliveryFee() {
    _feeSubscription = FirebaseFirestore.instance
        .collection('settings')
        .doc('appSettings_sl')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      setState(() {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          final baseDeliveryFee =
              (data['deliveryFee'] as num?)?.toDouble() ?? 0.0;

          if (widget.subtotal >= _freeDeliveryThreshold) {
            _deliveryFee = 0.0;
          } else {
            _deliveryFee = baseDeliveryFee;
          }
        } else {
          _deliveryFee = widget.deliveryFee;
        }
      });
    }, onError: (error) {
      debugPrint('❌ Error loading delivery fee: $error');
      if (mounted) {
        setState(() {
          _deliveryFee = widget.deliveryFee;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _feeSubscription?.cancel();
    super.dispose();
  }

  double get _total => widget.subtotal + _deliveryFee;

  void _goToDeliveryDetails() async {
    if (_isNavigating) return;

    final user = FirebaseAuth.instance.currentUser;
    LatLng? selectedLocation;
    String? selectedAddress;

    // 1. Try to fetch saved location first to skip map
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists &&
          userDoc.data()!.containsKey('last_delivery_location')) {
        final locData = userDoc.data()!['last_delivery_location'];
        selectedLocation = LatLng(locData['latitude'], locData['longitude']);
        selectedAddress = locData['address'];
      }
    }

    // 2. If no saved location, show Location Picker
    if (selectedLocation == null) {
      final locationResult = await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LocationPickerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );

      if (locationResult == null || locationResult['location'] == null) {
        if (mounted) setState(() => _isNavigating = false);
        return;
      }

      selectedLocation = locationResult['location'];
      selectedAddress = locationResult['address'] ?? '';

      // Save location immediately for future use even if order not placed
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'last_delivery_location': {
            'latitude': selectedLocation!.latitude,
            'longitude': selectedLocation.longitude,
            'address': selectedAddress,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));
      }
    }

    if (!mounted) return;

    final transformedCartItems = widget.cartItems.map((item) {
      return {
        ...item,
        'productId': item['id'],
        'quantity': (item['quantity'] as num?)?.toDouble() ?? 1.0,
      };
    }).toList();

    final orderSummaryMetadata = {
      'app': 'Nico Online Mart',
      'cart_items': transformedCartItems,
      'subtotal': widget.subtotal,
      'delivery_fee': _deliveryFee,
      'latitude': selectedLocation!.latitude,
      'longitude': selectedLocation.longitude,
      'selectedAddress': selectedAddress,
    };

    // Enhanced smooth navigation to Delivery Details
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DeliveryDetailsScreen(
          total: _total,
          currency: 'Rs.',
          metadata: orderSummaryMetadata,
          onPaymentResult: (success, paymentIntentId, deliveryDetails) {
            if (mounted && success) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final qualifiesForFreeDelivery = widget.subtotal >= _freeDeliveryThreshold;

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.grey.shade200,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalization.getText('checkoutTitle'),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildOrderSummary(qualifiesForFreeDelivery),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNavigating
                        ? Colors.grey.shade400
                        : const Color(0xFF4A22A8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isNavigating ? null : _goToDeliveryDetails,
                  child: _isNavigating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalization.getText(
                                  'continueToDeliveryDetails'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward,
                                color: Colors.white, size: 18),
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

  Widget _buildOrderSummary(bool qualifiesForFreeDelivery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalization.getText('orderSummary'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${widget.cartItems.length} ${widget.cartItems.length == 1 ? AppLocalization.getText('item') : AppLocalization.getText('items')}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // BILL DETAILS Header
          Text(
            AppLocalization.getText('itemDetails').toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 14),

          // Cart Items List
          ...widget.cartItems.map((item) {
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
            final lineTotal =
                (item['finalPrice'] as num?)?.toDouble() ?? (price * quantity);
            final unit = item['selectedUnit'] ?? 'x';
            final productName =
                item['name'] ?? AppLocalization.getText('unknownProduct');

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Text(
                            '${NumberFormat("0.##").format(quantity)} $unit',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            productName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rs.${lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade100, thickness: 1),
          const SizedBox(height: 8),

          // Bill Summary section
          Text(
            AppLocalization.getText('billSummary').toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 14),

          // Subtotal
          _buildSummaryRow(
              AppLocalization.getText('subtotal'), widget.subtotal),
          const SizedBox(height: 10),

          // Delivery Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalization.getText('delivery'),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  if (_deliveryFee == 0.0 && widget.deliveryFee > 0.0)
                    Text(
                      'Rs.${widget.deliveryFee.toStringAsFixed(2)} ',
                      style: TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  Text(
                    _deliveryFee == 0.0
                        ? 'Free'
                        : 'Rs.${_deliveryFee.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _deliveryFee == 0.0
                          ? Color(0xFF4A22A8)
                          : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(thickness: 1.5, color: Color(0xFFF8FAFC)),
          ),

          // Total
          _buildSummaryRow(AppLocalization.getText('total'), _total,
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black87 : Colors.grey.shade600,
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          'Rs.${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: isTotal ? const Color(0xFF4A22A8) : Colors.black87,
            fontSize: isTotal ? 17 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
