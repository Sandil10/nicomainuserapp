import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Singleton dialog flag to prevent multiple popups
bool _appliedDialogIsOpen = false;

// Custom scroll behavior to remove splash effects
class NoSplashScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

// ✨ REVAMPED & INSTANT DIALOG ✨
void showAppliedDialog(BuildContext context,
    {required String title, required String message}) {
  if (_appliedDialogIsOpen) return;
  _appliedDialogIsOpen = true;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 150),
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, anim1, anim2) {
      return Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8DFFF), Color(0xFFF4F0FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4A22A8), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child:
                      const Text("Done", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).then((_) {
    _appliedDialogIsOpen = false;
  });
}

class AdsBannerWidget extends StatefulWidget {
  final double? height;

  const AdsBannerWidget({Key? key, this.height}) : super(key: key);

  @override
  State<AdsBannerWidget> createState() => _AdsBannerWidgetState();
}

class _AdsBannerWidgetState extends State<AdsBannerWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final PageController _pageController;
  static const double DEFAULT_HEIGHT = 160.0;
  double get bannerHeight => widget.height ?? DEFAULT_HEIGHT;

  // ✅ Cache key for SharedPreferences
  static const String CACHE_KEY = 'ads_banner_cache';
  static const String CACHE_TIMESTAMP_KEY = 'ads_banner_cache_timestamp';
  static const Duration CACHE_DURATION = Duration(hours: 1);

  List<Map<String, dynamic>> _activeAds = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoadingFromCache = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _streamSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    print('🎯 AdsBannerWidget: initState called');
    _initializeAds();
  }

  @override
  void dispose() {
    print('🎯 AdsBannerWidget: dispose called');
    _isDisposed = true;
    _streamSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeAds() async {
    if (_isDisposed) return;

    print('🎯 AdsBannerWidget: Initializing ads...');

    try {
      if (!mounted) {
        print('⚠️ AdsBannerWidget: Widget not mounted');
        return;
      }

      // ✅ Step 1: Try loading from cache first
      await _loadFromCache();

      // ✅ Step 2: Setup Firestore stream for fresh data
      await _setupStream();
    } catch (e) {
      print('❌ AdsBannerWidget: Error in _initializeAds: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
          _isLoadingFromCache = false;
        });
        print('✅ AdsBannerWidget: Loading complete');
      }
    }
  }

  // ✅ Load ads from cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(CACHE_KEY);
      final cacheTimestamp = prefs.getInt(CACHE_TIMESTAMP_KEY);

      if (cachedData != null && cacheTimestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;

        if (cacheAge < CACHE_DURATION.inMilliseconds) {
          print(
              '✅ AdsBannerWidget: Loading ads from cache (age: ${Duration(milliseconds: cacheAge).inMinutes} minutes)');

          final List<dynamic> decodedData = jsonDecode(cachedData);
          final cachedAds = decodedData
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          if (mounted && !_isDisposed) {
            setState(() {
              _activeAds = cachedAds;
              _isLoadingFromCache = false;
            });
            print(
                '✅ AdsBannerWidget: Loaded ${cachedAds.length} ads from cache');
          }
          return;
        } else {
          print(
              '⚠️ AdsBannerWidget: Cache expired (age: ${Duration(milliseconds: cacheAge).inHours} hours)');
        }
      } else {
        print('⚠️ AdsBannerWidget: No cache found');
      }
    } catch (e) {
      print('❌ AdsBannerWidget: Error loading from cache: $e');
    }

    if (mounted && !_isDisposed) {
      setState(() => _isLoadingFromCache = false);
    }
  }

  // ✅ Save ads to cache
  Future<void> _saveToCache(List<Map<String, dynamic>> ads) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cacheableAds = ads.map((ad) {
        final Map<String, dynamic> cacheAd = Map.from(ad);

        if (cacheAd['startDate'] is Timestamp) {
          cacheAd['startDate'] =
              (cacheAd['startDate'] as Timestamp).millisecondsSinceEpoch;
        }
        if (cacheAd['endDate'] is Timestamp) {
          cacheAd['endDate'] =
              (cacheAd['endDate'] as Timestamp).millisecondsSinceEpoch;
        }
        if (cacheAd['createdAt'] is Timestamp) {
          cacheAd['createdAt'] =
              (cacheAd['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }

        return cacheAd;
      }).toList();

      await prefs.setString(CACHE_KEY, jsonEncode(cacheableAds));
      await prefs.setInt(
          CACHE_TIMESTAMP_KEY, DateTime.now().millisecondsSinceEpoch);

      print('✅ AdsBannerWidget: Saved ${ads.length} ads to cache');
    } catch (e) {
      print('❌ AdsBannerWidget: Error saving to cache: $e');
    }
  }

  Future<void> _setupStream() async {
    if (_isDisposed || !mounted) return;

    print('🎯 AdsBannerWidget: Setting up Firestore stream...');

    await _streamSubscription?.cancel();

    try {
      final stream = _firestore
          .collection('ads_sl')
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) =>
                snapshot.data() ?? <String, dynamic>{},
            toFirestore: (value, _) => value,
          )
          .where('isActive', isEqualTo: true)
          .snapshots();

      print('✅ AdsBannerWidget: Stream created successfully');

      _streamSubscription = stream.listen(
        _handleStreamData,
        onError: _handleError,
        cancelOnError: false,
      );
    } catch (e) {
      print('❌ AdsBannerWidget: Error setting up stream: $e');
      rethrow;
    }
  }

  void _handleStreamData(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (_isDisposed || !mounted) return;

    print(
        '📦 AdsBannerWidget: Received ${snapshot.docs.length} documents from Firestore');

    final now = DateTime.now();

    final ads = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).where((data) {
      final startDate = (data['startDate'] as Timestamp?)?.toDate();
      final endDate = (data['endDate'] as Timestamp?)?.toDate();

      if (startDate != null && endDate != null) {
        return now.isAfter(startDate) && now.isBefore(endDate);
      }
      return true;
    }).toList();

    ads.sort((a, b) {
      final priorityA = a['priority'] as int? ?? 999;
      final priorityB = b['priority'] as int? ?? 999;
      return priorityA.compareTo(priorityB);
    });

    setState(() {
      _activeAds = ads;
      _hasError = false;
      _errorMessage = '';
    });

    print('✅ AdsBannerWidget: State updated with ${_activeAds.length} ads');

    _saveToCache(ads);

    if (ads.isNotEmpty) {
      _trackImpressions(snapshot.docs.where((doc) {
        return ads.any((ad) => ad['id'] == doc.id);
      }).toList());
    }
  }

  void _handleError(dynamic error) {
    print('❌ AdsBannerWidget: Stream error: $error');

    if (_isDisposed || !mounted) return;
    if (error is FirebaseException &&
        error.code == 'permission-denied' &&
        _activeAds.isNotEmpty) {
      return;
    }

    setState(() {
      _hasError = true;
      _errorMessage = error.toString();
    });
  }

  final Set<String> _impressionTracked = {};

  void _trackImpressions(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty || _isDisposed) return;

    final batch = _firestore.batch();
    bool hasUpdates = false;

    for (var doc in docs) {
      if (!_impressionTracked.contains(doc.id)) {
        _impressionTracked.add(doc.id);
        batch.update(doc.reference, {'impressions': FieldValue.increment(1)});
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      batch.commit().catchError((e) {
        print('❌ AdsBannerWidget: Error tracking impressions: $e');
      });
    }
  }

  void _onAdTap(Map<String, dynamic> adData) {
    print('👆 AdsBannerWidget: Ad tapped - ${adData['title']}');

    showAppliedDialog(
      context,
      title: adData['title'] ?? "Offer Details",
      message: adData['description'] ??
          "This special offer has been successfully applied to your account.",
    );

    if (adData['id'] != null) {
      _firestore.collection('ads_sl').doc(adData['id']).update({
        'clicks': FieldValue.increment(1),
      }).catchError((e) {
        print('❌ AdsBannerWidget: Error updating ad clicks: $e');
      });
    }
  }

  Widget _buildAdCard(Map<String, dynamic> ad, double pageOffset) {
    final scale = 1.0 - (pageOffset.abs() * 0.15);

    return Transform.scale(
      scale: scale.clamp(0.85, 1.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: GestureDetector(
          onTap: () => _onAdTap(ad),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildAdBackground(ad),
          ),
        ),
      ),
    );
  }

  Widget _buildAdBackground(Map<String, dynamic> ad) {
    if (ad['startDate'] is int) {
      ad['startDate'] = Timestamp.fromMillisecondsSinceEpoch(ad['startDate']);
    }
    if (ad['endDate'] is int) {
      ad['endDate'] = Timestamp.fromMillisecondsSinceEpoch(ad['endDate']);
    }

    if (ad['imageUrl'] != null && (ad['imageUrl'] as String).isNotEmpty) {
      return _NetworkAdImage(imageUrl: ad['imageUrl'] as String);
    }

    if (ad['imageBase64'] != null && (ad['imageBase64'] as String).isNotEmpty) {
      return _FadeInAdImage(imageBase64: ad['imageBase64'] as String);
    }

    return _buildFallbackGradient(ad);
  }

  Widget _buildFallbackGradient(Map<String, dynamic> ad) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                ad['title'] ?? 'Special Offer',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                ad['description'] ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    if (_activeAds.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Center(
        child: SmoothPageIndicator(
          controller: _pageController,
          count: _activeAds.length,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Color(0xFF5B35B8),
            dotColor: Colors.grey.shade300,
            spacing: 10,
          ),
        ),
      ),
    );
  }

  // ✅ Built-in shimmer loading state
  Widget _buildLoadingState() {
    return Container(
      height: bannerHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: _ShimmerAnimation(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: bannerHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.red.shade600, size: 28),
              const SizedBox(height: 6),
              Text(
                'Cannot Load Offers',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage.length > 50 ? 'Connection error' : _errorMessage,
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                    _initializeAds();
                  },
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: bannerHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined,
                color: Colors.grey.shade500, size: 32),
            const SizedBox(height: 8),
            Text(
              'No Active Offers',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back later for new deals',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _activeAds.isEmpty) return _buildLoadingState();
    if (_hasError && _activeAds.isEmpty) return _buildErrorState();
    if (_activeAds.isEmpty) return _buildEmptyState();

    return Column(
      children: [
        SizedBox(
          height: bannerHeight,
          child: ScrollConfiguration(
            behavior: NoSplashScrollBehavior(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _activeAds.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double pageOffset = 0;
                    if (_pageController.position.haveDimensions) {
                      pageOffset = (_pageController.page ?? 0) - index;
                    }
                    return _buildAdCard(_activeAds[index], pageOffset);
                  },
                );
              },
            ),
          ),
        ),
        _buildPageIndicator(),
      ],
    );
  }
}

