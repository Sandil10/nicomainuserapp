import 'package:flutter/material.dart';
import 'app_notification.dart';
import 'app_localization.dart';
import 'widgets/app_image.dart';

/// Product detail screen matching the design (purple header with the food
/// image, a white rounded sheet with rating, price, quantity selector and an
/// "Add to cart" button).
class FoodDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onAddToCart;

  const FoodDetailPage({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  static const Color primaryPurple = Color(0xFF4A22A8);

  int _quantity = 1;
  late final double _basePrice;
  late final String _unit;

  @override
  void initState() {
    super.initState();
    _basePrice = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
    _unit = widget.product['uom']?.toString().toLowerCase() ?? 'piece';
  }

  // Discounted unit price, mirroring the logic used elsewhere in the app.
  double get _unitPrice {
    if (widget.product['discountType'] == 'fixed') {
      return (widget.product['fixedPrice'] as num?)?.toDouble() ?? _basePrice;
    } else if (widget.product['discountType'] == 'normal') {
      final disc = (widget.product['discount'] as num?)?.toDouble() ?? 0.0;
      return _basePrice * (1 - disc / 100);
    }
    return _basePrice;
  }

  void _adjustQuantity(int amount) {
    setState(() {
      _quantity = (_quantity + amount).clamp(1, 999);
    });
  }

  void _handleAddToCart() {
    final unitPrice = _unitPrice;
    final cartItem = {
      'id': widget.product['id'],
      ...widget.product,
      'quantity': _quantity,
      'selectedUnit': _unit,
      'price': _basePrice,
      'unitPrice': unitPrice,
      'finalPrice': unitPrice * _quantity,
    };
    widget.onAddToCart(cartItem);
    showAppNotification(
      title: AppLocalization.getText('addedToCart'),
      message: AppLocalization.getText('addedToCartMessage').replaceAll(
          '{productName}', widget.product['name']?.toString() ?? ''),
      type: NotificationType.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.product['name']?.toString() ?? 'Item';
    final description = widget.product['description']?.toString() ?? '';
    final rating = (widget.product['rating'] as num?)?.toDouble();
    final imageUrl = resolveImageSource(widget.product);
    final hasDiscount = widget.product['discountType'] == 'fixed' ||
        widget.product['discountType'] == 'normal';

    return Scaffold(
      backgroundColor: primaryPurple,
      body: Column(
        children: [
          // ===== Purple header with the product image =====
          Expanded(
            flex: 5,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: AppImage(
                        imageSource: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                            strokeWidth: 2,
                          ),
                        ),
                        fallback: const Icon(Icons.fastfood,
                            color: Colors.white70, size: 90),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 12,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== White rounded info sheet =====
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating badge + price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (rating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: primaryPurple,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFE8A600), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                'Rs.${_basePrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              'Rs.${_unitPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFFE8A600),
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Name + quantity selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            _qtyButton(Icons.remove, () => _adjustQuantity(-1)),
                            Container(
                              width: 34,
                              alignment: Alignment.center,
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            _qtyButton(Icons.add, () => _adjustQuantity(1)),
                          ],
                        ),
                      ],
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Add to cart button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _handleAddToCart,
                        child: Text(
                          AppLocalization.getText('addToCart'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: primaryPurple, width: 1.5),
        ),
        child: Icon(icon, size: 18, color: primaryPurple),
      ),
    );
  }
}
