import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import './widgets/small_wave_loader.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'app_notification.dart';
import 'app_localization.dart';
import 'cart.dart';

class ItalyItemsPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  final List<Map<String, dynamic>> cartItems;

  const ItalyItemsPage(
      {Key? key, required this.onAddToCart, this.cartItems = const []})
      : super(key: key);

  @override
  State<ItalyItemsPage> createState() => _ItalyItemsPageState();
}

class _ItalyItemsPageState extends State<ItalyItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All";
  List<String> _dynamicFilters = ["All"];

  bool _isLoading = true;
  List<DocumentSnapshot> _cachedDocs = [];
  StreamSubscription? _streamSubscription;

  @override
  void initState() {
    super.initState();
    AppLocalization.currentLanguage.addListener(_onLanguageChanged);
    _startLoadingData();
  }

  void _startLoadingData() {
    print("🔥 Starting to load Italy Items data...");
    print("🔍 Querying collection: products_sl");
    print("🔍 Filter: category == 'Italy items'");

    _streamSubscription = FirebaseFirestore.instance
        .collection("products_sl")
        .where("category", isEqualTo: "Italy items")
        .snapshots()
        .listen(
      (snapshot) {
        print("✅ Received ${snapshot.docs.length} Italy items products");

        // Debug: Print each product's details
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          print("📦 Product: ${doc.id}");
          print("   - Name: ${data?['name']}");
          print("   - Category: '${data?['category']}'");
        }

        if (!mounted) return;

        setState(() {
          _cachedDocs = snapshot.docs;
          _isLoading = false;
        });

        _updateFilters();
      },
      onError: (error) {
        print("❌ Error loading products: $error");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  void _updateFilters() {
    if (_cachedDocs.isEmpty) return;

    final subCategories = <String>{};

    for (var doc in _cachedDocs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('subCategory')) {
        final subCat = data['subCategory'];
        if (subCat != null && subCat is String && subCat.isNotEmpty) {
          subCategories.add(subCat);
        }
      }
    }

    final newFilters = ["All", ...subCategories.toList()];

    if (mounted) {
      setState(() => _dynamicFilters = newFilters);
    }
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

  void _filterProducts(String query) {
    setState(() => _searchQuery = query.toLowerCase());
  }

  void _selectFilter(String filter) {
    setState(() => _selectedFilter = filter);
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    product['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: product['imageUrl']?.toString() ?? '',
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
                      child: Icon(Icons.shopping_bag,
                          size: 60, color: Color(0xFF7E62C8)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if ((product['description']?.toString() ?? '').isNotEmpty)
                  Text(
                    product['description'].toString(),
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 22),
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

  Widget _buildFilterChips() {
    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dynamicFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _dynamicFilters[index];
          final isSelected = _selectedFilter == filter;

          return InkWell(
            onTap: () => _selectFilter(filter),
            borderRadius: BorderRadius.circular(18),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
              builder: (context, value, child) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: value > 0
                        ? LinearGradient(
                            colors: [
                              Color.lerp(Colors.white, const Color(0xFF4A22A8),
                                  value)!,
                              Color.lerp(Colors.white, const Color(0xFF8E6AE8),
                                  value)!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: value == 0 ? Colors.white : null,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Color.lerp(
                          Colors.grey.shade300, Colors.transparent, value)!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.lerp(
                          Colors.transparent,
                          const Color(0xFF4A22A8).withOpacity(0.25),
                          value,
                        )!,
                        blurRadius: lerpDouble(0, 6, value)!,
                        offset: Offset(0, lerpDouble(0, 3, value)!),
                      ),
                    ],
                  ),
                  child: Text(
                    filter == "All" ? AppLocalization.getText('all') : filter,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.lerp(
                        FontWeight.w600,
                        FontWeight.w700,
                        value,
                      ),
                      color: Color.lerp(Colors.black87, Colors.white, value),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Column(
            children: [
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
                          onTap: () => Navigator.pop(context),
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
                          AppLocalization.getText('italyItemsTitle'),
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterProducts,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: AppLocalization.getText('searchItalyItems'),
                    hintStyle:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 10),
                      child: Icon(Icons.search,
                          color: Colors.grey.shade600, size: 18),
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildFilterChips(),
              ),
              Expanded(
                child: _buildContent(),
              )
            ],
          ),
          if (widget.cartItems.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Cart(
                          cartItems: widget.cartItems,
                          onRemoveFromCart: (index) =>
                              setState(() => widget.cartItems.removeAt(index)),
                          onUpdateCartItem: (index, item) =>
                              setState(() => widget.cartItems[index] = item),
                          onBack: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A22A8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 8,
                    shadowColor: Colors.black45,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_basket, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'View Basket (${widget.cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))})',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SmallWaveLoader(),
      );
    }

    if (_cachedDocs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              AppLocalization.getText('noResultsFound'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No Italy items found',
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
      final product = doc.data() as Map<String, dynamic>?;
      if (product == null) return false;

      final name = (product["name"] ?? "").toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);

      final matchesFilter =
          _selectedFilter == "All" || product['subCategory'] == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              AppLocalization.getText('noResultsFound'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filteredProducts.length,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final doc = filteredProducts[index];
        final productData = doc.data() as Map<String, dynamic>?;

        if (productData == null) {
          return const SizedBox.shrink();
        }

        final fullProductData = {'id': doc.id, ...productData};
        final String prodId = fullProductData['id']?.toString() ?? '';

        // Find quantity in cart
        final cartItem = widget.cartItems.firstWhere(
          (i) => i['id']?.toString() == prodId,
          orElse: () => <String, dynamic>{},
        );
        final cartQty =
            cartItem.isNotEmpty ? (cartItem['quantity'] as num).toInt() : 0;

        return _ItalyItemListItem(
          key: ValueKey(prodId),
          product: fullProductData,
          cartQty: cartQty,
          onAddToCart: (p) => setState(() => widget.onAddToCart(p)),
          onImageTap: () => _showProductDetails(context, fullProductData),
        );
      },
    );
  }
}

class _ItalyItemListItem extends StatefulWidget {
  final Map<String, dynamic> product;
  final int cartQty;
  final Function(Map<String, dynamic>) onAddToCart;
  final VoidCallback onImageTap;

  const _ItalyItemListItem({
    Key? key,
    required this.product,
    required this.cartQty,
    required this.onAddToCart,
    required this.onImageTap,
  }) : super(key: key);

  @override
  _ItalyItemListItemState createState() => _ItalyItemListItemState();
}

class _ItalyItemListItemState extends State<_ItalyItemListItem> {
  late int _localQty;
  late String _unit;
  late double _basePrice;

  @override
  void initState() {
    super.initState();
    _localQty = widget.cartQty;
    _unit = widget.product['uom']?.toString().toLowerCase() ?? 'piece';
    _basePrice = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  void didUpdateWidget(_ItalyItemListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cartQty != oldWidget.cartQty) {
      setState(() {
        _localQty = widget.cartQty;
      });
    }
  }

  void _updateCart(int delta, double price, String uom) {
    final Map<String, dynamic> itemToSend =
        Map<String, dynamic>.from(widget.product);
    itemToSend['quantity'] = delta;
    itemToSend['selectedUnit'] = uom;
    itemToSend['finalPrice'] = price * delta;
    itemToSend['unitPrice'] = price;

    widget.onAddToCart(itemToSend);
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
      'quantity': _localQty,
      'selectedUnit': _unit,
      'price': _basePrice, // Original price
      'finalPrice': _basePrice * _localQty,
      'unitPrice': _basePrice, // Store the discounted unit price
    };
    widget.onAddToCart(cartItem);
    showAppNotification(
      title: AppLocalization.getText('addedToCart'),
      message: AppLocalization.getText('addedToCartMessage').replaceAll(
          '{productName}', widget.product['name']?.toString() ?? ''),
      type: NotificationType.success,
    );
  }

  Widget _buildProductImage() {
    final imageUrl = widget.product['imageUrl'] as String?;

    Widget fallbackImage = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4F0FF), Color(0xFFE8DFFF)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.shopping_bag, color: Color(0xFF5B35B8), size: 24),
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return fallbackImage;
    }

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
            print("❌ Error loading image: $error");
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
    final name = widget.product['name']?.toString() ?? 'Italy Item';
    final description = widget.product['description']?.toString() ?? '';

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
          _buildProductImage(),
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
          _buildCounterControl(_basePrice, _unit),
        ],
      ),
    );
  }

  Widget _buildCounterControl(double price, String uom) {
    int _localQty = widget.cartQty;

    if (_localQty <= 0) {
      return GestureDetector(
        onTap: () {
          setState(() => _localQty = 1);
          _updateCart(1, price, uom);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF4A22A8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 2),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_localQty == 1)
            _qtyBtn(Icons.delete_outline, () {
              setState(() => _localQty = 0);
              _updateCart(-1, price, uom);
            }, color: Colors.red.shade500)
          else
            _qtyBtn(Icons.remove, () {
              setState(() => _localQty--);
              _updateCart(-1, price, uom);
            }),
          const SizedBox(width: 12),
          Text('$_localQty',
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.black)),
          const SizedBox(width: 12),
          const SizedBox(width: 12),
          _qtyBtn(Icons.add, () {
            setState(() => _localQty++);
            _updateCart(1, price, uom);
          }),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFF4A22A8)).withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 22, color: color ?? const Color(0xFF4A22A8)),
      ),
    );
  }
}
