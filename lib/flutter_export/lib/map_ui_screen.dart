// map_ui_screen.dart
//
// "Map UI" — Uber-style live delivery tracking screen for NicoMart (Flutter).
// Google-Maps-style light map: cream canvas, WHITE roads with soft casings,
// beige building blocks with white outlines, green park blocks, blue place
// labels, a rotated street name, solid BLACK route line (only the remaining
// path ahead of the rider is drawn, like Uber), and a black rounded-rect
// vehicle marker that follows the route with correct heading.
//
// Delivery lifecycle (matches the approved HTML design 1:1):
//   1. placed        — order placed; kitchen preparing + radar rings while
//                      matching a rider
//   2. toRestaurant  — rider assigned; drives the black approach route TO the
//                      restaurant while food is still preparing
//   3. pickedUp      — bag bounce at the restaurant
//   4. onTheWay      — rider drives the black route to the customer
//   5. delivered     — green check overlay, then loops
//
// Self-contained: no packages beyond Flutter. To wire real data, replace the
// timer/ticker simulation in _cycle/_approach/_drive with your Firestore /
// socket order-status stream, and feed real polylines into _approachAnchors /
// _routeAnchors (normalized 0..1 coordinates).
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const MapUiScreen(),
//   ));

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum RiderVehicleType { bike, car }

enum DeliveryPhase { placed, toRestaurant, pickedUp, onTheWay, delivered }

class MapUiScreen extends StatefulWidget {
  final RiderVehicleType vehicleType;
  final String riderName;
  final double riderRating;
  final String vehiclePlate;
  final int approachSeconds; // simulated rider -> restaurant drive
  final int driveSeconds; // simulated restaurant -> customer drive

  const MapUiScreen({
    super.key,
    this.vehicleType = RiderVehicleType.bike,
    this.riderName = 'Kasun Perera',
    this.riderRating = 4.9,
    this.vehiclePlate = 'WP CAB-4521',
    this.approachSeconds = 5,
    this.driveSeconds = 7,
  });

  @override
  State<MapUiScreen> createState() => _MapUiScreenState();
}

