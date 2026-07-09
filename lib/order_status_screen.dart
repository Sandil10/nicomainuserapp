import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'user_panel.dart';
import 'orders_payments.dart';
import 'help.dart';

class OrderStatusScreen extends StatefulWidget {
  final String orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with SingleTickerProviderStateMixin {
  static const Set<String> _liveTrackingStatuses = {
    'finding_rider',
    'picked_up',
    'on_the_way',
  };

  LatLng _deliveryLatLng = const LatLng(6.9271, 79.8612); // Default
  String _currentStatus = 'processing';
  String _rejectionReason = '';
  bool _canCancel = true;

  // Drives the "play forward and backward" pulse on the active segment.
  // Initialized in initState (vsync needs the State); declared late.
  AnimationController? _pulseController;

  GoogleMapController? _mapController;

  // Google Directions API key (same project key used for Maps).
  static const String _mapsApiKey = 'AIzaSyBedirf6s8EnSButbonv6EWzAq7tqjmYns';

  // Fallback restaurant pickup point used until a real restaurant location
  // becomes available in the order payload.
  late LatLng _restaurantLatLng;
  LatLng? _riderLatLng;
  double _riderBearing = 0; // bike icon rotation (degrees)
  List<LatLng> _routePoints = [];
  final List<LatLng> _riderTrail = [];
  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteFetchAt;
  bool _usingLiveRiderFeed = false;
  bool _navigatedAway = false;
  bool _handledDeliveredState = false;
  BitmapDescriptor? _bikeIcon;
  Map<String, dynamic>? _assignedRider;

  // Shows the delivered success animation overlay before navigating away.
  bool _showDeliveredOverlay = false;

  // --- Demo rider animation (visual only, never written to Firestore) -------
  // When a rider is assigned but no real GPS feed exists, we animate a demo
  // rider: ~1km away -> restaurant (pickup) -> user location (delivered),
  // compressed into ~5 minutes. A real riderLocation feed cancels the demo.
  static const Duration _demoTotal = Duration(minutes: 5);
  static const Duration _demoTick = Duration(milliseconds: 120);
  Timer? _demoTimer;
  bool _demoRunning = false;
  double _demoProgress = 0; // 0..1 across the whole leg sequence
  List<LatLng> _demoLegToRestaurant = [];
  List<LatLng> _demoLegToCustomer = [];
  // Local status shown during the demo, overrides the Firestore status label.
  String? _demoStatus;
  bool _demoDelivered = false;

  @override
  void initState() {
    super.initState();
    // Placeholder until restaurant coordinates are stored with the order.
    _restaurantLatLng = LatLng(
        _deliveryLatLng.latitude + 0.011, _deliveryLatLng.longitude + 0.011);
    // Forward-and-backward pulse for the active progress segment.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _loadBikeIcon();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _pulseController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadBikeIcon() async {
    // Draw a black bike/scooter marker in code (no asset needed) so it always
    // renders and looks like the reference. Falls back to a pin on failure.
    BitmapDescriptor icon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    try {
      icon = await _drawBikeMarker();
    } catch (_) {
      // keep the fallback pin
    }
    if (mounted) setState(() => _bikeIcon = icon);
  }

  // Paints a glossy black bike badge with a soft shadow so the rider marker
  // feels closer to a 3D app icon than a flat pin.
  Future<BitmapDescriptor> _drawBikeMarker() async {
    const size = 118.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = const Offset(size / 2, size / 2);
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 84, height: 84),
      const Radius.circular(28),
    );

    canvas.drawShadow(
      Path()..addRRect(badgeRect),
      Colors.black.withValues(alpha: 0.45),
      14,
      true,
    );

