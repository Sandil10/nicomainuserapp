import 'package:flutter/material.dart';
import './water_bottles_page.dart';
import './groceries_page.dart';
import './ads_banner_widget.dart';
import './profile_settings.dart';
import 'auth_service.dart';
import 'social_login_screen.dart';
import 'auth_wrapper.dart';
import './fashion.dart';
import './school_item.dart';
import './food_page.dart';
import './italy_items_page.dart';
import './app_localization.dart';
import './shop_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import './widgets/small_wave_loader.dart';
import './models/restaurant_model.dart';
import './restaurant_card_widget.dart';

class UserPanelProducts extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  final VoidCallback onTestFirebase;
  final int cartItemCount;
  final List<Map<String, dynamic>> cartItems;

  const UserPanelProducts({
    Key? key,
    required this.onAddToCart,
    required this.onTestFirebase,
    this.cartItemCount = 0,
    this.cartItems = const [],
  }) : super(key: key);

  @override
  State<UserPanelProducts> createState() => _UserPanelProductsState();
}

class _UserPanelProductsState extends State<UserPanelProducts> {
  final TextEditingController _searchController = TextEditingController();
  String _userName = 'Guest';
  String _userEmail = '';
  bool _isInitialized = false;

  List<Restaurant> _restaurants = [];
  bool _isLoadingRestaurants = true;
  String _selectedCategory = 'All';
  String _sortBy = 'Popularity'; // 'Popularity' or 'Rating'

  @override
  void initState() {
    super.initState();
    _initializeComponent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeComponent() async {
    print('🔄 UserPanelProducts initializing...');

    // Ensure AppLocalization is initialized
    await AppLocalization.initialize();

    print('📱 Current language after init: ${AppLocalization.languageCode}');

    _loadUserInfo();
    _fetchRestaurants();

    setState(() {
      _isInitialized = true;
    });

    print('✅ UserPanelProducts initialized');
  }

  void _loadUserInfo() {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      if (currentUser.isAnonymous) {
        setState(() {
          _userName = 'Guest';
          _userEmail = '';
        });
      } else {
        setState(() {
          _userName = currentUser.displayName ??
              _extractNameFromEmail(currentUser.email ?? '') ??
              'User';
          _userEmail = currentUser.email ?? '';
        });
      }
    } else {
      setState(() {
        _userName = 'Guest';
        _userEmail = '';
      });
    }
  }