class _MapUiScreenState extends State<MapUiScreen>
    with TickerProviderStateMixin {
  // ---- Googer design tokens (bottom sheet chrome) ----
  static const bg1 = Color(0xFF18181B);
  static const accent = Color(0xFFA855F7);
  static const accentLight = Color(0xFFC084FC);
  static const success = Color(0xFF22C55E);
  static const like = Color(0xFFEF4444);
  static const fgMute = Color(0xFFA1A1AA);
  static const fgFaint = Color(0xFF71717A);

  // ---- Google-Maps-style map palette ----
  static const mapBg = Color(0xFFE8E6E1);
  static const roadCasing = Color(0xFFDBD8D2);
  static const roadFill = Color(0xFFFFFFFF);
  static const blockA = Color(0xFFF7F2E4);
  static const blockB = Color(0xFFEFEADB);
  static const park = Color(0xFFCFE6C8);
  static const routeBlack = Color(0xFF0A0A0A);
  static const streetLabel = Color(0xFF9AA7B3);
  static const placeLabel = Color(0xFF4A75C9);

  DeliveryPhase _phase = DeliveryPhase.placed;
  double _ta = 0; // 0..1 along approach route (rider -> restaurant)
  double _t = 0; // 0..1 along main route (restaurant -> customer)
  int _etaMin = 9;

  Timer? _phaseTimer;
  Ticker? _ticker;
  Duration? _tickStart;

  late final AnimationController _radar =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat();
  late final AnimationController _bagBounce =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);
  late final AnimationController _searchBar =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);
  late final AnimationController _veggie =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();
  late final AnimationController _checkPop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  // Normalized (0..1) anchors. Restaurant top-right, customer bottom-left.
  static const List<Offset> _routeAnchors = [
    Offset(0.846, 0.071),
    Offset(0.800, 0.124),
    Offset(0.769, 0.166),
    Offset(0.756, 0.207), // restaurant handoff point (~30%)
    Offset(0.577, 0.308),
    Offset(0.308, 0.438),
    Offset(0.231, 0.509),
  ];

  // Rider spawn (bottom of map) -> restaurant, along the vertical road.
  static const List<Offset> _approachAnchors = [
    Offset(0.949, 0.758),
    Offset(0.892, 0.640),
    Offset(0.846, 0.486),
    Offset(0.833, 0.379),
    Offset(0.795, 0.266),
    Offset(0.756, 0.207),
  ];

  static const Offset _restaurant = Offset(0.756, 0.207);
  static const Offset _customer = Offset(0.231, 0.509);

  @override
  void initState() {
    super.initState();
    _cycle();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _ticker?.dispose();
    _radar.dispose();
    _bagBounce.dispose();
    _searchBar.dispose();
    _veggie.dispose();
    _checkPop.dispose();
    super.dispose();
  }

  void _cycle() {
    setState(() {
      _phase = DeliveryPhase.placed;
      _ta = 0;
      _t = 0;
      _etaMin = 9;
    });
    _phaseTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      _approach();
    });
  }

  void _runTicker(int seconds, void Function(double) onT, VoidCallback onDone) {
    _tickStart = null;
    _ticker?.dispose();
    _ticker = createTicker((elapsed) {
      _tickStart ??= elapsed;
      final v = ((elapsed - _tickStart!).inMilliseconds / (seconds * 1000))
          .clamp(0.0, 1.0);
      onT(v);
      if (v >= 1.0) {
        _ticker?.stop();
        onDone();
      }
    })
      ..start();
  }

  void _approach() {
    setState(() => _phase = DeliveryPhase.toRestaurant);
    _runTicker(widget.approachSeconds.clamp(1, 60), (v) {
      setState(() => _ta = v);
    }, () {
      _phaseTimer = Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _phase = DeliveryPhase.pickedUp);
        _phaseTimer = Timer(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          _drive();
        });
      });
    });
  }

  void _drive() {
    setState(() => _phase = DeliveryPhase.onTheWay);
    _runTicker(widget.driveSeconds.clamp(1, 60), (v) {
      setState(() {
        _t = v;
        _etaMin = ((1 - v) * 9).round();
      });
    }, () {
      _phaseTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _phase = DeliveryPhase.delivered);
        _checkPop.forward(from: 0);
        _phaseTimer = Timer(const Duration(milliseconds: 2800), () {
          if (!mounted) return;
          _checkPop.reset();
          _cycle();
        });
      });
    });
  }

  static const double _restaurantLegT = 0.30;

  double get _mainT {
    switch (_phase) {
      case DeliveryPhase.placed:
      case DeliveryPhase.toRestaurant:
        return 0;
      case DeliveryPhase.pickedUp:
        return _restaurantLegT;
      case DeliveryPhase.onTheWay:
        return _restaurantLegT + _t * (1 - _restaurantLegT);
      case DeliveryPhase.delivered:
        return 1;
    }
  }

  bool get _isToRestaurant => _phase == DeliveryPhase.toRestaurant;
  bool get _showRider => _phase != DeliveryPhase.placed;

  String get _milesLabel {
    switch (_phase) {
      case DeliveryPhase.toRestaurant:
        return math.max(0.05, 0.4 * (1 - _ta)).toStringAsFixed(1) + ' miles';
      case DeliveryPhase.pickedUp:
        return '0.5 miles';
      case DeliveryPhase.onTheWay:
        return math.max(0.05, 0.5 * (1 - _t)).toStringAsFixed(1) + ' miles';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapUiPainter(
                routeAnchors: _routeAnchors,
                approachAnchors: _approachAnchors,
                mainProgress: _mainT,
                approachProgress: _ta,
                showApproach: _isToRestaurant,
                showMainRoute: _phase == DeliveryPhase.pickedUp ||
                    _phase == DeliveryPhase.onTheWay ||
                    _phase == DeliveryPhase.delivered,
              ),
            ),
          ),

          // Radar rings while matching a rider
          if (_phase == DeliveryPhase.placed)
            _MarkerAt(
              point: _restaurant,
              child: AnimatedBuilder(
                animation: _radar,
                builder: (context, _) =>
                    _RadarRings(progress: _radar.value, color: accent),
              ),
            ),

          // Pickup spot: white circle + black dot, "Pickup spot" pill, miles pill
          _MarkerAt(
            point: _restaurant,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: routeBlack, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          _MarkerAt(
            point: _restaurant,
            dx: -76,
            child: const _MapPill(label: 'Pickup spot'),
          ),
          if (_milesLabel.isNotEmpty)
            _MarkerAt(
              point: _restaurant,
              dx: 66,
              child: _MapPill(label: _milesLabel),
            ),

          // Bag bounce at pickup
          if (_phase == DeliveryPhase.pickedUp)
            _MarkerAt(
              point: _restaurant,
              dy: -34,
              child: AnimatedBuilder(
                animation: _bagBounce,
                builder: (context, _) => Transform.translate(
                  offset: Offset(0, -6 * _bagBounce.value),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.shopping_bag,
                        color: Color(0xFF0A0A0A), size: 15),
                  ),
                ),
              ),
            ),

          // Customer pin + "You" pill
          _MarkerAt(
            point: _customer,
            dy: -17,
            child: const Icon(Icons.location_on, color: routeBlack, size: 34),
          ),
          _MarkerAt(
            point: _customer,
            dy: 18,
            child: const _MapPill(label: 'You', small: true),
          ),

          // Rider marker: black rounded rect, rotated to heading
          if (_showRider)
            _RouteFollower(
              anchors: _isToRestaurant ? _approachAnchors : _routeAnchors,
              t: _isToRestaurant ? _ta : _mainT,
              builder: (context, angle) => Transform.rotate(
                angle: angle + math.pi / 2,
                child: Container(
                  width: 16,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 3, left: 2.5, right: 2.5),
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Top chrome
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundIconButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => Navigator.maybePop(context)),
                  const _LiveBadge(color: like),
                ],
              ),
            ),
          ),

          // Googer dark bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: _StatusSheet(
              phase: _phase,
              etaMin: _etaMin,
              driveT: _t,
              searchAnim: _searchBar,
              veggieAnim: _veggie,
              riderName: widget.riderName,
              riderRating: widget.riderRating,
              vehiclePlate: widget.vehiclePlate,
              vehicleType: widget.vehicleType,
            ),
          ),

          // Delivered overlay
          if (_phase == DeliveryPhase.delivered)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _checkPop,
                builder: (context, _) {
                  final pop = Curves.elasticOut
                      .transform(_checkPop.value.clamp(0.0, 1.0));
                  return Container(
                    color: Colors.black.withValues(alpha: 0.88),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: 0.3 + 0.7 * pop,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                  color: success, shape: BoxShape.circle),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 52),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Delivered',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          const Text('Enjoy your order',
                              style: TextStyle(color: fgMute, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// Shared path helpers
// ============================================================
Path _pathFrom(List<Offset> anchors, Size size) {
  final pts =
      anchors.map((o) => Offset(o.dx * size.width, o.dy * size.height)).toList();
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    final prev = pts[i - 1];
    final cur = pts[i];
    final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
    path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
  }
  path.lineTo(pts.last.dx, pts.last.dy);
  return path;
}