    canvas.drawRRect(
      badgeRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center.dx - 28, center.dy - 28),
          Offset(center.dx + 32, center.dy + 32),
          const [
            Color(0xFF4E4E4E),
            Color(0xFF0B0B0B),
          ],
        ),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - 8, center.dy - 14),
          width: 54,
          height: 20,
        ),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: String.fromCharCode(Icons.directions_bike.codePoint),
      style: TextStyle(
        fontSize: 50,
        fontFamily: Icons.directions_bike.fontFamily,
        package: Icons.directions_bike.fontPackage,
        color: Colors.white,
      ),
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 + 2),
    );

    final img =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // Zoom the camera so the entire route is visible (like Uber's overview).
  Future<void> _fitRouteBounds(List<LatLng> pts) async {
    if (_mapController == null || pts.isEmpty) return;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await _mapController!
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  // Call Google Directions API and decode the polyline into road points.
  // On web the browser blocks the API with CORS, so we route the request
  // through a public CORS proxy. If everything fails we fall back to a
  // smooth curved path (not a flat straight line) so it still looks like a
  // real route.
  Future<List<LatLng>> _fetchRoute(LatLng origin, LatLng dest) async {
    final directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${dest.latitude},${dest.longitude}'
        '&mode=driving&key=$_mapsApiKey';

    // On web, prefix a CORS proxy; on mobile call Google directly.
    final url = kIsWeb
        ? 'https://corsproxy.io/?${Uri.encodeComponent(directionsUrl)}'
        : directionsUrl;

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final encoded =
              data['routes'][0]['overview_polyline']['points'] as String;
          final pts = _decodePolyline(encoded);
          if (pts.length >= 2) return pts;
        }
      }
    } catch (_) {
      // fall through to the curved fallback
    }
    // Fallback: a gently curved multi-point path so movement looks natural
    // even when the Directions API is unavailable.
    return _curvedFallback(origin, dest);
  }

  // Builds a smooth curved path between two points (quadratic bezier with a
  // perpendicular offset), so the rider doesn't travel a flat diagonal line.
  List<LatLng> _curvedFallback(LatLng a, LatLng b) {
    const steps = 24;
    final mx = (a.latitude + b.latitude) / 2;
    final my = (a.longitude + b.longitude) / 2;
    // Perpendicular offset for the control point (gives the arc its bend).
    final dx = b.latitude - a.latitude;
    final dy = b.longitude - a.longitude;
    final cx = mx - dy * 0.18;
    final cy = my + dx * 0.18;
    final pts = <LatLng>[];
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = math.pow(1 - t, 2) * a.latitude +
          2 * (1 - t) * t * cx +
          math.pow(t, 2) * b.latitude;
      final lng = math.pow(1 - t, 2) * a.longitude +
          2 * (1 - t) * t * cy +
          math.pow(t, 2) * b.longitude;
      pts.add(LatLng(lat.toDouble(), lng.toDouble()));
    }
    return pts;
  }

  // Standard Google encoded-polyline decoder.
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // Bearing (heading) between two points so the bike icon faces forward.
  double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  Future<void> _refreshRouteFromRider(LatLng origin) async {
    if (!_shouldRefreshRoute(origin)) return;

    final points = await _fetchRoute(origin, _deliveryLatLng);
    if (!mounted) return;

    setState(() {
      _routePoints = points;
      _lastRouteOrigin = origin;
      _lastRouteFetchAt = DateTime.now();
    });
    if (points.isNotEmpty) {
      unawaited(_fitRouteBounds(points));
    }
  }

  bool _shouldRefreshRoute(LatLng origin) {
    if (_lastRouteOrigin == null || _lastRouteFetchAt == null) {
      return true;
    }

    if (DateTime.now().difference(_lastRouteFetchAt!).inSeconds >= 20) {
      return true;
    }

    return _distanceBetween(_lastRouteOrigin!, origin) >= 25;
  }

  void _applyLiveRiderLocation(Map<String, dynamic> locationData) {
    final lat = _toDouble(locationData['latitude']);
    final lng = _toDouble(locationData['longitude']);
    if (lat == null || lng == null) return;

    final nextPosition = LatLng(lat, lng);
    final nextBearing = _toDouble(locationData['bearing']) ??
        (_riderLatLng == null ? 0 : _bearing(_riderLatLng!, nextPosition));

    if (_riderLatLng != null &&
        _distanceBetween(_riderLatLng!, nextPosition) < 2) {
      _riderBearing = nextBearing;
      _usingLiveRiderFeed = true;
      return;
    }

    if (_riderLatLng == null) {
      _riderTrail
        ..clear()
        ..add(nextPosition);
    } else {
      _riderTrail.add(nextPosition);
      if (_riderTrail.length > 80) {
        _riderTrail.removeAt(0);
      }
    }

    _riderLatLng = nextPosition;
    _riderBearing = nextBearing;
    _usingLiveRiderFeed = true;
    unawaited(_refreshRouteFromRider(nextPosition));
  }

  void _resetLiveTrackingVisuals() {
    _riderLatLng = null;
    _riderBearing = 0;
    _routePoints = [];
    _riderTrail.clear();
    _lastRouteOrigin = null;
    _lastRouteFetchAt = null;
    _usingLiveRiderFeed = false;
  }

  // --- Demo rider animation --------------------------------------------------

  /// Returns a point [distanceMeters] away from [origin] at [bearingDeg].
  LatLng _offsetPoint(LatLng origin, double distanceMeters, double bearingDeg) {
    const earthRadius = 6371000.0;
    final bearing = bearingDeg * math.pi / 180.0;
    final lat1 = origin.latitude * math.pi / 180.0;
    final lng1 = origin.longitude * math.pi / 180.0;
    final angular = distanceMeters / earthRadius;

    final lat2 = math.asin(math.sin(lat1) * math.cos(angular) +
        math.cos(lat1) * math.sin(angular) * math.cos(bearing));
    final lng2 = lng1 +
        math.atan2(
          math.sin(bearing) * math.sin(angular) * math.cos(lat1),
          math.cos(angular) - math.sin(lat1) * math.sin(lat2),
        );
    return LatLng(lat2 * 180.0 / math.pi, lng2 * 180.0 / math.pi);
  }

  /// Linear interpolation along a polyline by fraction [t] (0..1).
  LatLng _pointAlong(List<LatLng> path, double t) {
    if (path.isEmpty) return _deliveryLatLng;
    if (path.length == 1 || t <= 0) return path.first;
    if (t >= 1) return path.last;
    // Cumulative segment lengths.
    final segLengths = <double>[];
    double total = 0;
    for (var i = 0; i < path.length - 1; i++) {
      final d = _distanceBetween(path[i], path[i + 1]);
      segLengths.add(d);
      total += d;
    }
    if (total == 0) return path.first;
    double target = t * total;
    for (var i = 0; i < segLengths.length; i++) {
      if (target <= segLengths[i]) {
        final f = segLengths[i] == 0 ? 0.0 : target / segLengths[i];
        return LatLng(
          path[i].latitude + (path[i + 1].latitude - path[i].latitude) * f,
          path[i].longitude + (path[i + 1].longitude - path[i].longitude) * f,
        );
      }
      target -= segLengths[i];
    }
    return path.last;
  }

  /// Kicks off the visual-only demo when a rider is assigned but no real GPS
  /// feed is present. Rider starts ~1km from the restaurant, drives there
  /// (pickup), then to the customer (delivered) over ~5 minutes.
  Future<void> _startDemoIfNeeded() async {
    if (_demoRunning || _demoDelivered || _usingLiveRiderFeed) return;
    _demoRunning = true;
    _demoStatus = 'finding_rider';

    // Start point ~1km north-west of the restaurant.
    final start = _offsetPoint(_restaurantLatLng, 1000, 315);

    // Try real road routes; fall back to straight lines so the demo always runs.
    List<LatLng> toRestaurant = await _fetchRoute(start, _restaurantLatLng);
    if (toRestaurant.length < 2) toRestaurant = [start, _restaurantLatLng];
    List<LatLng> toCustomer =
        await _fetchRoute(_restaurantLatLng, _deliveryLatLng);
    if (toCustomer.length < 2) toCustomer = [_restaurantLatLng, _deliveryLatLng];

    if (!mounted || _usingLiveRiderFeed) {
      _demoRunning = false;
      return;
    }

    setState(() {
      _demoLegToRestaurant = toRestaurant;
      _demoLegToCustomer = toCustomer;
      _demoProgress = 0;
      _riderLatLng = start;
      _routePoints = toRestaurant;
    });

    final totalTicks =
        _demoTotal.inMilliseconds ~/ _demoTick.inMilliseconds;
    var elapsedTicks = 0;

    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(_demoTick, (timer) {
      // A real GPS feed appeared — hand over to live tracking.
      if (_usingLiveRiderFeed || !mounted) {
        timer.cancel();
        _demoRunning = false;
        return;
      }
      elapsedTicks++;
      _demoProgress = (elapsedTicks / totalTicks).clamp(0.0, 1.0);
      _advanceDemo(_demoProgress);
      if (_demoProgress >= 1.0) {
        timer.cancel();
      }
    });
  }

  /// Advances the demo rider along its two legs by overall progress [p] (0..1).
  /// First half = drive to restaurant (pickup), second half = drive to customer
  /// (delivered).
  void _advanceDemo(double p) {
    LatLng next;
    LatLng prev = _riderLatLng ?? _demoLegToRestaurant.first;
    String status;
    List<LatLng> activeRoute;

    if (p < 0.5) {
      // Leg 1: toward restaurant.
      final legT = p / 0.5;
      next = _pointAlong(_demoLegToRestaurant, legT);
      status = 'finding_rider';
      activeRoute = _demoLegToRestaurant;
    } else {
      // Leg 2: restaurant -> customer.
      final legT = (p - 0.5) / 0.5;
      next = _pointAlong(_demoLegToCustomer, legT);
      status = 'on_the_way';
      activeRoute = _demoLegToCustomer;
    }

    final bearing = _bearing(prev, next);

    setState(() {
      _riderLatLng = next;
      _riderBearing = bearing;
      _routePoints = activeRoute;
      _demoStatus = status;
      _riderTrail.add(next);
      if (_riderTrail.length > 80) _riderTrail.removeAt(0);
    });

    if (p >= 1.0 && !_demoDelivered) {
      _demoDelivered = true;
      _demoStatus = 'delivered';
      // Trigger the existing delivered success overlay + navigation.
      WidgetsBinding.instance.addPostFrameCallback((_) => _onDelivered());
    }
  }

  void _stopDemo() {
    _demoTimer?.cancel();
    _demoTimer = null;
    _demoRunning = false;
    _demoStatus = null;
  }

  double _distanceBetween(LatLng a, LatLng b) {
    const earthRadiusMeters = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLng = (b.longitude - a.longitude) * math.pi / 180.0;
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadiusMeters * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  Future<void> _onDelivered() async {
    if (_handledDeliveredState) return;
    _handledDeliveredState = true;

    if (!mounted || _navigatedAway) return;
    // Show the delivered success animation, then navigate to past orders.
    setState(() => _showDeliveredOverlay = true);
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted || _navigatedAway) return;
    _navigatedAway = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
      (route) => false,
    );
  }

  // Full-screen animated "Delivered" success overlay (scale + check).
  Widget _buildDeliveredOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withValues(alpha: 0.96),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1FAE5A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 64),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Delivered!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A22A8))),
              const SizedBox(height: 6),
              Text('Enjoy your order 🎉',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('delivery'),
        position: _deliveryLatLng,
        infoWindow: const InfoWindow(title: 'Delivery location'),
      ),
    };
    if (!_usingLiveRiderFeed &&
        (_currentStatus == 'finding_rider' ||
            _currentStatus == 'on_the_way' ||
            _currentStatus == 'delivered')) {
      markers.add(Marker(
        markerId: const MarkerId('restaurant'),
        position: _restaurantLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Restaurant'),
      ));
    }
    if (_riderLatLng != null && _currentStatus != 'delivered') {
      markers.add(Marker(
        markerId: const MarkerId('rider'),
        position: _riderLatLng!,
        icon: _bikeIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        rotation: _riderBearing,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: const InfoWindow(title: 'Rider'),
      ));
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final lines = <Polyline>{};
    if (_routePoints.length >= 2) {
      lines.add(Polyline(
        polylineId: const PolylineId('route_shadow'),
        points: _routePoints,
        color: Colors.white.withValues(alpha: 0.9),
        width: 10,
        zIndex: 0,
      ));
      lines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: const Color(0xFF111111),
        width: 6,
        zIndex: 1,
      ));
    }
    if (_riderTrail.length >= 2) {
      lines.add(Polyline(
        polylineId: const PolylineId('rider_trail'),
        points: _riderTrail,
        color: const Color(0xFF000000),
        width: 7,
        zIndex: 2,
      ));
    }
    return lines;
  }

  /// Radar pulse around the restaurant while a rider is being found — ported
  /// from the Rider Tracking Map design (expanding, fading purple rings), drawn
  /// as animated map Circles so it lives inside the real map.
  Set<Circle> _buildCircles() {
    final circles = <Circle>{};
    if (_currentStatus != 'finding_rider') return circles;

    final t = _pulseController?.value ?? 0.0;
    const accent = Color(0xFF4A22A8);
    // Three staggered rings expanding from ~30m to ~220m.
    for (var i = 0; i < 3; i++) {
      final localT = ((t + i / 3) % 1.0);
      final radius = 30 + localT * 190;
      final fade = (1 - localT).clamp(0.0, 1.0);
      circles.add(Circle(
        circleId: CircleId('radar_$i'),
        center: _restaurantLatLng,
        radius: radius,
        fillColor: accent.withValues(alpha: 0.05 * fade),
        strokeColor: accent.withValues(alpha: 0.5 * fade),
        strokeWidth: 2,
      ));
    }
    return circles;
  }

  Map<String, dynamic>? _extractAssignedRider(Map<String, dynamic> data) {
    final assigned = data['assignedRider'];
    if (assigned is Map<String, dynamic>) {
      return assigned;
    }
    if (assigned is Map) {
      return assigned.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders_sl')
          .doc(widget.orderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final previousStatus = _currentStatus;
          _currentStatus = (data['orderStatus'] ?? 'confirmed').toString();
          _rejectionReason = (data['rejectionReason'] ?? '').toString();
          _assignedRider = _extractAssignedRider(data);
          final address = data['deliveryAddress'] as Map<String, dynamic>?;
          if (address != null && address['latitude'] != null) {
            final lat = _toDouble(address['latitude']);
            final lng = _toDouble(address['longitude']);
            if (lat != null && lng != null) {
              _deliveryLatLng = LatLng(lat, lng);
            }
            _restaurantLatLng = LatLng(_deliveryLatLng.latitude + 0.011,
                _deliveryLatLng.longitude + 0.011);
          }

          final riderLocation = data['riderLocation'];
          final hasRider = _assignedRider != null ||
              (data['assignedRiderId'] ?? '').toString().isNotEmpty;
          if (_liveTrackingStatuses.contains(_currentStatus) &&
              riderLocation is Map) {
            // Real GPS feed present — cancel any demo and track live.
            _stopDemo();
            _applyLiveRiderLocation(
              riderLocation.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            );
          } else if (_liveTrackingStatuses.contains(_currentStatus) &&
              hasRider &&
              !_usingLiveRiderFeed) {
            // Rider assigned (e.g. by admin) but no live GPS — run demo.
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _startDemoIfNeeded());
          } else if (!_liveTrackingStatuses.contains(_currentStatus) &&
              _currentStatus != 'delivered') {
            _stopDemo();
            _resetLiveTrackingVisuals();
          }

          // While the demo drives, its local status overrides the label.
          if (_demoRunning && _demoStatus != null) {
            _currentStatus = _demoStatus!;
          }

          _canCancel = _currentStatus == 'confirmed' ||
              _currentStatus == 'processing' ||
              _currentStatus == 'received';

          if (_currentStatus == 'delivered' &&
              previousStatus != 'delivered' &&
              !_handledDeliveredState) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _onDelivered());
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const UserPanel()),
                (route) => false,
              ),
            ),
            title: const Text('Order Status',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Map View
                  Expanded(
                    flex: 3,
                    child: AnimatedBuilder(
                      animation: _pulseController ??
                          const AlwaysStoppedAnimation(0.0),
                      builder: (context, _) => GoogleMap(
                        onMapCreated: (c) => _mapController = c,
                        initialCameraPosition:
                            CameraPosition(target: _deliveryLatLng, zoom: 15),
                        markers: _buildMarkers(),
                        polylines: _buildPolylines(),
                        circles: _buildCircles(),
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                  ),

                  // Status Content
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusHeader(),
                          const SizedBox(height: 20),
                          _buildProgressBar(),
                          const SizedBox(height: 28),
                          if (_riderAssigned)
                            _buildRiderCard()
                          else
                            _buildStatusDescription(),
                          const Spacer(),
                          if (_canCancel) _buildCancelButton(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_showDeliveredOverlay) _buildDeliveredOverlay(),
            ],
          ),
        );
      },
    );
  }

  // 0=Received, 1=Preparing, 2=Rider assigned, 3=On the way, 4=Delivered
  int get _stageIndex {
    switch (_currentStatus) {
      case 'preparing':
        return 1;
      case 'ready':
        return 2;
      case 'finding_rider':
        return 2;
      case 'picked_up':
        return 3;
      case 'on_the_way':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0; // processing / received
    }
  }

  static const int _totalStages = 4; // 4 segments like the reference

  String get _etaText {
    switch (_currentStatus) {
      case 'confirmed':
        return 'Awaiting restaurant';
      case 'preparing':
        return 'Preparing now';
      case 'ready':
        return 'Restaurant pickup ready';
      case 'finding_rider':
        return 'Finding rider';
      case 'picked_up':
        return 'Rider picked up';
      case 'on_the_way':
        return 'Live tracking active';
      default:
        return 'Live update';
    }
  }

  Widget _buildStatusHeader() {
    String title = 'Hanging tight...';
    String subtitle = 'Waiting for restaurant to receive your order';
    if (_currentStatus == 'confirmed') {
      title = 'Order placed';
      subtitle = 'Waiting for the restaurant to accept your order';
    }
    if (_currentStatus == 'preparing') {
      title = 'Preparing your order';
      subtitle = 'Restaurant is getting it ready';
    }
    if (_currentStatus == 'ready') {
      title = 'Restaurant pickup ready';
      subtitle = 'The restaurant has your order ready for pickup';
    }
    if (_currentStatus == 'finding_rider') {
      title = 'Finding rider';
      subtitle = 'We are matching a rider for your order';
    }
    if (_currentStatus == 'picked_up') {
      title = 'Picked up';
      subtitle = 'Your rider has collected the order';
    }
    if (_currentStatus == 'on_the_way') {
      title = 'Almost here!';
      subtitle = 'Rider is on the way to you';
    }
    if (_currentStatus == 'delivered') {
      title = 'Delivered!';
      subtitle = 'Enjoy your order';
    }
    if (_currentStatus == 'cancelled') {
      title = 'Order Cancelled';
      subtitle = 'Order was stopped';
    }
    if (_currentStatus == 'rejected') {
      title = 'Order Rejected';
      subtitle = _rejectionReason.isNotEmpty
          ? _rejectionReason
          : 'The restaurant could not accept your order';
    }

    final showEta = _currentStatus != 'delivered' &&
        _currentStatus != 'cancelled' &&
        _currentStatus != 'rejected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A22A8))),
        const SizedBox(height: 4),
        if (showEta)
          Row(
            children: [
              Text('Arriving at ',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
              Text(_etaText,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A22A8),
                      fontWeight: FontWeight.bold)),
            ],
          )
        else
          Text(subtitle,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Segmented Uber-style progress bar: completed segments stay purple; the
  // active (in-progress) segment pulses forward-and-backward to show motion.
  Widget _buildProgressBar() {
    final controller = _pulseController;
    if (controller == null) return const SizedBox(height: 6);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          children: List.generate(_totalStages, (i) {
            final filled = i < _stageIndex; // completed
            final active = i == _stageIndex && _currentStatus != 'delivered';
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == _totalStages - 1 ? 0 : 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: filled
                            ? const Color(0xFF4A22A8)
                            : Colors.grey.shade200,
                      ),
                      // Active segment: a purple fill whose width sweeps
                      // forward and backward via the pulse controller.
                      if (active)
                        FractionallySizedBox(
                          widthFactor: 0.25 + controller.value * 0.75,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF4A22A8),
                                Color(0xFF8E6AE8),
                              ]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  bool get _riderAssigned =>
      _currentStatus == 'finding_rider' ||
      _currentStatus == 'picked_up' ||
      _currentStatus == 'on_the_way' ||
      _assignedRider != null;

  // Uber-style rider card: photo, name, vehicle/plate, rating, actions.
  Widget _buildRiderCard() {
    final riderName = (_assignedRider?['name'] ??
            _assignedRider?['fullName'] ??
            'Assigned rider')
        .toString();
    final vehicle = (_assignedRider?['vehicle'] ??
            _assignedRider?['vehicleNumber'] ??
            _assignedRider?['vehicleType'] ??
            'Delivery vehicle')
        .toString();
    final ratingValue = _assignedRider?['rating'];
    final rating = ratingValue is num ? ratingValue.toStringAsFixed(1) : '4.8';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E2F5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A22A8).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE7FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    color: Color(0xFF4A22A8), size: 28),
              ),
              const SizedBox(width: 12),
              // Name + vehicle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(riderName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(rating,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE8A600))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(vehicle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.delivery_dining, color: Color(0xFF4A22A8)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpPage()),
                );
              },
              icon: const Icon(Icons.message, size: 16),
              label: const Text('Send a message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A22A8),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDescription() {
    String desc = 'Waiting for the restaurant to receive your order.';
    IconData icon = Icons.access_time_filled;

    // While the kitchen is preparing (or the order was just placed), show the
    // animated veggie/pizza/plate "hop" from the design instead of a static
    // icon — on the same white background.
    final showKitchenAnim =
        _currentStatus == 'preparing' || _currentStatus == 'confirmed';

    if (_currentStatus == 'confirmed') {
      desc =
          'Your order has been placed successfully and sent to the restaurant.';
      icon = Icons.receipt_long;
    } else if (_currentStatus == 'preparing') {
      desc =
          'Restaurant is preparing your items. Your money will be deducted shortly.';
      icon = Icons.restaurant;
    } else if (_currentStatus == 'ready') {
      desc =
          'The restaurant has finished preparing your order and dispatch is looking for a rider.';
      icon = Icons.store_mall_directory;
    } else if (_currentStatus == 'finding_rider') {
      desc =
          'A delivery rider has been assigned and is heading to the restaurant.';
      icon = Icons.moped;
    } else if (_currentStatus == 'picked_up') {
      desc =
          'Your rider has picked up the order and is starting the trip to you.';
      icon = Icons.shopping_bag;
    } else if (_currentStatus == 'on_the_way') {
      desc = 'A rider is on the way to your location.';
      icon = Icons.delivery_dining;
    }

    return Row(
      children: [
        if (showKitchenAnim)
          const _KitchenPreparingAnimation()
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black87),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            desc,
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 16, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _cancelOrder,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        child: const Text('Cancel Order',
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('orders_sl')
          .doc(widget.orderId)
          .update({
        'orderStatus': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Optionally navigate back after cancellation
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const UserPanel()),
          (route) => false,
        );
      }
    }
  }
}

/// "Kitchen is preparing" hop animation, ported from the Rider Tracking Map
/// design. Three food icons (veggie / pizza / plate) hop in sequence. Sits on
/// the white background of the status screen (design purple accent kept).
class _KitchenPreparingAnimation extends StatefulWidget {
  const _KitchenPreparingAnimation();

  @override
  State<_KitchenPreparingAnimation> createState() =>
      _KitchenPreparingAnimationState();
}

class _KitchenPreparingAnimationState extends State<_KitchenPreparingAnimation>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF4A22A8); // app purple

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          Widget hop(IconData icon, double phaseOffset) {
            final local = ((_controller.value + phaseOffset) % 1.0);
            final lift = math.sin(local * math.pi) * 6;
            return Transform.translate(
              offset: Offset(0, -lift),
              child: Icon(icon, color: _accent, size: 16),
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              hop(Icons.eco_outlined, 0.0),
              const SizedBox(width: 3),
              hop(Icons.local_pizza_outlined, 0.17),
              const SizedBox(width: 3),
              hop(Icons.restaurant_outlined, 0.34),
            ],
          );
        },
      ),
    );
  }
}
