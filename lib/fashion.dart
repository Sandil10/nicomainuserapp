import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import './widgets/small_wave_loader.dart';
import 'dart:async';
import 'dart:math';
import 'app_notification.dart';
import 'app_localization.dart';

class FashionPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddToCart;

  const FashionPage({Key? key, required this.onAddToCart}) : super(key: key);

  @override
  State<FashionPage> createState() => _FashionPageState();
}

class _FashionPageState extends State<FashionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isLoading = true;
  List<DocumentSnapshot> _cachedDocs = [];
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    AppLocalization.currentLanguage.addListener(_onLanguageChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLoadingData();
    });
  }

  void _startLoadingData() async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    _streamSubscription = FirebaseFirestore.instance
        .collection('products_sl')
        .where('category', isEqualTo: 'Fashion')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      print('📦 Loaded ${snapshot.docs.length} fashion products');
      if (snapshot.docs.isNotEmpty) {
        final firstDoc = snapshot.docs.first.data() as Map<String, dynamic>;
        print('🔍 First product data: $firstDoc');
        print('🖼️ Image URL field: ${firstDoc['imageUrl']}');
      }

      setState(() {
        _cachedDocs = snapshot.docs;
        _isLoading = false;
      });
    }, onError: (error) {
      print('❌ Firestore Error: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _streamSubscription?.cancel();
    AppLocalization.currentLanguage.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    product['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Discount Badge if applicable
                if (product['discountType'] == 'fixed' ||
                    product['discountType'] == 'normal')
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product['discountType'] == 'fixed'
                          ? 'SALE'
                          : '-${product['discount']}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: product['imageUrl'] ?? '',
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer(
                      duration: const Duration(seconds: 2),
                      interval: const Duration(seconds: 2),
                      color: Colors.grey.shade300,
                      colorOpacity: 0.4,
                      enabled: true,
                      direction: const ShimmerDirection.fromLTRB(),
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF4F0FF), Color(0xFFE8DFFF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.checkroom,
                          size: 60, color: Color(0xFF7E62C8)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                if ((product['description'] ?? '').isNotEmpty)
                  Text(
                    product['description'],
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 22),
                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (product['discountType'] == 'fixed' ||
                        product['discountType'] == 'normal') ...[
                      Text(
                        'Rs.${(product['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Rs.',
                      style: TextStyle(
                        color: (product['discountType'] == 'fixed' ||
                                product['discountType'] == 'normal')
                            ? Color(0xFF4A22A8)
                            : Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      () {
                        double price =
                            (product['price'] as num?)?.toDouble() ?? 0.0;
                        if (product['discountType'] == 'fixed') {
                          return (product['fixedPrice'] as num?)
                                  ?.toStringAsFixed(2) ??
                              '0.00';
                        } else if (product['discountType'] == 'normal') {
                          double disc =
                              (product['discount'] as num?)?.toDouble() ?? 0.0;
                          return (price * (1 - disc / 100)).toStringAsFixed(2);
                        }
                        return price.toStringAsFixed(2);
                      }(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: (product['discountType'] == 'fixed' ||
                                product['discountType'] == 'normal')
                            ? Color(0xFF4A22A8)
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Custom AppBar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.arrow_back,
                            size: 18, color: Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalization.getText('fashion'),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: AppLocalization.getText('searchFashionItems'),
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 10),
                  child:
                      Icon(Icons.search, color: Colors.grey.shade600, size: 18),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Product List
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SmallWaveLoader(color: Color(0xFF4A22A8)),
      );
    }

    if (_cachedDocs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checkroom_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              AppLocalization.getText('noFashionItemsFound'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No fashion items available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final filteredProducts = _cachedDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      return _searchQuery.isEmpty || name.contains(_searchQuery);
    }).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? AppLocalization.getText('noFashionItemsFound')
                  : '${AppLocalization.getText('noResultsFor')} "$_searchQuery"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: filteredProducts.length,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final doc = filteredProducts[index];
        final productData = doc.data() as Map<String, dynamic>;
        final fullProductData = {'id': doc.id, ...productData};
        return _FashionListItem(
          key: ValueKey(doc.id),
          product: fullProductData,
          onAddToCart: widget.onAddToCart,
          onImageTap: () => _showProductDetails(context, fullProductData),
        );
      },
    );
  }
}

class _FashionListItem extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onAddToCart;
  final VoidCallback onImageTap;

  const _FashionListItem({
    Key? key,
    required this.product,
    required this.onAddToCart,
    required this.onImageTap,
  }) : super(key: key);

  @override
  _FashionListItemState createState() => _FashionListItemState();
}