Tangent? _tangentAt(Path path, double t) {
  final metrics = path.computeMetrics().toList();
  final total = metrics.fold<double>(0, (s, m) => s + m.length);
  var target = total * t.clamp(0.0, 1.0);
  for (final m in metrics) {
    if (target <= m.length) return m.getTangentForOffset(target);
    target -= m.length;
  }
  return metrics.isEmpty
      ? null
      : metrics.last.getTangentForOffset(metrics.last.length);
}

/// Extracts the sub-path AFTER fraction [from] (the remaining route).
Path _remainingPath(Path path, double from) {
  final metrics = path.computeMetrics().toList();
  final total = metrics.fold<double>(0, (s, m) => s + m.length);
  var skip = total * from.clamp(0.0, 1.0);
  final out = Path();
  for (final m in metrics) {
    if (skip >= m.length) {
      skip -= m.length;
      continue;
    }
    out.addPath(m.extractPath(skip, m.length), Offset.zero);
    skip = 0;
  }
  return out;
}

// ============================================================
// Map painter — Google-Maps-style light map
// ============================================================
class _MapUiPainter extends CustomPainter {
  final List<Offset> routeAnchors;
  final List<Offset> approachAnchors;
  final double mainProgress;
  final double approachProgress;
  final bool showApproach;
  final bool showMainRoute;

