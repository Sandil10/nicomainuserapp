import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import 'stripe_service.dart';
import 'settings_user.dart';
import 'user_panel.dart';
import 'app_localization.dart';
import 'order_status_screen.dart';

class StripePaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final Map<String, dynamic>? metadata;
  final Function(bool success, String? paymentIntentId) onPaymentResult;

  const StripePaymentScreen({
    Key? key,
    required this.amount,
    this.currency = 'EUR',
    this.metadata,
    required this.onPaymentResult,
  }) : super(key: key);

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _paymentIntent;
  bool _isPaymentProcessing = false;
  bool _isCreatingOrder = false;
  bool _orderCreated = false;
  bool _processingDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _createPaymentIntent();
  }

  /// Generate more unique order ID to reduce collisions in high volume
  String _generateOrderId() {
    final random = Random();
    final randomNumbers = (100000 + random.nextInt(900000)).toString();
    return 'ORD$randomNumbers';
  }

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

  /// Create PaymentIntent on backend via StripeService
  Future<void> _createPaymentIntent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Ensure metadata has minimal required fields
      final metadata = <String, dynamic>{
        'app': 'Nico Online Mart',
        'userId': user?.uid ?? 'guest',
      };

      final paymentIntent = await StripeService.createPaymentIntent(
        amount: StripeService.amountToCents(widget.amount), // now returns int
        currency: widget.currency.toLowerCase(),
        metadata: metadata,
      );

      // Check that both id and client_secret are returned to avoid 'No such payment_intent' error
      if (paymentIntent == null ||
          paymentIntent['id'] == null ||
          paymentIntent['client_secret'] == null) {
        throw Exception(
            'PaymentIntent creation failed: missing id or client_secret');
      }

      if (!mounted) return;
      setState(() {
        _paymentIntent = paymentIntent;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Create order record in Firestore after successful payment
  Future<String?> _createOrderInFirestore(String paymentIntentId) async {
    if (_orderCreated) {
      print('⚠️ Order already created, skipping duplicate creation');
      return null;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final cartItems = widget.metadata?['cart_items'] ?? [];
      if (cartItems.isEmpty) throw Exception('Cart is empty');

      // Create order entry
      final orderId = _generateOrderId();
      final now = Timestamp.now();
      final subtotal = widget.metadata?['subtotal'] ?? 0.0;
      final deliveryFee = widget.metadata?['delivery_fee'] ?? 0.0;
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

      final orderData = {
        'orderId': orderId,
        'userId': user.uid,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        if (restaurantLocation != null)
          'restaurantLocation': restaurantLocation,
        'paymentIntentId': paymentIntentId,
        'orderDate': now,
        'createdAt': now,
        'updatedAt': now,
        'deliveryDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'customerName': widget.metadata?['customer_name'] ?? '',
        'customerPhone': widget.metadata?['customer_phone'] ?? '',
        'deliveryAddress': {
          'streetAddress': widget.metadata?['delivery_address'] ?? '',
          'city': widget.metadata?['delivery_city'] ?? '',
          'notes': widget.metadata?['delivery_notes'] ?? '',
          'latitude': widget.metadata?['latitude'],
          'longitude': widget.metadata?['longitude'],
        },
        'paymentMethod': 'Card',
        'paymentStatus': 'completed',
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'totalAmount': widget.amount,
        'currency': widget.currency,
        'orderStatus': 'confirmed',
        'orderItems': cartItems,
        'itemCount': cartItems.length,
      };

      final batch = FirebaseFirestore.instance.batch();
      final mainOrderRef =
          FirebaseFirestore.instance.collection('orders_sl').doc(orderId);
      final userOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId);

      batch.set(mainOrderRef, orderData);
      batch.set(userOrderRef, {
        'orderId': orderId,
        'orderDate': now,
        'totalAmount': widget.amount,
        'orderStatus': 'confirmed',
        'itemCount': cartItems.length,
        'paymentMethod': 'Card',
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
      });

      await batch.commit();

      setState(() {
        _orderCreated = true;
      });

      print('✅ Card payment order created successfully: $orderId');
      return orderId;
    } catch (e) {
      print('❌ Error creating order: $e');
      rethrow;
    }
  }

  /// Main payment processing function, handles payment and order creation UI flow
  Future<void> _processPayment() async {
    if (_paymentIntent == null || !mounted) return;

    if (_isPaymentProcessing || _orderCreated) {
      print('⚠️ Payment already processing or order already created');
      return;
    }

    final navigator = Navigator.of(context);

    setState(() {
      _isPaymentProcessing = true;
    });
    _showProcessingDialog();

    try {
      final success = await StripeService.processPaymentWithSheet(
        clientSecret: _paymentIntent!['client_secret'],
        context: context,
        amount: widget.amount,
      );

      if (!mounted) return;

      _hideProcessingDialog(navigator);

      if (success) {
        setState(() {
          _isCreatingOrder = true;
        });

        try {
          final orderId = await _createOrderInFirestore(_paymentIntent!['id']);

          if (orderId != null) {
            widget.onPaymentResult(true, _paymentIntent!['id']);

            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => OrderStatusScreen(orderId: orderId),
                  ),
                  (route) => false,
                );
              });
            }
          }
        } catch (e) {
          if (mounted) {
            _showErrorDialog(
              AppLocalization.getText('orderFailed'),
              e.toString().replaceAll('Exception: ', ''),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() =>
              _errorMessage = AppLocalization.getText('paymentCancelled'));
        }
      }
    } catch (e) {
      if (mounted) {
        print('Stripe Error: $e'); // more detailed logging for Stripe errors

        _hideProcessingDialog(navigator);
        setState(
            () => _errorMessage = e.toString().replaceAll('Exception: ', ''));
        _showErrorDialog(
            AppLocalization.getText('paymentFailed'), _errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPaymentProcessing = false;
          _isCreatingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {
                if (!_orderCreated) {
                  widget.onPaymentResult(false, null);
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              AppLocalization.getText('securePayment'),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAmountCard(),
                  const SizedBox(height: 20),
                  _buildStatusSection(),
                  const SizedBox(height: 20),
                  _buildPayButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child:
                Icon(Icons.credit_card, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalization.getText('paymentAmount'),
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '€${widget.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
            const SizedBox(height: 12),
            Text(
              AppLocalization.getText('anErrorOccurred'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createPaymentIntent,
              child: Text(AppLocalization.getText('tryAgain')),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPayButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          disabledBackgroundColor: Colors.grey.shade400,
        ),
        onPressed: (_isLoading ||
                _isPaymentProcessing ||
                _paymentIntent == null ||
                _orderCreated)
            ? null
            : () async {
                await _processPayment();
              },
        child: Text(
          _orderCreated
              ? AppLocalization.getText('orderPlaced')
              : AppLocalization.getText('payAmountButton',
                  params: {'amount': widget.amount.toStringAsFixed(2)}),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showProcessingDialog() {
    _processingDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isCreatingOrder
                  ? AppLocalization.getText('creatingOrder')
                  : AppLocalization.getText('processingPayment'),
            ),
          ],
        ),
      ),
    );
  }

  void _hideProcessingDialog([NavigatorState? navigator]) {
    if (!_processingDialogVisible) return;
    _processingDialogVisible = false;
    final nav = navigator ?? Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  void _showErrorDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(msg),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (!_orderCreated) {
                Navigator.of(context).pop();
              }
            },
            child: Text(AppLocalization.getText('ok')),
          )
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(BuildContext context, String? orderId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Timer(const Duration(seconds: 5), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFFE8DFFF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Color(0xFF4A22A8),
                            size: 45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          AppLocalization.getText('orderPlacedSuccessfully'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (orderId != null)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              AppLocalization.getText('orderIdSuccess',
                                  params: {'orderId': orderId}),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppLocalization.getText('amountPaid'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '€${widget.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          AppLocalization.getText('orderDeliveryInfo'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 20,
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
}
