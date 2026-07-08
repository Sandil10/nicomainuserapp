import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'help.dart';
import 'app_localization.dart';

class OrdersPayments extends StatefulWidget {
  const OrdersPayments({Key? key}) : super(key: key);

  @override
  State<OrdersPayments> createState() => _OrdersPaymentsState();
}

class _OrdersPaymentsState extends State<OrdersPayments> {
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeComponent();
  }

  Future<void> initializeComponent() async {
    await AppLocalization.initialize();
    await checkForUnviewedSuccessOrder();
    if (mounted) {
      setState(() {
        isInitialized = true;
      });
    }
  }

  Future<void> checkForUnviewedSuccessOrder() async {
    // This logic remains unchanged
  }

  void showOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4A22A8),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF4A22A8),
                size: 20,
              ),
            ),
            title: Text(
              AppLocalization.getText('ordersTitle'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      AppLocalization.getText('viewPastCurrentOrders'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: showOrderHistory,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF4A22A8).withOpacity(0.1),
                                      const Color(0xFF8E6AE8).withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF4A22A8)
                                        .withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  color: Color(0xFF4A22A8),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalization.getText('orderHistory'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF1F2937),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppLocalization.getText(
                                          'trackPurchasesDelivery'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFF9CA3AF),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// === ANIMATED BIKE DELIVERY ===
class AnimatedBikeDelivery extends StatefulWidget {
  final bool isActive;
  const AnimatedBikeDelivery({Key? key, this.isActive = true})
      : super(key: key);

  @override
  State<AnimatedBikeDelivery> createState() => _AnimatedBikeDeliveryState();
}

class _AnimatedBikeDeliveryState extends State<AnimatedBikeDelivery>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A22A8).withOpacity(0.05),
            const Color(0xFF8E6AE8).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4A22A8).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              AppLocalization.getText('orderOnTheWay'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                left: _animation.value *
                    (MediaQuery.of(context).size.width - 120),
                top: 25,
                child: const Icon(
                  Icons.delivery_dining,
                  color: Color(0xFF4A22A8),
                  size: 28,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// === ORDER HISTORY PAGE ===
class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Stream<QuerySnapshot>? ordersStream;
  User? currentUser;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeComponent();
  }

  Future<void> initializeComponent() async {
    await AppLocalization.initialize();
    initializeOrdersStream();
    if (mounted) {
      setState(() {
        isInitialized = true;
      });
    }
  }

  void initializeOrdersStream() {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('🔍 DEBUG: Fetching orders for userId: ${currentUser!.uid}');

      // Remove orderBy to avoid composite index requirement
      // We'll sort in memory instead
      ordersStream = FirebaseFirestore.instance
          .collection('orders_sl')
          .where('userId', isEqualTo: currentUser!.uid)
          .snapshots();

      FirebaseFirestore.instance
          .collection('orders_sl')
          .where('userId', isEqualTo: currentUser!.uid)
          .get()
          .then((snapshot) {
        print('📦 DEBUG: Total orders found: ${snapshot.docs.length}');
        for (var doc in snapshot.docs) {
          final data = doc.data();
          print('   Order ID: ${doc.id}');
          print('   Payment Method: ${data['paymentMethod']}');
          print('   Order Status: ${data['orderStatus']}');
          print('   Total: ${data['totalAmount']}');
          print('   Order Date: ${data['orderDate']}');
          print('   ---');
        }
      }).catchError((error) {
        print('❌ DEBUG: Error fetching orders: $error');
      });
    } else {
      ordersStream = null;
      print('❌ DEBUG: No user logged in');
    }
  }

  String getShortOrderId(String? orderId) {
    if (orderId == null || orderId.isEmpty) {
      return AppLocalization.getText('notAvailable');
    }
    return orderId.length > 8 ? orderId.substring(0, 8) : orderId;
  }

  String getStatusText(String? status) {
    if (status == null) return AppLocalization.getText('processing');

    switch (status.toLowerCase()) {
      case 'processing':
        return AppLocalization.getText('processing');
      case 'preparing':
        return AppLocalization.getText('preparing');
      case 'on the way':
        return AppLocalization.getText('onTheWay');
      case 'delivered':
        return AppLocalization.getText('delivered');
      case 'cancelled':
        return AppLocalization.getText('cancelled');
      case 'pending':
        return AppLocalization.getText('pending');
      case 'confirmed':
        return AppLocalization.getText('confirmed');
      case 'completed':
        return AppLocalization.getText('completed');
      case 'failed':
        return AppLocalization.getText('failed');
      default:
        return status
            .replaceAll('_', ' ')
            .split(' ')
            .map((str) =>
                str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : '')
            .join(' ');
    }
  }

  String getPaymentMethodText(String? method) {
    if (method == null) return AppLocalization.getText('notAvailable');

    switch (method.toLowerCase()) {
      case 'card':
        return AppLocalization.getText('card');
      case 'cash on delivery':
        return AppLocalization.getText('cashOnDelivery');
      default:
        return method;
    }
  }

  Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'confirmed':
        return const Color(0xFF8E6AE8);
      case 'on the way':
      case 'preparing':
        return const Color(0xFF4A22A8);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  bool isActiveDelivery(String? status) {
    return ['preparing', 'on the way'].contains(status?.toLowerCase());
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return AppLocalization.getText('unknownDate');

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
      return AppLocalization.getText('unknownDate');
    } catch (e) {
      print('Error formatting date: $e');
      return AppLocalization.getText('unknownDate');
    }
  }

  String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return AppLocalization.getText('unknownDateTime');

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return AppLocalization.getText('unknownDateTime');
    } catch (e) {
      print('Error formatting datetime: $e');
      return AppLocalization.getText('unknownDateTime');
    }
  }

  double parseTotal(dynamic total) {
    if (total == null) return 0.0;
    if (total is String) {
      return double.tryParse(total) ?? 0.0;
    }
    if (total is num) {
      return total.toDouble();
    }
    return 0.0;
  }

  String safeStringValue(dynamic value) {
    if (value == null) return AppLocalization.getText('notAvailable');
    if (value is String) {
      return value.isEmpty ? AppLocalization.getText('notAvailable') : value;
    }
    if (value is Map && value.containsKey('streetAddress')) {
      return value['streetAddress']?.toString() ??
          AppLocalization.getText('notAvailable');
    }
    return value.toString();
  }

  String getDeliveryAddress(dynamic addressData) {
    if (addressData == null) return AppLocalization.getText('notAvailable');

    if (addressData is String) {
      return addressData.isEmpty
          ? AppLocalization.getText('notAvailable')
          : addressData;
    }

    if (addressData is Map<String, dynamic>) {
      final streetAddress = addressData['streetAddress']?.toString() ?? '';
      final city = addressData['city']?.toString() ?? '';

      List<String> addressParts = [];
      if (streetAddress.isNotEmpty) addressParts.add(streetAddress);
      if (city.isNotEmpty) addressParts.add(city);

      return addressParts.isEmpty
          ? AppLocalization.getText('notAvailable')
          : addressParts.join(', ');
    }

    return addressData.toString();
  }

  List<Map<String, dynamic>> getOrderItems(Map<String, dynamic> order) {
    List<Map<String, dynamic>> items = [];
    List<dynamic>? rawItems = order['orderItems'] ??
        order['items'] ??
        order['cartItems'] ??
        order['products'];

    if (rawItems != null && rawItems.isNotEmpty) {
      for (var item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add({
            'name': item['name'] ??
                item['productName'] ??
                item['title'] ??
                AppLocalization.getText('unknownItem'),
            'price': parseTotal(item['price'] ?? item['unitPrice'] ?? 0),
            'quantity': item['quantity'] ?? item['qty'] ?? 1,
            'uom':
                item['uom'] ?? item['unit'] ?? item['unitOfMeasure'] ?? 'pcs',
            'image': item['image'] ?? item['imageUrl'] ?? '',
            'description': item['description'] ?? '',
            'total': parseTotal(item['total'] ?? item['finalPrice'] ?? 0),
            'discountType': item['discountType'],
            'discount': item['discount'],
            'fixedPrice': item['fixedPrice'],
            'unitPrice': item['unitPrice'],
          });
        }
      }
    }

    if (items.isEmpty) {
      items.add({
        'name': AppLocalization.getText('orderItemsNotAvailable'),
        'price': 0.0,
        'quantity': 0,
        'uom': AppLocalization.getText('notAvailable'),
        'image': '',
        'description': '',
        'total': 0.0,
      });
    }

    return items;
  }

  void showOrderDetails(Map<String, dynamic> order) {
    List<Map<String, dynamic>> orderItems = getOrderItems(order);
    double total = parseTotal(order['totalAmount']);
    double subtotal = parseTotal(order['subtotal'] ?? 0);
    double deliveryFee = parseTotal(order['deliveryFee'] ?? 0);

    if (subtotal == 0.0) {
      subtotal = orderItems.fold(
          0.0, (sum, item) => sum + (item['price'] * item['quantity']));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalization.getText('orderDetails'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalization.getText('orderNumber', params: {
                                  'orderId': getShortOrderId(order['orderId'])
                                }),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: getStatusColor(order['orderStatus']),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            getStatusText(order['orderStatus']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoSection(
                        AppLocalization.getText('orderInformation'), [
                      _buildInfoRow(
                          AppLocalization.getText('orderDate'),
                          formatDateTime(
                              order['orderDate'] ?? order['createdAt'])),
                      if (order['deliveryDate'] != null)
                        _buildInfoRow(AppLocalization.getText('deliveryDate'),
                            formatDate(order['deliveryDate'])),
                    ]),
                    _buildInfoSection(
                        AppLocalization.getText('paymentInformation'), [
                      _buildInfoRow(
                          AppLocalization.getText('paymentMethod'),
                          getPaymentMethodText(
                              safeStringValue(order['paymentMethod']))),
                      _buildInfoRow(
                          AppLocalization.getText('paymentStatus'),
                          getStatusText(
                              safeStringValue(order['paymentStatus']))),
                    ]),
                    if (order['deliveryAddress'] != null) ...[
                      _buildInfoSection(
                          AppLocalization.getText('deliveryAddressLabel'), [
                        _buildInfoRow(AppLocalization.getText('address'),
                            getDeliveryAddress(order['deliveryAddress'])),
                        if (order['deliveryAddress'] is Map &&
                            order['deliveryAddress']['city'] != null)
                          _buildInfoRow(
                              AppLocalization.getText('city'),
                              safeStringValue(
                                  order['deliveryAddress']['city'])),
                        if (order['deliveryAddress'] is Map &&
                            order['deliveryAddress']['notes'] != null &&
                            safeStringValue(
                                    order['deliveryAddress']['notes']) !=
                                AppLocalization.getText('notAvailable'))
                          _buildInfoRow(
                              AppLocalization.getText('deliveryNotes'),
                              safeStringValue(
                                  order['deliveryAddress']['notes'])),
                      ]),
                    ],
                    _buildInfoSection(
                        AppLocalization.getText('customerInformation'), [
                      if (order['customerName'] != null)
                        _buildInfoRow(AppLocalization.getText('name'),
                            safeStringValue(order['customerName'])),
                      if (order['customerPhone'] != null)
                        _buildInfoRow(AppLocalization.getText('phone'),
                            safeStringValue(order['customerPhone'])),
                    ]),
                    if (isActiveDelivery(order['orderStatus']))
                      const AnimatedBikeDelivery(isActive: true),
                    const SizedBox(height: 8),
                    _buildItemsSection(orderItems),
                    const SizedBox(height: 24),
                    _buildSummarySection(subtotal, deliveryFee, total),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildItemsSection(List<Map<String, dynamic>> orderItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalization.getText('yourItems'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              AppLocalization.getText('itemsCount',
                  params: {'count': orderItems.length.toString()}),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...orderItems.map((item) => _buildOrderItem(item)).toList(),
      ],
    );
  }

  Widget _buildSummarySection(
      double subtotal, double deliveryFee, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A22A8).withOpacity(0.05),
            const Color(0xFF8E6AE8).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF4A22A8).withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalization.getText('orderSummary'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          if (subtotal > 0)
            _buildSummaryRow(AppLocalization.getText('subtotal'),
                'Rs.${subtotal.toStringAsFixed(2)}'),
          if (deliveryFee > 0)
            _buildSummaryRow(AppLocalization.getText('deliveryFee'),
                'Rs.${deliveryFee.toStringAsFixed(2)}'),
          if (subtotal > 0 || deliveryFee > 0) ...[
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 8),
          ],
          _buildSummaryRow(AppLocalization.getText('total'),
              'Rs.${total.toStringAsFixed(2)}',
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final name = item['name'] ?? AppLocalization.getText('unknownItem');
    final originalPrice = item['price'] ?? 0.0;
    final quantity = item['quantity'] ?? 1;
    final uom = item['uom'] ?? 'pcs';
    // Use unitPrice if available (this is the discounted price we saved to the order)
    final discountedUnitPrice = item['unitPrice'] ?? originalPrice;
    final itemTotal = item['total'] ?? (discountedUnitPrice * quantity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        height: 1.3,
                      ),
                    ),
                    if (item['discountType'] == 'fixed' ||
                        item['discountType'] == 'normal')
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['discountType'] == 'fixed'
                              ? 'SALE'
                              : '-${item['discount']}% OFF',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item['discountType'] == 'fixed' ||
                      item['discountType'] == 'normal')
                    Text(
                      'Rs.${(originalPrice * quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    'Rs.${itemTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A22A8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalization.getText('qty',
                      params: {'quantity': quantity.toString()}),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A22A8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  uom,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A22A8),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                AppLocalization.getText('each',
                    params: {'price': discountedUnitPrice.toStringAsFixed(2)}),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isTotal ? const Color(0xFF1F2937) : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color:
                  isTotal ? const Color(0xFF4A22A8) : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalization.getText('noOrdersYet'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalization.getText('viewPastCurrentOrders'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNotSignedInState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.login_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalization.getText('pleaseSignInToView'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4A22A8),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF4A22A8),
                size: 20,
              ),
            ),
            title: Text(
              AppLocalization.getText('orderHistoryTitle'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: false,
          ),
          body: currentUser == null
              ? buildNotSignedInState()
              : StreamBuilder<QuerySnapshot>(
                  stream: ordersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4A22A8),
                          strokeWidth: 2.5,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      print('❌ ERROR in StreamBuilder: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${AppLocalization.getText('error')}: ${snapshot.error}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print('⚠️ DEBUG: No orders found for user');
                      return buildEmptyState();
                    }

                    final orders = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['orderId'] = data['orderId'] ?? doc.id;
                      return data;
                    }).toList();

                    // Sort orders by orderDate in descending order (newest first)
                    orders.sort((a, b) {
                      final aDate = a['orderDate'] as Timestamp?;
                      final bDate = b['orderDate'] as Timestamp?;
                      if (aDate == null && bDate == null) return 0;
                      if (aDate == null) return 1;
                      if (bDate == null) return -1;
                      return bDate.compareTo(aDate); // Descending order
                    });

                    print('✅ DEBUG: Displaying ${orders.length} orders');

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        List<Map<String, dynamic>> items = getOrderItems(order);
                        int itemsCount = items.length;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => showOrderDetails(order),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          AppLocalization.getText('orderNumber',
                                              params: {
                                                'orderId': getShortOrderId(
                                                    order['orderId'])
                                              }),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: getStatusColor(
                                                order['orderStatus']),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            getStatusText(order['orderStatus']),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatDate(order['orderDate'] ??
                                          order['createdAt']),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          AppLocalization.getText('itemsCount',
                                              params: {
                                                'count': itemsCount.toString()
                                              }),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Rs.${parseTotal(order['totalAmount']).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF4A22A8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpPage()),
              );
            },
            backgroundColor: const Color(0xFF4A22A8),
            elevation: 4,
            child:
                const Icon(Icons.support_agent, color: Colors.white, size: 24),
          ),
        );
      },
    );
  }
}