  _MapUiPainter({
    required this.routeAnchors,
    required this.approachAnchors,
    required this.mainProgress,
    required this.approachProgress,
    required this.showApproach,
    required this.showMainRoute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _MapUiScreenState.mapBg);

    void road(Offset a, Offset b, double w) {
      final pa = Offset(a.dx * size.width, a.dy * size.height);
      final pb = Offset(b.dx * size.width, b.dy * size.height);
      canvas.drawLine(pa, pb,
          Paint()..color = _MapUiScreenState.roadCasing..strokeWidth = w + 4);
      canvas.drawLine(pa, pb,
          Paint()..color = _MapUiScreenState.roadFill..strokeWidth = w);
    }

    void minorRoad(Offset a, Offset b) {
      final pa = Offset(a.dx * size.width, a.dy * size.height);
      final pb = Offset(b.dx * size.width, b.dy * size.height);
      canvas.drawLine(pa, pb,
          Paint()..color = _MapUiScreenState.roadFill..strokeWidth = 6);
    }

    // Major roads (white with casing)
    road(const Offset(0, 0.107), const Offset(1, 0.107), 11);
    road(const Offset(0, 0.302), const Offset(1, 0.302), 13);
    road(const Offset(0, 0.486), const Offset(1, 0.486), 10);
    road(const Offset(0, 0.717), const Offset(1, 0.717), 11);
    road(const Offset(0.141, 0), const Offset(0.141, 1), 10);
    road(const Offset(0.474, 0), const Offset(0.474, 1), 13);
    road(const Offset(0.846, 0), const Offset(0.846, 1), 16);
    road(const Offset(0, 0.901), const Offset(1, 0.664), 14);

    // Minor roads
    minorRoad(const Offset(0, 0.178), const Offset(1, 0.178));
    minorRoad(const Offset(0, 0.391), const Offset(1, 0.391));
    minorRoad(const Offset(0, 0.592), const Offset(1, 0.592));
    minorRoad(const Offset(0.308, 0), const Offset(0.308, 1));
    minorRoad(const Offset(0.667, 0), const Offset(0.667, 1));

    // Blocks (beige with white outline; a few parks)
    final blocks = <List<double>>[
      [0.026, 0.018, 0.087, 0.065], [0.179, 0.018, 0.244, 0.065],
      [0.513, 0.018, 0.115, 0.065], [0.692, 0.018, 0.115, 0.071],
      [0.026, 0.124, 0.087, 0.030], [0.179, 0.118, 0.244, 0.036],
      [0.513, 0.118, 0.115, 0.036], [0.885, 0.018, 0.090, 0.071],
      [0.885, 0.118, 0.090, 0.036], [0.026, 0.201, 0.087, 0.077],
      [0.179, 0.196, 0.103, 0.083], [0.333, 0.196, 0.115, 0.083],
      [0.885, 0.196, 0.090, 0.083], [0.026, 0.320, 0.087, 0.053],
      [0.179, 0.320, 0.103, 0.053], [0.333, 0.320, 0.115, 0.053],
      [0.513, 0.320, 0.115, 0.053], [0.885, 0.320, 0.090, 0.053],
      [0.026, 0.409, 0.087, 0.059], [0.179, 0.409, 0.103, 0.059],
      [0.513, 0.409, 0.115, 0.059], [0.692, 0.409, 0.115, 0.059],
      [0.026, 0.503, 0.087, 0.071], [0.333, 0.503, 0.115, 0.071],
      [0.513, 0.503, 0.115, 0.071], [0.692, 0.503, 0.115, 0.071],
      [0.885, 0.503, 0.090, 0.071], [0.026, 0.610, 0.087, 0.083],
      [0.179, 0.610, 0.103, 0.083], [0.513, 0.610, 0.115, 0.083],
      [0.692, 0.610, 0.115, 0.083], [0.885, 0.610, 0.090, 0.083],
    ];
    final parkIdx = {3, 9, 15, 24};
    final outline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(b[0] * size.width, b[1] * size.height,
            b[2] * size.width, b[3] * size.height),
        const Radius.circular(2),
      );
      canvas.drawRRect(
          r,
          Paint()
            ..color = parkIdx.contains(i)
                ? _MapUiScreenState.park
                : (i.isEven ? _MapUiScreenState.blockA : _MapUiScreenState.blockB));
      canvas.drawRRect(r, outline);
    }

    // Street name rotated along the big vertical road
    final tp = TextPainter(
      text: const TextSpan(
        text: 'R. Jose Ricardo',
        style: TextStyle(
            color: _MapUiScreenState.streetLabel,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(size.width * 0.867, size.height * 0.355);
    canvas.rotate(88 * math.pi / 180);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();

    // Blue place label
    final place = TextPainter(
      text: const TextSpan(
        text: 'cado Brasil\npical (Arroios)',
        style: TextStyle(
            color: _MapUiScreenState.placeLabel,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    place.paint(canvas, Offset(size.width * 0.036, size.height * 0.532));

    // Routes: only the REMAINING path is drawn, solid black (Uber style)
    final routePaint = Paint()
      ..color = _MapUiScreenState.routeBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (showApproach) {
      final ap = _pathFrom(approachAnchors, size);
      canvas.drawPath(_remainingPath(ap, approachProgress), routePaint);
    }
    if (showMainRoute) {
      final mp = _pathFrom(routeAnchors, size);
      canvas.drawPath(_remainingPath(mp, mainProgress), routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapUiPainter old) =>
      old.mainProgress != mainProgress ||
      old.approachProgress != approachProgress ||
      old.showApproach != showApproach ||
      old.showMainRoute != showMainRoute;
}

// ============================================================
// Positioning helpers
// ============================================================
class _MarkerAt extends StatelessWidget {
  final Offset point; // normalized 0..1
  final double dx, dy;
  final Widget child;
  const _MarkerAt({required this.point, required this.child, this.dx = 0, this.dy = 0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = c.biggest;
      return Stack(children: [
        Positioned(
          left: point.dx * size.width + dx,
          top: point.dy * size.height + dy,
          child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5), child: child),
        ),
      ]);
    });
  }
}

class _RouteFollower extends StatelessWidget {
  final List<Offset> anchors;
  final double t;
  final Widget Function(BuildContext, double angle) builder;
  const _RouteFollower(
      {required this.anchors, required this.t, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = c.biggest;
      final tangent = _tangentAt(_pathFrom(anchors, size), t);
      if (tangent == null) return const SizedBox.shrink();
      return Stack(children: [
        Positioned(
          left: tangent.position.dx,
          top: tangent.position.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: builder(context, -tangent.angle),
          ),
        ),
      ]);
    });
  }
}

// ============================================================
// Small widgets
// ============================================================
class _MapPill extends StatelessWidget {
  final String label;
  final bool small;
  const _MapPill({required this.label, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 12 : 14, vertical: small ? 6 : 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Text(label,
          style: TextStyle(
              color: const Color(0xFF111111),
              fontSize: small ? 12 : 13,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _RadarRings extends StatelessWidget {
  final double progress;
  final Color color;
  const _RadarRings({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(3, (i) {
          final localT = (progress + i / 3) % 1.0;
          return Opacity(
            opacity: (1 - localT) * 0.55,
            child: Transform.scale(
              scale: 0.5 + localT * 3.4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF18181B), size: 18),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  final Color color;
  const _LiveBadge({required this.color});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.25).animate(_c),
            child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: widget.color, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 6),
          const Text('LIVE',
              style: TextStyle(
                  color: Color(0xFF18181B),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4)),
        ],
      ),
    );
  }
}

// ============================================================
// Googer dark bottom sheet
// ============================================================
class _StatusSheet extends StatelessWidget {
  final DeliveryPhase phase;
  final int etaMin;
  final double driveT;
  final Animation<double> searchAnim;
  final Animation<double> veggieAnim;
  final String riderName;
  final double riderRating;
  final String vehiclePlate;
  final RiderVehicleType vehicleType;

  const _StatusSheet({
    required this.phase,
    required this.etaMin,
    required this.driveT,
    required this.searchAnim,
    required this.veggieAnim,
    required this.riderName,
    required this.riderRating,
    required this.vehiclePlate,
    required this.vehicleType,
  });

  String get _title {
    switch (phase) {
      case DeliveryPhase.placed:
      case DeliveryPhase.toRestaurant:
        return 'Preparing your order';
      case DeliveryPhase.pickedUp:
        return 'Rider picked up your order';
      case DeliveryPhase.onTheWay:
        return 'Almost here!';
      case DeliveryPhase.delivered:
        return 'Delivered!';
    }
  }

  String get _subtitle {
    switch (phase) {
      case DeliveryPhase.placed:
        return 'The kitchen just started cooking';
      case DeliveryPhase.toRestaurant:
        return 'Rider is heading to the restaurant';
      case DeliveryPhase.pickedUp:
        return 'Heading your way shortly';
      case DeliveryPhase.onTheWay:
        return 'Rider is on the way to you';
      case DeliveryPhase.delivered:
        return 'Enjoy your order';
    }
  }

  String get _eta {
    switch (phase) {
      case DeliveryPhase.placed:
        return '—';
      case DeliveryPhase.toRestaurant:
        return '12 MIN';
      case DeliveryPhase.pickedUp:
        return '9 MIN';
      case DeliveryPhase.onTheWay:
        return etaMin <= 0 ? '<1 MIN' : '$etaMin MIN';
      case DeliveryPhase.delivered:
        return '0 MIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = _MapUiScreenState.accent;
    const accentLight = _MapUiScreenState.accentLight;
    const fgMute = _MapUiScreenState.fgMute;
    const fgFaint = _MapUiScreenState.fgFaint;

    final isPlaced = phase == DeliveryPhase.placed;
    final isToRestaurant = phase == DeliveryPhase.toRestaurant;
    final isDelivered = phase == DeliveryPhase.delivered;
    final isOnWay = phase == DeliveryPhase.onTheWay;
    final showRiderCard =
        phase == DeliveryPhase.pickedUp || isOnWay || isDelivered;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: _MapUiScreenState.bg1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 50,
              offset: const Offset(0, -20)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999))),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(_subtitle,
                        style: const TextStyle(
                            color: fgMute,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  border: Border.all(color: accent.withValues(alpha: 0.20)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Column(
                  children: [
                    const Text('ETA',
                        style: TextStyle(
                            color: accentLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4)),
                    const SizedBox(height: 2),
                    Text(_eta,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _segment(
                      filled: !isPlaced, active: isPlaced, sweep: true)),
              const SizedBox(width: 6),
              Expanded(
                  child: _segment(
                      filled: showRiderCard,
                      active: isToRestaurant,
                      sweep: true)),
              const SizedBox(width: 6),
              Expanded(
                  child: _segment(
                      filled: isDelivered,
                      active: isOnWay,
                      fillFactor: driveT)),
            ],
          ),
          const SizedBox(height: 16),
          if (isPlaced || isToRestaurant)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: veggieAnim,
                    builder: (context, _) {
                      Widget hop(IconData icon, double phaseOffset) {
                        final local = (veggieAnim.value + phaseOffset) % 1.0;
                        final lift = math.sin(local * math.pi) * 8;
                        return Transform.translate(
                            offset: Offset(0, -lift),
                            child: Icon(icon, color: accent, size: 22));
                      }

                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        hop(Icons.eco_outlined, 0.0),
                        const SizedBox(width: 6),
                        hop(Icons.local_pizza_outlined, 0.17),
                        const SizedBox(width: 6),
                        hop(Icons.restaurant_outlined, 0.34),
                      ]);
                    },
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('The kitchen is preparing your order.',
                        style:
                            TextStyle(color: fgMute, fontSize: 13, height: 1.5)),
                  ),
                ],
              ),
            ),
          if (isPlaced)
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: Color(0xFF121212), shape: BoxShape.circle),
                  child: const Icon(Icons.search, color: accent, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                      'Matching you with the closest available rider nearby.',
                      style:
                          TextStyle(color: fgMute, fontSize: 13, height: 1.5)),
                ),
              ],
            )
          else if (isToRestaurant)
            Row(
              children: const [
                Icon(Icons.navigation_outlined, color: accent, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Rider is heading to the restaurant to collect your order.',
                      style: TextStyle(color: fgMute, fontSize: 12)),
                ),
              ],
            )
          else if (showRiderCard)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF111114),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10)),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(riderName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            Icon(Icons.star,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 11),
                            const SizedBox(width: 2),
                            Text('$riderRating',
                                style: const TextStyle(
                                    color: fgMute,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (vehicleType == RiderVehicleType.car ? 'Car' : 'Bike') + ' • ' + vehiclePlate,
                          style: const TextStyle(
                              color: fgFaint,
                              fontSize: 11,
                              fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  _circleBtn(Icons.call_outlined, Colors.transparent),
                  const SizedBox(width: 8),
                  _circleBtn(Icons.chat_bubble_outline, accent),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _segment(
      {required bool filled,
      required bool active,
      bool sweep = false,
      double fillFactor = 0}) {
    const accent = _MapUiScreenState.accent;
    const accentLight = _MapUiScreenState.accentLight;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(color: filled ? accent : const Color(0xFF2A2A30)),
            if (active && sweep)
              AnimatedBuilder(
                animation: searchAnim,
                builder: (_, __) => Align(
                  alignment: Alignment(-1 + 2.8 * searchAnim.value, 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [accent, accentLight]),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            if (active && !sweep)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fillFactor.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: [accent, accentLight]),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color bg) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg == Colors.transparent ? Colors.transparent : bg,
          shape: BoxShape.circle,
          border:
              bg == Colors.transparent ? Border.all(color: Colors.white24) : null,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      );
}
