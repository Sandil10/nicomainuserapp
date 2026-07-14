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
  List<LatLng> _routePoints = [];
  final List<LatLng> _riderTrail = [];
  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteFetchAt;
  bool _usingLiveRiderFeed = false;
  bool _navigatedAway = false;
  bool _handledDeliveredState = false;
  Map<String, dynamic>? _assignedRider;
  String _restaurantName = 'Restaurant';
  DateTime? _orderCreatedAt;
  String? _restaurantLocationLookupId;
  bool _usingLocalDemoFlow = false;
  DateTime? _lastCameraFollowAt;
  bool _cameraAnimatingProgrammatically = false;
  bool _userControllingMap = false;
  Timer? _userMapResumeTimer;

  // ---- "Map UI" design marker set (exact port of map_ui_screen.dart) ------
  // Black rounded-rect vehicle that follows the route with correct heading,
  // white pickup-spot dot, black customer pin, white label pills and the
  // pickup bag — all drawn as bitmaps and placed on the real Google Map.
  BitmapDescriptor? _vehicleIcon;
  BitmapDescriptor? _pickupSpotIcon;
  BitmapDescriptor? _customerPinIcon;
  BitmapDescriptor? _youPillIcon;
  BitmapDescriptor? _pickupPillIcon;
  BitmapDescriptor? _bagIcon;
  BitmapDescriptor? _milesPillIcon;
  String _milesPillText = '';
  double _riderBearing = 0; // vehicle heading (degrees from north)

  // Shows the delivered success animation overlay before navigating away.
  bool _showDeliveredOverlay = false;

  // Tracks whether the camera is parked on the restaurant (pre-rider phases).
  bool _cameraOnRestaurant = false;

  // --- Demo rider animation (visual only, never written to Firestore) -------
  // When a rider is assigned but no real GPS feed exists, we animate a demo
  // rider: ~1km away -> restaurant (pickup) -> user location (delivered),
  // compressed into ~5 minutes. A real riderLocation feed cancels the demo.
  static const Duration _demoTotal = Duration(seconds: 45);
  static const Duration _demoTick = Duration(milliseconds: 700);
  static const Duration _placedHold = Duration(seconds: 5);
  static const Duration _preparingHold = Duration(seconds: 5);
  Timer? _demoTimer;
  Timer? _statusRefreshTimer;
  bool _demoRunning = false;
  double _demoProgress = 0; // 0..1 across the whole leg sequence
  List<LatLng> _demoLegToRestaurant = [];
  List<LatLng> _demoLegToCustomer = [];
  // Local status shown during the demo, overrides the Firestore status label.
  String? _demoStatus;
  bool _demoDelivered = false;

  // Throttled (~10fps) driver for the map's radar-pulse Circles while
  // "finding_rider" is active. Deliberately NOT an AnimatedBuilder wrapping
  // GoogleMap — see the comment at the GoogleMap widget for why that broke
  // the map on Android.
  Timer? _radarPulseTimer;

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
    _loadMapIcons();
    _radarPulseTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      // Radar rings animate while we're matching a rider (pre-rider phases).
      if (_isPreRiderPhase) setState(() {});
    });
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _orderCreatedAt == null) return;
      if (_currentStatus == 'confirmed' ||
          (_usingLocalDemoFlow && !_demoRunning)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _userMapResumeTimer?.cancel();
    _statusRefreshTimer?.cancel();
    _radarPulseTimer?.cancel();
    _pulseController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ---- "Map UI" design bitmaps (exact port of map_ui_screen.dart) ---------

  static const Color _routeBlack = Color(0xFF0A0A0A);

  /// Renders [draw] on a canvas of [w]x[h] physical px shown at [w]/[scale]
  /// logical px, so all marker art stays crisp and small on high-DPI screens.
  Future<BitmapDescriptor> _bitmap(
    double w,
    double h,
    void Function(Canvas canvas) draw, {
    double scale = 3,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    draw(canvas);
    final img = await recorder
        .endRecording()
        .toImage((w * scale).round(), (h * scale).round());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: scale,
      width: w,
      height: h,
    );
  }

  /// White label pill with soft shadow — the design's `_MapPill`.
  Future<BitmapDescriptor> _pillBitmap(String label, {bool small = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFF111111),
          fontSize: small ? 10.5 : 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final padH = small ? 9.0 : 11.0;
    final padV = small ? 5.0 : 7.0;
    final w = tp.width + padH * 2 + 8;
    final h = tp.height + padV * 2 + 8;
    return _bitmap(w, h, (canvas) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, w - 8, h - 8),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        rect.shift(const Offset(0, 2)),
        Paint()
          ..color = Colors.black26
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
      );
      canvas.drawRRect(rect, Paint()..color = Colors.white);
      tp.paint(canvas, Offset(4 + padH, 4 + padV));
    });
  }

  Future<void> _loadMapIcons() async {
    try {
      // Vehicle: small black rounded rect with white border + windshield
      // stripe — exact port of map_ui_screen.dart's rider marker. Drawn
      // pointing north (up) so marker `rotation` = bearing rotates it
      // correctly toward the pickup spot / customer.
      final vehicle = await _bitmap(16, 30, (canvas) {
        final rect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 16, 30),
          const Radius.circular(5),
        );
        canvas.drawRRect(rect, Paint()..color = const Color(0xFF111111));
        canvas.drawRRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.85),
        );
        // Windshield stripe near the front (top).
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(2.5, 3, 11, 5),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.28),
        );
      });

      // Restaurant pickup marker: small dimensional restaurant icon.
      final pickupSpot = await _bitmap(28, 28, (canvas) {
        canvas.drawCircle(
          const Offset(14, 15),
          11.5,
          Paint()
            ..color = Colors.black26
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
        );
        canvas.drawCircle(
            const Offset(14, 13), 11.5, Paint()..color = Colors.white);
        canvas.drawCircle(
          const Offset(14, 13),
          8.4,
          Paint()..color = const Color(0xFFFFF0DC),
        );
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.restaurant_rounded.codePoint),
            style: TextStyle(
              fontSize: 13,
              fontFamily: Icons.restaurant_rounded.fontFamily,
              color: const Color(0xFFD46A00),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(14 - tp.width / 2, 13 - tp.height / 2));
        canvas.drawCircle(
          const Offset(14, 13),
          11.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xFFFFB25A),
        );
      });

      // Customer destination: explicit black destination pin, not a default dot.
      final customerPin = await _bitmap(34, 34, (canvas) {
        canvas.drawCircle(
          const Offset(17, 18),
          12.5,
          Paint()
            ..color = Colors.black26
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          const Offset(17, 16),
          12.5,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          const Offset(17, 16),
          12.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = _routeBlack,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.flag_rounded.codePoint),
            style: TextStyle(
              fontSize: 18,
              fontFamily: Icons.flag_rounded.fontFamily,
              color: _routeBlack,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(17 - tp.width / 2, 16 - tp.height / 2));
      });

      // Pickup bag: white circle with black shopping bag.
      final bag = await _bitmap(26, 26, (canvas) {
        canvas.drawCircle(
          const Offset(13, 14),
          11,
          Paint()
            ..color = Colors.black26
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
        );
        canvas.drawCircle(
            const Offset(13, 13), 11, Paint()..color = Colors.white);
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.shopping_bag.codePoint),
            style: TextStyle(
              fontSize: 11,
              fontFamily: Icons.shopping_bag.fontFamily,
              color: _routeBlack,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(13 - tp.width / 2, 13 - tp.height / 2));
      });

      final youPill = await _pillBitmap('You', small: true);
      final pickupPill = await _pillBitmap(_restaurantName);

      if (!mounted) return;
      setState(() {
        _vehicleIcon = vehicle;
        _pickupSpotIcon = pickupSpot;
        _customerPinIcon = customerPin;
        _bagIcon = bag;
        _youPillIcon = youPill;
        _pickupPillIcon = pickupPill;
      });
    } catch (e) {
      debugPrint('map icon build failed: $e');
    }
  }

  /// Rebuilds the miles pill only when its text changes (e.g. "0.4 miles").
  Future<void> _updateMilesPill(String text) async {
    if (text == _milesPillText) return;
    _milesPillText = text;
    if (text.isEmpty) {
      if (mounted) setState(() => _milesPillIcon = null);
      return;
    }
    final pill = await _pillBitmap(text);
    if (mounted && text == _milesPillText) {
      setState(() => _milesPillIcon = pill);
    }
  }

  Future<void> _updatePickupPill(String text) async {
    final label = text.trim().isEmpty ? 'Restaurant' : text.trim();
    final pill = await _pillBitmap(label);
    if (mounted && _restaurantName == label) {
      setState(() => _pickupPillIcon = pill);
    }
  }

  // Bearing (heading) between two points so the vehicle faces forward.
  double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
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

  Future<void> _smoothFollowRider(LatLng rider, LatLng target) async {
    final controller = _mapController;
    if (controller == null || _userControllingMap) return;

    final now = DateTime.now();
    if (_lastCameraFollowAt != null &&
        now.difference(_lastCameraFollowAt!).inMilliseconds < 2500) {
      return;
    }
    _lastCameraFollowAt = now;

    final distance = _distanceBetween(rider, target);
    final zoom = distance > 1200
        ? 14.6
        : distance > 600
            ? 15.2
            : 16.0;

    _cameraAnimatingProgrammatically = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: rider, zoom: zoom),
        ),
      );
    } finally {
      Future.delayed(const Duration(milliseconds: 250), () {
        _cameraAnimatingProgrammatically = false;
      });
    }
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
          final pts = _thinRoute(_decodePolyline(encoded));
          if (pts.length >= 2) return pts;
        }
      }
    } catch (_) {
      // fall through to the curved fallback
    }
    // Fallback: a gently curved multi-point path so movement looks natural
    // even when the Directions API is unavailable.
    return _thinRoute(_curvedFallback(origin, dest));
  }

  List<LatLng> _thinRoute(List<LatLng> points, {int maxPoints = 34}) {
    if (points.length <= maxPoints) return points;
    final last = points.length - 1;
    final step = last / (maxPoints - 1);
    final thinned = <LatLng>[];
    for (var i = 0; i < maxPoints; i++) {
      final index = (i * step).round().clamp(0, last);
      if (thinned.isEmpty || thinned.last != points[index]) {
        thinned.add(points[index]);
      }
    }
    if (thinned.last != points.last) thinned.add(points.last);
    return thinned;
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

    if (_riderLatLng != null &&
        _distanceBetween(_riderLatLng!, nextPosition) < 2) {
      _usingLiveRiderFeed = true;
      return;
    }

    // Heading for the vehicle marker: feed-provided bearing when available,
    // otherwise derived from the movement direction.
    final feedBearing = _toDouble(locationData['bearing']);
    if (feedBearing != null) {
      _riderBearing = feedBearing;
    } else if (_riderLatLng != null) {
      _riderBearing = _bearing(_riderLatLng!, nextPosition);
    }

    _riderLatLng = nextPosition;
    _usingLiveRiderFeed = true;

    // Miles pill: distance still to drive to the current target.
    final target =
        _currentStatus == 'finding_rider' ? _restaurantLatLng : _deliveryLatLng;
    final miles = _distanceBetween(nextPosition, target) / 1609.34;
    unawaited(
        _updateMilesPill('${math.max(0.05, miles).toStringAsFixed(1)} miles'));

    unawaited(_refreshRouteFromRider(nextPosition));
  }

  void _resetLiveTrackingVisuals() {
    _riderLatLng = null;
    _routePoints = [];
    _riderTrail.clear();
    _lastRouteOrigin = null;
    _lastRouteFetchAt = null;
    _usingLiveRiderFeed = false;
    unawaited(_updateMilesPill(''));
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

  /// The part of [path] still AHEAD of fraction [t] — the design draws only
  /// the remaining route in front of the vehicle (Uber style).
  List<LatLng> _remainingOfPath(List<LatLng> path, double t) {
    if (path.length < 2 || t <= 0) return path;
    if (t >= 1) return const [];
    final segLengths = <double>[];
    double total = 0;
    for (var i = 0; i < path.length - 1; i++) {
      final d = _distanceBetween(path[i], path[i + 1]);
      segLengths.add(d);
      total += d;
    }
    if (total == 0) return path;
    double target = t * total;
    for (var i = 0; i < segLengths.length; i++) {
      if (target <= segLengths[i]) {
        final f = segLengths[i] == 0 ? 0.0 : target / segLengths[i];
        final current = LatLng(
          path[i].latitude + (path[i + 1].latitude - path[i].latitude) * f,
          path[i].longitude + (path[i + 1].longitude - path[i].longitude) * f,
        );
        return [current, ...path.sublist(i + 1)];
      }
      target -= segLengths[i];
    }
    return const [];
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
    if (toCustomer.length < 2) {
      toCustomer = [_restaurantLatLng, _deliveryLatLng];
    }

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

    final totalTicks = _demoTotal.inMilliseconds ~/ _demoTick.inMilliseconds;
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
    String status;
    List<LatLng> remaining;
    LatLng target;

    if (p < 0.5) {
      // Leg 1: toward restaurant.
      final legT = p / 0.5;
      next = _pointAlong(_demoLegToRestaurant, legT);
      status = 'finding_rider';
      remaining = _remainingOfPath(_demoLegToRestaurant, legT);
      target = _restaurantLatLng;
    } else {
      // Leg 2: restaurant -> customer.
      final legT = (p - 0.5) / 0.5;
      next = _pointAlong(_demoLegToCustomer, legT);
      status = 'on_the_way';
      remaining = _remainingOfPath(_demoLegToCustomer, legT);
      target = _deliveryLatLng;
    }

    final prev = _riderLatLng;
    setState(() {
      if (prev != null && _distanceBetween(prev, next) > 1) {
        _riderBearing = _bearing(prev, next);
      }
      _riderLatLng = next;
      // Only the remaining path ahead of the vehicle is drawn (design rule).
      _routePoints = remaining;
      _demoStatus = status;
    });

    unawaited(_smoothFollowRider(next, target));

    // Miles pill next to the pickup spot (design: distance still to drive).
    final miles = _distanceBetween(next, target) / 1609.34;
    unawaited(
        _updateMilesPill('${math.max(0.05, miles).toStringAsFixed(1)} miles'));

    if (p >= 1.0 && !_demoDelivered) {
      _demoDelivered = true;
      _demoStatus = 'delivered';
      unawaited(_updateMilesPill(''));
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

  /// Statuses before a rider exists: the order is with the restaurant.
  bool get _isPreRiderPhase => const {
        'confirmed',
        'processing',
        'received',
        'preparing',
        'ready',
      }.contains(_currentStatus);

  // Marker layer — exact port of the "Map UI" design onto the real map:
  // pickup spot (white circle + black dot) with "Pickup spot" + miles pills,
  // customer black pin with "You" pill, bag at pickup, and the black
  // rounded-rect vehicle rotated to its heading.
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Pickup spot + label (always visible, like the design).
    markers.add(Marker(
      markerId: const MarkerId('pickup_spot'),
      position: _restaurantLatLng,
      icon: _pickupSpotIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      anchor: const Offset(0.5, 0.5),
      zIndexInt: 3,
    ));
    if (_pickupPillIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup_pill'),
        position: _restaurantLatLng,
        icon: _pickupPillIcon!,
        // Right edge of the pill sits left of the spot (design dx: -76).
        anchor: const Offset(1.15, 0.5),
        zIndexInt: 2,
      ));
    }
    if (_milesPillIcon != null && _milesPillText.isNotEmpty) {
      markers.add(Marker(
        markerId: const MarkerId('miles_pill'),
        position: _restaurantLatLng,
        icon: _milesPillIcon!,
        // Left edge of the pill sits right of the spot (design dx: 66).
        anchor: const Offset(-0.15, 0.5),
        zIndexInt: 2,
      ));
    }

    // Customer pin + "You" pill (always visible, like the design).
    markers.add(Marker(
      markerId: const MarkerId('customer_pin'),
      position: _deliveryLatLng,
      icon: _customerPinIcon ?? BitmapDescriptor.defaultMarker,
      anchor: const Offset(0.5, 0.5),
      zIndexInt: 3,
    ));
    if (_youPillIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('you_pill'),
        position: _deliveryLatLng,
        icon: _youPillIcon!,
        // Pill floats just below the pin point (design dy: +18).
        anchor: const Offset(0.5, -0.35),
        zIndexInt: 2,
      ));
    }

    // Bag at the restaurant while the rider collects the order.
    if (_currentStatus == 'picked_up' && _bagIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup_bag'),
        position: _restaurantLatLng,
        icon: _bagIcon!,
        // Floats above the pickup spot (design dy: -34).
        anchor: const Offset(0.5, 2.1),
        zIndexInt: 4,
      ));
    }

    // Vehicle following the route with correct heading.
    if (_riderLatLng != null &&
        !_isPreRiderPhase &&
        _currentStatus != 'delivered') {
      markers.add(Marker(
        markerId: const MarkerId('rider'),
        position: _riderLatLng!,
        icon: _vehicleIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        rotation: _riderBearing,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 5,
      ));
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final lines = <Polyline>{};
    // Solid BLACK route, and only the REMAINING path ahead of the rider is
    // drawn (Uber style) — the demo/live update keeps _routePoints trimmed
    // to the part that is still ahead.
    if (_routePoints.length >= 2 && !_isPreRiderPhase) {
      lines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: _routeBlack,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        zIndex: 1,
      ));
    }
    return lines;
  }

  /// Radar rings around the restaurant while we're matching a rider — the
  /// design's `_RadarRings`, drawn as expanding, fading map Circles.
  Set<Circle> _buildCircles() {
    final circles = <Circle>{};
    if (!_isPreRiderPhase) return circles;

    final t = _pulseController?.value ?? 0.0;
    const accent = Color(0xFFA855F7);
    // Two light rings only; animated map circles are expensive on phones.
    for (var i = 0; i < 2; i++) {
      final localT = ((t + i / 2) % 1.0);
      final radius = 35 + localT * 120;
      final fade = (1 - localT).clamp(0.0, 1.0);
      circles.add(Circle(
        circleId: CircleId('radar_$i'),
        center: _restaurantLatLng,
        radius: radius,
        fillColor: accent.withValues(alpha: 0.025 * fade),
        strokeColor: accent.withValues(alpha: 0.28 * fade),
        strokeWidth: 1,
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

  LatLng? _extractLatLng(dynamic value) {
    if (value is GeoPoint) {
      return LatLng(value.latitude, value.longitude);
    }
    if (value is Map) {
      final lat = _toDouble(value['latitude'] ?? value['lat']);
      final lng = _toDouble(value['longitude'] ?? value['lng']);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return null;
  }

  DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _localDemoStatus(String remoteStatus) {
    _usingLocalDemoFlow = false;
    if (remoteStatus != 'confirmed' || _orderCreatedAt == null) {
      return remoteStatus;
    }

    final elapsed = DateTime.now().difference(_orderCreatedAt!);
    if (elapsed < _placedHold) return 'confirmed';
    if (elapsed < _placedHold + _preparingHold) return 'preparing';

    _usingLocalDemoFlow = true;
    return 'finding_rider';
  }

  Future<void> _loadRestaurantLocation(String restaurantId) async {
    if (restaurantId.isEmpty || _restaurantLocationLookupId == restaurantId) {
      return;
    }
    _restaurantLocationLookupId = restaurantId;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();
      final data = snap.data();
      final location = data == null
          ? null
          : (_extractLatLng(data['location']) ??
              _extractLatLng({
                'latitude': data['latitude'],
                'longitude': data['longitude'],
              }));
      if (!mounted || location == null) return;
      setState(() {
        _restaurantLatLng = location;
        _cameraOnRestaurant = false;
      });
    } catch (e) {
      debugPrint('Could not load restaurant pickup location: $e');
    }
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
          final remoteStatus = (data['orderStatus'] ?? 'confirmed').toString();
          _orderCreatedAt ??= _readTimestamp(data['createdAt']) ??
              _readTimestamp(data['orderDate']) ??
              DateTime.now();
          _currentStatus = _localDemoStatus(remoteStatus);
          _rejectionReason = (data['rejectionReason'] ?? '').toString();
          _assignedRider = _extractAssignedRider(data);
          final nextRestaurantName =
              (data['restaurantName'] ?? 'Restaurant').toString().trim();
          if (nextRestaurantName.isNotEmpty &&
              nextRestaurantName != _restaurantName) {
            _restaurantName = nextRestaurantName;
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => _updatePickupPill(_restaurantName));
          }
          final address = data['deliveryAddress'] as Map<String, dynamic>?;
          if (address != null && address['latitude'] != null) {
            final lat = _toDouble(address['latitude']);
            final lng = _toDouble(address['longitude']);
            if (lat != null && lng != null) {
              _deliveryLatLng = LatLng(lat, lng);
            }
            if (_restaurantLocationLookupId == null) {
              _restaurantLatLng = LatLng(_deliveryLatLng.latitude + 0.011,
                  _deliveryLatLng.longitude + 0.011);
            }
          }

          final orderRestaurantLocation =
              _extractLatLng(data['restaurantLocation']) ??
                  _extractLatLng({
                    'latitude': data['restaurantLatitude'],
                    'longitude': data['restaurantLongitude'],
                  });
          if (orderRestaurantLocation != null) {
            _restaurantLatLng = orderRestaurantLocation;
          } else {
            final restaurantId = (data['restaurantId'] ?? '').toString();
            if (restaurantId.isNotEmpty &&
                _restaurantLocationLookupId != restaurantId) {
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _loadRestaurantLocation(restaurantId));
            }
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
              (hasRider || _usingLocalDemoFlow) &&
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

          // While the restaurant is preparing (pre-rider), park the camera on
          // the restaurant; once a rider phase starts the route-fit logic and
          // rider updates take over the camera.
          if (_isPreRiderPhase && !_cameraOnRestaurant) {
            _cameraOnRestaurant = true;
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_restaurantLatLng, 15.5),
            );
          } else if (!_isPreRiderPhase) {
            _cameraOnRestaurant = false;
          }

          if (_currentStatus == 'delivered' &&
              previousStatus != 'delivered' &&
              !_handledDeliveredState) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _onDelivered());
          }
        }

        final showMapPanel = !const {
          'confirmed',
          'processing',
          'received',
        }.contains(_currentStatus);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              // Pop back to the existing home when possible — rebuilding the
              // whole UserPanel with pushAndRemoveUntil made "back" feel slow.
              onPressed: () {
                final nav = Navigator.of(context);
                if (nav.canPop()) {
                  nav.pop();
                } else {
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const UserPanel()),
                    (route) => false,
                  );
                }
              },
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
                  //
                  // IMPORTANT: GoogleMap is a native PlatformView on Android.
                  // It previously sat inside an AnimatedBuilder that rebuilt
                  // it on every animation frame (60fps) to drive the radar
                  // pulse circles — that thrashed the underlying native
                  // Android MapView badly enough that it never finished
                  // initializing (blank map on Android only; iOS tolerated
                  // it, which is why this bug was Android-specific). Fixed by
                  // giving GoogleMap a stable key and driving the pulse via a
                  // throttled ~10fps Timer (_radarPulseTimer) that calls the
                  // screen's own setState, instead of rebuilding this widget
                  // from an Animation listener.
                  Expanded(
                    flex: 3,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: showMapPanel
                          ? GoogleMap(
                              key: const ValueKey('order_status_map'),
                              onMapCreated: (c) {
                                _mapController = c;
                                // If the order is still with the restaurant when the
                                // map appears, start focused on the restaurant.
                                if (_isPreRiderPhase) {
                                  _cameraOnRestaurant = true;
                                  c.animateCamera(CameraUpdate.newLatLngZoom(
                                      _restaurantLatLng, 15.5));
                                }
                              },
                              onCameraMoveStarted: () {
                                if (_cameraAnimatingProgrammatically) return;
                                _userControllingMap = true;
                                _userMapResumeTimer?.cancel();
                                _userMapResumeTimer = Timer(
                                  const Duration(seconds: 4),
                                  () {
                                    if (mounted) _userControllingMap = false;
                                  },
                                );
                              },
                              initialCameraPosition: CameraPosition(
                                  target: _restaurantLatLng, zoom: 15.5),
                              markers: _buildMarkers(),
                              polylines: _buildPolylines(),
                              circles: _buildCircles(),
                              zoomControlsEnabled: false,
                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              rotateGesturesEnabled: false,
                              myLocationButtonEnabled: false,
                              // Perf: skip expensive layers this screen never uses.
                              buildingsEnabled: false,
                              tiltGesturesEnabled: false,
                              mapToolbarEnabled: false,
                              compassEnabled: false,
                              trafficEnabled: false,
                            )
                          : _buildOrderPlacedIntro(),
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

  Widget _buildOrderPlacedIntro() {
    return Container(
      key: const ValueKey('order_placed_intro'),
      width: double.infinity,
      color: const Color(0xFFF7F3FF),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: const Color(0xFF4A22A8).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long,
                  color: Color(0xFF4A22A8), size: 42),
            ),
            const SizedBox(height: 16),
            const Text(
              'Order placed',
              style: TextStyle(
                color: Color(0xFF4A22A8),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sending it to the restaurant',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A22A8))),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (_etaMinutesText != null) ...[
          const SizedBox(width: 12),
          _buildEtaPill(_etaMinutesText!),
        ],
      ],
    );
  }

  // Purple "ETA · N MIN" pill, matching the Rider Tracking Map design.
  String? get _etaMinutesText {
    switch (_currentStatus) {
      case 'finding_rider':
      case 'picked_up':
      case 'on_the_way':
        return '5 MIN';
      case 'delivered':
        return '0 MIN';
      default:
        return null;
    }
  }

  Widget _buildEtaPill(String eta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4A22A8).withValues(alpha: 0.10),
        border:
            Border.all(color: const Color(0xFF4A22A8).withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        children: [
          const Text('ETA',
              style: TextStyle(
                  color: Color(0xFF8E6AE8),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4)),
          const SizedBox(height: 2),
          Text(eta,
              style: const TextStyle(
                  color: Color(0xFF4A22A8),
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      ),
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
    // Guard against attempting a write the Firestore rules will reject —
    // cancellation is only allowed while the order hasn't been accepted yet.
    const cancellableStatuses = {'confirmed', 'processing', 'received'};
    if (!cancellableStatuses.contains(_currentStatus)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'This order can no longer be cancelled — the restaurant has already started preparing it.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('orders_sl')
          .doc(widget.orderId)
          .update({
        'orderStatus': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UserPanel()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not cancel the order: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