class _FashionListItemState extends State<_FashionListItem> {
  int _quantity = 1;
  late String _unit;
  late double _basePrice;

  @override
  void initState() {
    super.initState();
    _unit = widget.product['uom']?.toLowerCase() ?? 'item';
    _basePrice = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
  }

  void _adjustQuantity(int amount) {
    setState(() {
      int newQuantity = _quantity + amount;
      if (newQuantity < 1) {
        newQuantity = 1;
      }
      _quantity = newQuantity;
    });
  }

  void _handleAddToCart() {
    double finalUnitPrice = _basePrice;
    if (widget.product['discountType'] == 'fixed') {
      finalUnitPrice =
          (widget.product['fixedPrice'] as num?)?.toDouble() ?? _basePrice;
    } else if (widget.product['discountType'] == 'normal') {
      double disc = (widget.product['discount'] as num?)?.toDouble() ?? 0.0;
      finalUnitPrice = _basePrice * (1 - disc / 100);
    }

    final cartItem = {
      'id': widget.product['id'],
      ...widget.product,
      'quantity': _quantity,
      'selectedUnit': _unit,
      'price': _basePrice, // Original price
      'finalPrice': finalUnitPrice * _quantity,
      'unitPrice': finalUnitPrice, // Store the discounted unit price
    };
    widget.onAddToCart(cartItem);
    showAppNotification(
      title: AppLocalization.getText('addedToCart'),
      message: AppLocalization.getText('addedToCartMessage')
          .replaceAll('{productName}', widget.product['name'] ?? ''),
      type: NotificationType.success,
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    final fallbackImage = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4F0FF), Color(0xFFE8DFFF)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.checkroom, color: Color(0xFF5B35B8), size: 24),
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return fallbackImage;
    }

    // Professional shimmer loading placeholder
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
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    return InkWell(
      onTap: widget.onImageTap,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          memCacheWidth: 120,
          maxHeightDiskCache: 120,
          maxWidthDiskCache: 120,
          placeholder: (context, url) => shimmerPlaceholder,
          errorWidget: (context, url, error) {
            print('❌ Failed to load image: $imageUrl');
            print('Error: $error');
            return fallbackImage;
          },
        ),
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

  @override
  Widget build(BuildContext context) {
    final name = widget.product['name'] ?? 'Fashion Item';
    final description = widget.product['description'] ?? '';
    final imageUrl = widget.product['imageUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProductImage(imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                if (widget.product['discountType'] == 'fixed' ||
                    widget.product['discountType'] == 'normal')
                  Row(
                    children: [
                      Text(
                        'Rs.${_basePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.product['discountType'] == 'fixed'
                              ? 'SALE'
                              : '-${widget.product['discount']}%',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                Text(
                  () {
                    double finalPrice = _basePrice;
                    if (widget.product['discountType'] == 'fixed') {
                      finalPrice =
                          (widget.product['fixedPrice'] as num?)?.toDouble() ??
                              _basePrice;
                    } else if (widget.product['discountType'] == 'normal') {
                      double disc =
                          (widget.product['discount'] as num?)?.toDouble() ??
                              0.0;
                      finalPrice = _basePrice * (1 - disc / 100);
                    }
                    return 'Rs.${finalPrice.toStringAsFixed(2)} / $_unit';
                  }(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: (widget.product['discountType'] == 'fixed' ||
                            widget.product['discountType'] == 'normal')
                        ? Color(0xFF4A22A8)
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onTap: () => _adjustQuantity(-1),
              ),
              Container(
                width: 35,
                height: 24,
                alignment: Alignment.center,
                child: Text(
                  _quantity.toString(),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onTap: () => _adjustQuantity(1),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7E62C8),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(36, 30),
                  elevation: 0,
                ),
                onPressed: _handleAddToCart,
                child: Text(
                  AppLocalization.getText('add'),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