  Future<void> _fetchRestaurants() async {
    try {
      // 1. Try common 'restaurants' (lowercase)
      final snapshot =
          await FirebaseFirestore.instance.collection('restaurants').get();

      if (snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _restaurants = snapshot.docs
                .map((doc) => Restaurant.fromFirestore(doc))
                .toList();
            _isLoadingRestaurants = false;
          });
        }
        return;
      }

      // 2. Try 'Restaurants' (Capital R)
      final upperSnapshot =
          await FirebaseFirestore.instance.collection('Restaurants').get();
      if (upperSnapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _restaurants = upperSnapshot.docs
                .map((doc) => Restaurant.fromFirestore(doc))
                .toList();
            _isLoadingRestaurants = false;
          });
        }
        return;
      }

      // 3. Try the specific typo 'returants' as mentioned in the user request
      final typoSnapshot =
          await FirebaseFirestore.instance.collection('returants').get();
      if (typoSnapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _restaurants = typoSnapshot.docs
                .map((doc) => Restaurant.fromFirestore(doc))
                .toList();
            _isLoadingRestaurants = false;
          });
        }
        return;
      }

      // If nothing found in any collection
      if (mounted) {
        setState(() {
          _restaurants = [];
          _isLoadingRestaurants = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching restaurants: $e');
      if (mounted) {
        setState(() {
          _isLoadingRestaurants = false;
        });
      }
    }
  }

  String? _extractNameFromEmail(String email) {
    if (email.isEmpty) return null;
    final namePart = email.split('@').first;
    if (namePart.isNotEmpty) {
      return namePart
          .replaceAll(RegExp(r'[._]'), ' ')
          .split(' ')
          .map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '')
          .join(' ');
    }
    return null;
  }

  String _getCurrentGreeting() {
    final hour = DateTime.now().hour;
    String key;
    if (hour < 12) {
      key = 'goodMorning';
    } else if (hour < 17) {
      key = 'goodAfternoon';
    } else if (hour < 20) {
      key = 'goodEvening';
    } else {
      key = 'goodNight';
    }

    final result = AppLocalization.getText(key);
    return result;
  }

  String _getDisplayName() {
    if (_userName == 'Guest') {
      return AppLocalization.getText('guest');
    } else if (_userName == 'User') {
      return AppLocalization.getText('user');
    }
    return _userName;
  }

  // Navigation methods
  void _navigateToItalyItems() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItalyItemsPage(
          onAddToCart: widget.onAddToCart,
          cartItems: widget.cartItems, // Pass actual reference
        ),
      ),
    );
  }

  void _navigateToGroceries() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroceriesPage(
          onAddToCart: widget.onAddToCart,
          cartItems: widget.cartItems, // Pass actual reference
        ),
      ),
    );
  }

  void _navigateToShop(Map<String, dynamic> shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailPage(
          shopData: shop,
          onAddToCart: widget.onAddToCart,
          initialCartItems: widget.cartItems, // Use direct reference
        ),
      ),
    );
  }

  void _showUserProfileOptions(BuildContext scaffoldContext) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return ValueListenableBuilder<String>(
          valueListenable: AppLocalization.currentLanguage,
          builder: (context, languageCode, child) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            const Color(0xFF4A22A8).withOpacity(0.1),
                        child: Text(
                          _getDisplayName().isNotEmpty
                              ? _getDisplayName()[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A22A8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDisplayName(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (_userEmail.isNotEmpty)
                              Text(
                                _userEmail,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(modalContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileSettings(
                              userData: null,
                              onSuccess: (message) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(AppLocalization.getText(
                                            'profileUpdatedSuccess')),
                                        backgroundColor: Color(0xFF4A22A8)),
                                  );
                                  _loadUserInfo();
                                }
                              },
                              onError: (message) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(AppLocalization.getText(
                                            'profileUpdateError')),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A22A8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.person_outline),
                      label: Text(
                        AppLocalization.getText('viewProfile'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Method to show Google Sign-in success message
  void showGoogleSignInSuccess() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalization.getText('googleSignInSuccess'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF4A22A8),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalization.getText('signOutTitle')),
          content: Text(AppLocalization.getText('signOutConfirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalization.getText('cancel'),
                  style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AuthService.signOut().then((_) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SocialLoginScreen()),
                    (route) => false,
                  );
                });
              },
              child: Text(AppLocalization.getText('signOut'),
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(
          child: SmallWaveLoader(size: 16),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return ValueListenableBuilder<String>(
            valueListenable: AppLocalization.currentLanguage,
            builder: (context, languageCode, child) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4A22A8), Color(0xFF8E6AE8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: AppLocalization.getText(
                                                  'hiGreeting'),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            TextSpan(
                                              text: _getDisplayName(),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getCurrentGreeting(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showUserProfileOptions(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.white,
                                          child: Text(
                                            _getDisplayName().isNotEmpty
                                                ? _getDisplayName()[0]
                                                    .toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4A22A8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.keyboard_arrow_down,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Search Bar
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Search for restaurants or food...',
                                  hintStyle: TextStyle(
                                      color: Colors.grey.withOpacity(0.7),
                                      fontSize: 14),
                                  prefixIcon: const Icon(Icons.search,
                                      color: Color(0xFF4A22A8)),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const AdsBannerWidget(),
                    const SizedBox(height: 24),

                    // Features on Nico Mart Section (Shops)
                    _buildFeaturesSection(),

                    const SizedBox(height: 24),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Restaurants',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward,
                      color: Color(0xFF4A22A8), size: 18),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                width: 30,
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A22A8),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoadingRestaurants)
          SizedBox(
            height: 240, // Smaller height
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Shimmer(
                duration: const Duration(seconds: 1),
                color: Colors.grey.shade300,
                child: Container(
                  width: 200, // Smaller width
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          )
        else if (_restaurants.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu, size: 40, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No restaurants found',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 260, // Smaller height
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 24, right: 8),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = _restaurants[index];
                return ModernRestaurantCard(
                  restaurant: restaurant,
                  onTap: () {
                    _navigateToShop({
                      'id': restaurant.id,
                      'name': restaurant.name,
                      'rating': restaurant.rating.toString(),
                      'cuisine': restaurant.category,
                      'imageUrl': restaurant.imageUrl,
                      'openUntil': restaurant.closingTime,
                      'priceLevel': restaurant.priceLevel,
                      'deliveryFee': restaurant.deliveryFee,
                      'deliveryTime': restaurant.deliveryTime,
                      'pickupTime': restaurant.pickupTime,
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryFilterRow() {
    final categories = [
      'All',
      'Sri Lankan',
      'Chinese',
      'Indian',
      'Italian',
      'Fine Dining'
    ];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: const Color(0xFF4A22A8),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
              elevation: 0,
              pressElevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  // Removed redundant _buildRestaurantCard as we now use ModernRestaurantCard

  List<Restaurant> get _filteredRestaurants {
    List<Restaurant> filtered = _restaurants.where((restaurant) {
      final matchesSearch = _searchController.text.isEmpty ||
          restaurant.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          restaurant.category
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());

      // Removed category filtering logic as per user request to fetch all restaurants
      return matchesSearch;
    }).toList();

    if (_sortBy == 'Rating') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      // For Popularity, we can use createdAt or just default
      filtered.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
    }

    return filtered;
  }

  void _shareShop(Map<String, dynamic> shop) {
    final String text =
        'Check out ${shop['name']} on Nico Mart! serving ${shop['cuisine']} food. Rating: ${shop['rating']} ⭐\nDownload Nico Mart now!';
    Share.share(text);
  }
}