// ✅ Custom built-in shimmer animation widget
class _ShimmerAnimation extends StatefulWidget {
  final Widget child;

  const _ShimmerAnimation({required this.child});

  @override
  __ShimmerAnimationState createState() => __ShimmerAnimationState();
}

class __ShimmerAnimationState extends State<_ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFEBEBF4),
                Color(0xFFF4F4F4),
                Color(0xFFEBEBF4),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// ✨ Network Image Widget
class _NetworkAdImage extends StatefulWidget {
  final String imageUrl;

  const _NetworkAdImage({required this.imageUrl});

  @override
  __NetworkAdImageState createState() => __NetworkAdImageState();
}

class __NetworkAdImageState extends State<_NetworkAdImage> {
  bool _isImageReady = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF66BB6A)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
        ),
        Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              if (!_isImageReady) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _isImageReady = true);
                });
              }
              return AnimatedOpacity(
                opacity: _isImageReady ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: child,
              );
            }
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.7)),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2E7D32),
                    Color(0xFF4CAF50),
                    Color(0xFF66BB6A)
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ✨ Base64 Image Widget
class _FadeInAdImage extends StatefulWidget {
  final String imageBase64;

  const _FadeInAdImage({required this.imageBase64});

  @override
  __FadeInAdImageState createState() => __FadeInAdImageState();
}

class __FadeInAdImageState extends State<_FadeInAdImage> {
  bool _isImageReady = false;
  MemoryImage? _imageProvider;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _FadeInAdImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageBase64 != oldWidget.imageBase64) {
      setState(() {
        _isImageReady = false;
        _hasError = false;
      });
      _loadImage();
    }
  }

  void _loadImage() {
    try {
      final pureBase64 = widget.imageBase64.contains(',')
          ? widget.imageBase64.split(',').last
          : widget.imageBase64;

      _imageProvider = MemoryImage(base64Decode(pureBase64));

      _imageProvider!.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener(
              (ImageInfo info, bool synchronousCall) {
                if (mounted) {
                  setState(() => _isImageReady = true);
                }
              },
              onError: (exception, stackTrace) {
                if (mounted) {
                  setState(() => _hasError = true);
                }
              },
            ),
          );
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _imageProvider == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF66BB6A)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      opacity: _isImageReady ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
      child: Image(
        image: _imageProvider!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2E7D32),
                  Color(0xFF4CAF50),
                  Color(0xFF66BB6A)
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          );
        },
      ),
    );
  }
}
