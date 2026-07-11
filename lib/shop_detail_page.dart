import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:share_plus/share_plus.dart';
import './widgets/small_wave_loader.dart';
import './cart.dart';
import './food_detail_page.dart';
import './widgets/app_image.dart';

class ShopDetailPage extends StatefulWidget {
  final Map<String, dynamic> shopData;
  final Function(Map<String, dynamic>) onAddToCart;
  final List<Map<String, dynamic>> initialCartItems;

  const ShopDetailPage({
    Key? key,
    required this.shopData,
    required this.onAddToCart,
    this.initialCartItems = const [],
  }) : super(key: key);

  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage> {
  Map<String, dynamic>? _liveShopData;
  bool _isLoadingShop = true;
  List<Map<String, dynamic>> _allProducts = [];
  List<String> _categories = [];
  bool _isLoadingProducts = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<Map<String, dynamic>> _currentCartItems = [];
  bool _isDeliverySelected = true;

  @override
  void initState() {
    super.initState();
    _currentCartItems = widget.initialCartItems;
    _fetchLiveShopData();
    _fetchRestaurantProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveShopData() async {
    final String? shopId = widget.shopData['id'];
    if (shopId == null) {
      setState(() {
        _liveShopData = widget.shopData;
        _isLoadingShop = false;
      });
      return;
    }

    try {
      // Trying both common collection names for robustness
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(shopId)
          .get();
      if (!doc.exists) {
        doc = await FirebaseFirestore.instance
            .collection('Restaurants')
            .doc(shopId)
            .get();
      }

      if (doc.exists && mounted) {
        setState(() {
          _liveShopData = doc.data() as Map<String, dynamic>;
          _isLoadingShop = false;
        });
      } else {
        setState(() {
          _liveShopData = widget.shopData;
          _isLoadingShop = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching shop data: $e');
      if (mounted) {
        setState(() {
          _liveShopData = widget.shopData;
          _isLoadingShop = false;
        });
      }
    }
  }

  Future<void> _fetchRestaurantProducts() async {
    final String? shopId = widget.shopData['id'];
    if (shopId == null) {
      setState(() => _isLoadingProducts = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products_sl')
          .where('restaurantId', isEqualTo: shopId)
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'imageUrl': resolveImageSource(data),
        };
      }).toList();
      final cats = products
          .map((p) => p['category']?.toString() ?? 'General')
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          _allProducts = products;
          _categories = cats;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching products: $e');
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  void _navigateToCategoryProducts(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProductsPage(
          restaurantId: widget.shopData['id'] ?? '',
          restaurantName: _liveShopData?['name'] ?? widget.shopData['name'],
          category: category,
          onAddToCart: _handleCartAdd,
          initialCartItems: _currentCartItems,
        ),
      ),
    );
  }

  void _handleCartAdd(Map<String, dynamic> product) {
    print(
        "🛒 ShopDetailPage handling cart add for: ${product['name']} with delta: ${product['quantity']}");
    widget.onAddToCart(product);
    if (!mounted) return;
    setState(() {
      // Logic for adding/removing/updating is now handled centrally in UserPanel._addToCart
      // We just trigger a rebuild here to sync UI with the modified cartItems list
    });
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(
          cartItems: _currentCartItems,
          onRemoveFromCart: (index) =>
              setState(() => _currentCartItems.removeAt(index)),
          onUpdateCartItem: (index, item) =>
              setState(() => _currentCartItems[index] = item),
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayData = _liveShopData ?? widget.shopData;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Container(
            width: MediaQuery.of(context).size.width * 0.45,
            height: 34,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search menu...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon:
                    Icon(Icons.search, size: 16, color: Colors.grey.shade500),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: () {
              final String text =
                  'Check out ${displayData['name']} on Nico Mart! serving ${displayData['category'] ?? displayData['cuisine']} food. Rating: ${displayData['rating']} ⭐\nDownload Nico Mart now!';
              Share.share(text);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Details Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayData['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            '${displayData['rating'] ?? '0.0'} · ${displayData['category'] ?? displayData['cuisine'] ?? 'Sri Lankan'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Open until ${displayData['closingTime'] ?? displayData['openUntil'] ?? '10:00 PM'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _isDeliverySelected = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isDeliverySelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: _isDeliverySelected
                                        ? [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2))
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Delivery',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: _isDeliverySelected
                                              ? const Color(0xFF4A22A8)
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${displayData['deliveryTime'] ?? '25-30 min'} · Rs.250.00',
                                        style: TextStyle(
                                          color: _isDeliverySelected
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _isDeliverySelected = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isDeliverySelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: !_isDeliverySelected
                                        ? [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2))
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Pickup',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: !_isDeliverySelected
                                              ? const Color(0xFF4A22A8)
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Self collection',
                                        style: TextStyle(
                                          color: !_isDeliverySelected
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Dynamic Categories Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: const Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // Dynamic Category Grid
                if (_isLoadingProducts)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: SmallWaveLoader(size: 20)))
                else if (_categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.restaurant_menu,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                              'No menu items available for this restaurant',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _categories
                          .where((c) => c.toLowerCase().contains(_searchQuery))
                          .length,
                      itemBuilder: (context, index) {
                        final filteredCategories = _categories
                            .where(
                                (c) => c.toLowerCase().contains(_searchQuery))
                            .toList();
                        final category = filteredCategories[index];
                        final product = _allProducts.firstWhere(
                          (p) =>
                              p['category'] == category &&
                              resolveImageSource(p).isNotEmpty,
                          orElse: () => _allProducts.firstWhere(
                            (p) => p['category'] == category,
                            orElse: () => <String, dynamic>{},
                          ),
                        );
                        final String imageUrl = resolveImageSource(product);

                        return GestureDetector(
                          onTap: () => _navigateToCategoryProducts(category),
                          child: _buildCategoryCard(
                            image: imageUrl,
                            label: category,
                            itemsInCart: _currentCartItems
                                .where((i) => i['category'] == category)
                                .length,
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 100), // Spacing for fab
              ],
            ),
          ),
          if (_currentCartItems.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Center(
                child: ElevatedButton(
                  onPressed: _navigateToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A22A8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 4,
                    shadowColor: Colors.black26,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_basket_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'View Basket (${_currentCartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))})',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _buildCategoryCard(
      {required String image, required String label, int itemsInCart = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppImage(
                imageSource: image,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: Shimmer(
                  duration: const Duration(seconds: 1),
                  color: Colors.grey.shade300,
                  child: Container(color: Colors.grey.shade200),
                ),
                fallback: const Center(
                    child: Icon(Icons.fastfood, color: Colors.grey)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// --- NEW CLASS FOR CATEGORY PRODUCTS VIEW ---
class CategoryProductsPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String category;
  final Function(Map<String, dynamic>) onAddToCart;
  final List<Map<String, dynamic>> initialCartItems;

  const CategoryProductsPage({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
    required this.category,
    required this.onAddToCart,
    this.initialCartItems = const [],
  }) : super(key: key);

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSubFilter = 'All';
  List<String> _subCategories = ['All'];

  bool _isLoading = true;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _currentCartItems = [];

  @override
  void initState() {
    super.initState();
    // Use the reference directly so it stays in sync across the app
    _currentCartItems = widget.initialCartItems;
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products_sl')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('category', isEqualTo: widget.category)
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'imageUrl': resolveImageSource(data),
        };
      }).toList();
      final subs = products
          .map((p) => p['subCategory']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          _allProducts = products;
          _subCategories = ['All', ...subs];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching category products: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.category,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            Text(widget.restaurantName,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: () {
              final String text =
                  'Check out ${widget.restaurantName} on Nico Mart! Category: ${widget.category}. Download Nico Mart now!';
              Share.share(text);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search in ${widget.category}',
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF4A22A8)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              // Subcategory Chips
              if (_subCategories.length > 1)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _subCategories.length,
                    itemBuilder: (context, index) {
                      final sub = _subCategories[index];
                      final isSelected = _selectedSubFilter == sub;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(sub),
                          selected: isSelected,
                          onSelected: (selected) =>
                              setState(() => _selectedSubFilter = sub),
                          showCheckmark: false,
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF4A22A8),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4A22A8),
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF4A22A8)
                                : const Color(0xFFD8CFF0),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),

              // Product List
              Expanded(
                child: _isLoading
                    ? const Center(child: SmallWaveLoader(size: 20))
                    : _buildProductList(),
              ),
            ],
          ),
          if (_currentCartItems.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Center(
                child: ElevatedButton(
                  onPressed: _navigateToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A22A8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 4,
                    shadowColor: Colors.black26,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_basket_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'View Basket (${_currentCartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int))})',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _buildProductList() {
    final filtered = _allProducts.where((p) {
      final matchesSearch =
          p['name']?.toString().toLowerCase().contains(_searchQuery) ?? true;
      final matchesSub =
          _selectedSubFilter == 'All' || p['subCategory'] == _selectedSubFilter;
      return matchesSearch && matchesSub;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
          child:
              Text('No products found', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
        final String prodId = product['id']?.toString() ?? '';
        final cartItem = _currentCartItems.firstWhere(
          (i) => i['id']?.toString() == prodId,
          orElse: () => <String, dynamic>{},
        );
        final cartQty =
            cartItem.isNotEmpty ? (cartItem['quantity'] as num).toInt() : 0;

        return _ProductListItem(
          key: ValueKey(prodId),
          product: product,
          cartQty: cartQty,
          onAddToCart: (p) {
            print(
                "📦 CategoryProductsPage relaying item to detail page: ${p['name']}");
            widget.onAddToCart(p);
            if (!mounted) return;
            setState(() {
              // Rebuild to reflect parent's list state
            });
          },
        );
      },
    );
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(
          cartItems: _currentCartItems,
          onRemoveFromCart: (index) =>
              setState(() => _currentCartItems.removeAt(index)),
          onUpdateCartItem: (index, item) =>
              setState(() => _currentCartItems[index] = item),
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

// Reuse the style of _FoodListItem for consistency
class _ProductListItem extends StatefulWidget {
  final Map<String, dynamic> product;
  final int cartQty;
  final Function(Map<String, dynamic>) onAddToCart;

  const _ProductListItem({
    Key? key,
    required this.product,
    required this.cartQty,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<_ProductListItem> createState() => _ProductListItemState();
}

class _ProductListItemState extends State<_ProductListItem> {
  late int _localQty;

  @override
  void initState() {
    super.initState();
    _localQty = widget.cartQty;
  }

  @override
  void didUpdateWidget(_ProductListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cartQty != oldWidget.cartQty) {
      setState(() {
        _localQty = widget.cartQty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.product['name']?.toString() ?? 'Item';
    final price = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = resolveImageSource(widget.product);
    final uom = widget.product['uom']?.toString() ?? 'piece';

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
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openDetail,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(
                      imageSource: imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      fallback: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.fastfood,
                            size: 24, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black87),
                            maxLines: 1),
                        const SizedBox(height: 4),
                        Text('Rs.${price.toStringAsFixed(2)} / $uom',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF4A22A8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildCounterControl(price, uom),
        ],
      ),
    );
  }

  Widget _buildCounterControl(double price, String uom) {
    if (_localQty <= 0) {
      return GestureDetector(
        onTap: () {
          print("🟢 PLUS INITIAL: Handling click locally first");
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
              print("🔴 TRASH CLICK: Handling locally");
              setState(() => _localQty = 0);
              _updateCart(-1, price, uom);
            }, color: Colors.red.shade500)
          else
            _qtyBtn(Icons.remove, () {
              print("➖ MINUS CLICK: Handling locally");
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
            print("➕ PLUS CLICK: Handling locally");
            setState(() => _localQty++);
            _updateCart(1, price, uom);
          }),
        ],
      ),
    );
  }

  void _openDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailPage(
          product: widget.product,
          onAddToCart: widget.onAddToCart,
        ),
      ),
    );
  }

  void _updateCart(int delta, double price, String uom) {
    // Apply any admin-set discount so the cart subtotal uses the discounted
    // unit price (same rules as FoodDetailPage).
    double unitPrice = price;
    if (widget.product['discountType'] == 'fixed') {
      unitPrice = (widget.product['fixedPrice'] as num?)?.toDouble() ?? price;
    } else if (widget.product['discountType'] == 'normal') {
      final disc = (widget.product['discount'] as num?)?.toDouble() ?? 0.0;
      unitPrice = price * (1 - disc / 100);
    }

    final Map<String, dynamic> itemToSend =
        Map<String, dynamic>.from(widget.product);
    itemToSend['quantity'] = delta;
    itemToSend['selectedUnit'] = uom;
    itemToSend['finalPrice'] = unitPrice * delta;
    itemToSend['unitPrice'] = unitPrice;

    widget.onAddToCart(itemToSend);
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
