import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import './widgets/small_wave_loader.dart';
import 'dart:async';

import 'checkout.dart';
import 'app_localization.dart';
import 'widgets/app_image.dart';

class Cart extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(int) onRemoveFromCart;
  final Function(int, Map<String, dynamic>) onUpdateCartItem;
  final VoidCallback? onBack;

  const Cart({
    Key? key,
    required this.cartItems,
    required this.onRemoveFromCart,
    required this.onUpdateCartItem,
    this.onBack,
  }) : super(key: key);

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _displayItems = [];
  double _baseDeliveryFee = 0.0;
  bool _isLoadingFee = true;
  StreamSubscription<DocumentSnapshot>? _feeSubscription;

  static const double _freeDeliveryThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _displayItems = List<Map<String, dynamic>>.from(widget.cartItems);
    _subscribeToDeliveryFee();
  }

  @override
  void didUpdateWidget(Cart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the widget receives a new list of items from the parent,
    // we should update our local display list to keep them in sync.
    if (widget.cartItems.length != oldWidget.cartItems.length) {
      if (mounted) {
        setState(() {
          _displayItems = List<Map<String, dynamic>>.from(widget.cartItems);
        });
      }
    }
  }

  void _subscribeToDeliveryFee() {
    _feeSubscription = FirebaseFirestore.instance
        .collection('settings')
        .doc('appSettings_sl')
        .snapshots()
        .listen(
      (DocumentSnapshot snapshot) {
        if (!mounted) return;

        setState(() {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data() as Map<String, dynamic>;
            _baseDeliveryFee = (data['deliveryFee'] as num?)?.toDouble() ?? 0.0;
          } else {
            _baseDeliveryFee = 0.0;
          }
          _isLoadingFee = false;
        });
      },
      onError: (error) {
        debugPrint('❌ Error loading delivery fee: $error');
        if (mounted) {
          setState(() {
            _baseDeliveryFee = 0.0;
            _isLoadingFee = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _feeSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  double _calculateSubtotal() {
    return _displayItems.fold(0.0, (total, item) {
      // Use unitPrice (discounted) if available, else fallback to price
      double price = (item['unitPrice'] as num?)?.toDouble() ??
          (item['price'] as num?)?.toDouble() ??
          0.0;
      final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;
      return total + (price * qty);
    });
  }

  double _calculateDeliveryFee() {
    final subtotal = _calculateSubtotal();
    if (subtotal >= _freeDeliveryThreshold) {
      return 0.0;
    }
    return _baseDeliveryFee;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateDeliveryFee();
  }

  void _navigateToCheckout() {
    if (_displayItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.getText('cartEmpty')),
          backgroundColor: Color(0xFF4A22A8),
        ),
      );
      return;
    }

    if (_isLoadingFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading delivery fee, please wait...'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: _displayItems,
          subtotal: _calculateSubtotal(),
          deliveryFee: _calculateDeliveryFee(),
        ),
      ),
    );
  }

  void _localRemove(int index) {
    setState(() {
      _displayItems.removeAt(index);
    });
    widget.onRemoveFromCart(index);
  }

  void _localUpdate(int index, Map<String, dynamic> item) {
    setState(() {
      _displayItems[index] = item;
    });
    widget.onUpdateCartItem(index, item);
  }

  Widget _buildCheckoutSummary() {
    final subtotal = _calculateSubtotal();
    final deliveryFee = _calculateDeliveryFee();
    final amountNeededForFreeDelivery = _freeDeliveryThreshold - subtotal;
    final qualifiesForFreeDelivery = subtotal >= _freeDeliveryThreshold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner to encourage adding more items for free delivery
          if (!qualifiesForFreeDelivery &&
              amountNeededForFreeDelivery > 0 &&
              _baseDeliveryFee > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFF4F0FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFD8CCF6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined,
                      color: Color(0xFF4A22A8), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalization.getText('addMoreForFreeDelivery',
                          params: {
                            'amount':
                                amountNeededForFreeDelivery.toStringAsFixed(2)
                          }),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A22A8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Success Banner for Free Delivery
          if (qualifiesForFreeDelivery && _baseDeliveryFee > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFF4F0FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFD8CCF6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Color(0xFF4A22A8), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalization.getText('freeDeliveryQualified'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A22A8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Subtotal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalization.getText('subtotal'),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Text(
                'Rs.${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Delivery Fee Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalization.getText('deliveryFee'),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 4),
                  if (_isLoadingFee)
                    const SizedBox(
                      width: 36,
                      height: 12,
                      child:
                          SmallWaveLoader(color: Color(0xFF4A22A8), size: 12),
                    ),
                ],
              ),
              _isLoadingFee
                  ? const SmallWaveLoader(color: Color(0xFF4A22A8), size: 12)
                  : Row(
                      children: [
                        if (deliveryFee == 0.0 && _baseDeliveryFee > 0)
                          Text(
                            'Rs.${_baseDeliveryFee.toStringAsFixed(2)} ',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        Text(
                          deliveryFee == 0.0
                              ? 'Free'
                              : 'Rs.${deliveryFee.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: deliveryFee == 0.0
                                ? Color(0xFF4A22A8)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
          const Divider(height: 24, thickness: 1),

          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalization.getText('total'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              _isLoadingFee
                  ? const SmallWaveLoader(color: Colors.black, size: 14)
                  : Text(
                      'Rs.${_calculateTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 16),

          // Order Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoadingFee
                    ? Colors.grey.shade300
                    : const Color(0xFF4A22A8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              onPressed: _isLoadingFee ? null : _navigateToCheckout,
              child: _isLoadingFee
                  ? const Center(
                      child: SmallWaveLoader(color: Colors.white, size: 14))
                  : Text(
                      AppLocalization.getText('order'),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Back to Menu link
          TextButton(
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.maybePop(context);
              }
            },
            child: Text(
              AppLocalization.getText('backToMenu'),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalization.getText('cartEmpty'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalization.getText('addItemsToStart'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          return;
        }
      },
      child: ValueListenableBuilder<String>(
        valueListenable: AppLocalization.currentLanguage,
        builder: (context, currentLanguage, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF8F9FA),
              elevation: 0,
              centerTitle: false,
              titleSpacing: 20,
              automaticallyImplyLeading: widget.onBack == null,
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: widget.onBack,
                    )
                  : null,
              title: Text(
                '${_displayItems.length} ${_displayItems.length == 1 ? AppLocalization.getText('item') : AppLocalization.getText('items')} in cart',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
            body: _displayItems.isEmpty
                ? _buildEmptyCart()
                : Column(
                    children: [
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: _displayItems.length,
                            itemBuilder: (context, index) {
                              return _CartListItem(
                                key: ValueKey(
                                    _displayItems[index]['id'] ?? index),
                                product: _displayItems[index],
                                onRemove: () => _localRemove(index),
                                onUpdate: (updatedItem) =>
                                    _localUpdate(index, updatedItem),
                              );
                            },
                          ),
                        ),
                      ),
                      _buildCheckoutSummary(),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// Cart List Item Widget
class _CartListItem extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onRemove;
  final Function(Map<String, dynamic>) onUpdate;

  const _CartListItem({
    Key? key,
    required this.product,
    required this.onRemove,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _CartListItemState createState() => _CartListItemState();
}

class _CartListItemState extends State<_CartListItem> {
  late int _quantity;
  late String _unit;
  late double _basePrice; // Original price
  late double _unitPrice; // Discounted price
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _unit = widget.product['selectedUnit'] ??
        widget.product['uom']?.toLowerCase() ??
        'piece';
    _quantity = (widget.product['quantity'] as num?)?.toInt() ?? 1;
    _basePrice = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
    _unitPrice =
        (widget.product['unitPrice'] as num?)?.toDouble() ?? _basePrice;
  }

  @override
  void didUpdateWidget(_CartListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product['quantity'] != widget.product['quantity']) {
      setState(() {
        _quantity = (widget.product['quantity'] as num?)?.toInt() ?? 1;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _updateParent() {
    final updatedItem = Map<String, dynamic>.from(widget.product);
    updatedItem['quantity'] = _quantity;
    updatedItem['finalPrice'] = _unitPrice * _quantity;
    widget.onUpdate(updatedItem);
  }

  void _debouncedUpdate() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      // Faster debounce
      if (mounted) _updateParent();
    });
  }

  void _adjustQuantity(int amount) {
    setState(() {
      int newQuantity = _quantity + amount;
      if (newQuantity < 1) {
        newQuantity = 1;
      }
      _quantity = newQuantity;
    });
    _debouncedUpdate();
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    Widget fallbackImage = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Color(0xFF4A22A8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.shopping_basket, color: Color(0xFF5B35B8), size: 24),
    );

    final imageUrl = resolveImageSource(product);

    Widget shimmerPlaceholder = Shimmer(
      duration: const Duration(milliseconds: 1500),
      interval: const Duration(milliseconds: 1500),
      color: Colors.white,
      colorOpacity: 0.5,
      enabled: true,
      direction: const ShimmerDirection.fromLTRB(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AppImage(
        imageSource: imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: shimmerPlaceholder,
        fallback: fallbackImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double lineTotal = _unitPrice * _quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.6),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProductImage(widget.product),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product['name'] ?? 'Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (_unitPrice < _basePrice)
                  Row(
                    children: [
                      Text(
                        'Rs.${_basePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rs.${_unitPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4A22A8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '$_quantity $_unit x Rs.${_basePrice.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Rs.${lineTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onTap: () => _adjustQuantity(-1),
              ),
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text(
                  _quantity.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onTap: () => _adjustQuantity(1),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onRemove,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8), // Increased touch area
                child: Icon(Icons.close, color: Colors.red.shade400, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: Colors.grey.shade700),
      ),
    );
  }
}
