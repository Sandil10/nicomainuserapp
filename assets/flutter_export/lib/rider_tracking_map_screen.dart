// rider_tracking_map_screen.dart
//
// Drop-in real-time rider tracking screen for the NicoMart Flutter app,
// styled to match the Googer design system (dark chrome, purple accent
// #A855F7, Geist-style weight hierarchy) with a light "real map" surface
// (white base + black roads) like Uber/mainstream map apps.
//
// This is a self-contained simulation (no Google Maps SDK dependency) so it
// drops into any Flutter project immediately. To wire it to real data:
//   - Replace `_RiderTrackingController._cycle/_drive` with Firestore/HTTP
//     listeners that update `riderProgress` (0..1 along the route) and
//     `phase` from your backend / order_status_screen.dart equivalents.
//   - Replace `_routePath` (a Path built from fixed points) with your
//     decoded Directions API polyline, mapped into local widget space, or
//     keep using google_maps_flutter and just reuse the bottom sheet +
//     state machine below.
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const RiderTrackingMapScreen(
//       vehicleType: RiderVehicleType.bike,
//       riderName: 'Kasun Perera',
//       riderRating: 4.9,
//       vehiclePlate: 'WP CAB-4521',
//       restaurantName: 'Nico Kitchen',
//     ),
//   ));

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Vehicle used by the assigned rider. Swaps the marker icon + label.
enum RiderVehicleType { bike, car }

/// Delivery lifecycle. Mirrors the statuses used in order_status_screen.dart
/// (finding_rider / picked_up / on_the_way / delivered).
enum DeliveryPhase { findingRider, pickedUp, onTheWay, delivered }

class RiderTrackingMapScreen extends StatefulWidget {
  final RiderVehicleType vehicleType;
  final String riderName;
  final double riderRating;
  final String vehiclePlate;
  final String restaurantName;

  /// How long (seconds) the simulated drive from restaurant to door takes.
  /// Wire a real feed by driving `controller.setProgress(...)` instead and
  /// ignoring this.
  final int simulatedDriveSeconds;

  const RiderTrackingMapScreen({
    super.key,
    this.vehicleType = RiderVehicleType.bike,
    this.riderName = 'Kasun Perera',
    this.riderRating = 4.9,
    this.vehiclePlate = 'WP CAB-4521',
    this.restaurantName = 'Nico Kitchen',
    this.simulatedDriveSeconds = 7,
  });

  @override
  State<RiderTrackingMapScreen> createState() =>
      _RiderTrackingMapScreenState();
}

class _RiderTrackingMapScreenState extends State<RiderTrackingMapScreen>
    with TickerProviderStateMixin {
  // ---- Googer design tokens (see colors_and_type.css) ----
  static const _bg0 = Color(0xFF000000);
  static const _bg1 = Color(0xFF18181B);
  static const _bg3 = Color(0xFF1E1E24);
  static const _accent = Color(0xFFA855F7);
  static const _accentLight = Color(0xFFC084FC);
  static const _success = Color(0xFF22C55E);
  static const _like = Color(0xFFEF4444);
  static const _fgMute = Color(0xFFA1A1AA);
  static const _fgFaint = Color(0xFF71717A);

  // Map surface stays light ("real map" look) even though chrome is dark.
  static const _mapBg = Color(0xFFE9EDF1);
  static const _roadMajor = Color(0xFF26282C);
  static const _roadMinor = Color(0xFFC4CBD2);
  static const _block = Color(0xFFDDE1E5);
  static const _park = Color(0xFFC9E6CD);

  DeliveryPhase _phase = DeliveryPhase.findingRider;
  double _routeT = 0; // 0..1 progress from restaurant to destination
  int _etaMin = 9;

  Timer? _phaseTimer;
  Ticker? _driveTicker;
  Duration? _driveStart;

  late final AnimationController _radarController;
  late final AnimationController _bagBounceController;
  late final AnimationController _searchBarController;
  late final AnimationController _checkPopController;

  // Normalized (0..1 space, scaled to canvas at build time) route control
  // points — a simple curved street path from the restaurant (top-right)
  // down to the customer (bottom-left). Swap for a real decoded polyline.
  static const List<Offset> _routeAnchors = [
    Offset(0.846, 0.071), // restaurant
    Offset(0.800, 0.124),
    Offset(0.769, 0.166),
    Offset(0.756, 0.207), // end of "restaurant leg" (~30% of path)
    Offset(0.577, 0.308),
    Offset(0.308, 0.438),
    Offset(0.231, 0.509), // destination
  ];

  @override
  void initState() {
    super.initState();
    _radarController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
          ..repeat();
    _bagBounceController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..repeat(reverse: true);
    _searchBarController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
          ..repeat(reverse: true);
    _checkPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _runLifecycle();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _driveTicker?.dispose();
    _radarController.dispose();
    _bagBounceController.dispose();
    _searchBarController.dispose();
    _checkPopController.dispose();
    super.dispose();
  }

  // ---- Simulated state machine — replace with real backend events ----
  void _runLifecycle() {
    setState(() {
      _phase = DeliveryPhase.findingRider;
      _routeT = 0;
      _etaMin = 9;
    });
    _phaseTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _phase = DeliveryPhase.pickedUp);
      _phaseTimer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        _drive();
      });
    });
  }

  void _drive() {
    setState(() => _phase = DeliveryPhase.onTheWay);
    _driveStart = null;
    _driveTicker = createTicker((elapsed) {
      _driveStart ??= elapsed;
      final seconds = widget.simulatedDriveSeconds.clamp(1, 60);
      final t = ((elapsed - _driveStart!).inMilliseconds / (seconds * 1000))
          .clamp(0.0, 1.0);
      setState(() {
        _routeT = t;
        _etaMin = ((1 - t) * 9).round();
      });
      if (t >= 1.0) {
        _driveTicker?.stop();
        _phaseTimer = Timer(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() => _phase = DeliveryPhase.delivered);
          _checkPopController.forward(from: 0);
          _phaseTimer = Timer(const Duration(milliseconds: 2800), () {
            if (!mounted) return;
            _checkPopController.reset();
            _runLifecycle();
          });
        });
      }
    })
      ..start();
  }

  /// Fraction of the whole route that is the "restaurant leg" (rider walks
  /// out of frame before driving); matches the HTML reference's ~30% mark.
  static const double _restaurantLegT = 0.30;

  double get _combinedT {
    switch (_phase) {
      case DeliveryPhase.findingRider:
        return 0;
      case DeliveryPhase.pickedUp:
        return _restaurantLegT;
      case DeliveryPhase.onTheWay:
        return _restaurantLegT + _routeT * (1 - _restaurantLegT);
      case DeliveryPhase.delivered:
        return 1;
    }
  }

  bool get _showRider => _phase != DeliveryPhase.findingRider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg0,
      body: Stack(
        children: [
          // ---- Map surface (white/light, black roads) ----
          Positioned.fill(
            child: CustomPaint(
              painter: _MapPainter(
                mapBg: _mapBg,
                roadMajor: _roadMajor,
                roadMinor: _roadMinor,
                block: _block,
                park: _park,
                routeAnchors: _routeAnchors,
                routeProgress: _combinedT,
                accent: _accent,
              ),
            ),
          ),

          // ---- Radar pulse around restaurant while finding rider ----
          if (_phase == DeliveryPhase.findingRider)
            _AnimatedMarkerOverlay(
              anchors: _routeAnchors,
              t: 0,
              builder: (context, size) => AnimatedBuilder(
                animation: _radarController,
                builder: (context, _) => _RadarRings(
                  progress: _radarController.value,
                  color: _accent,
                ),
              ),
            ),

          // Restaurant pin + label
          _AnimatedMarkerOverlay(
            anchors: _routeAnchors,
            t: 0,
            builder: (context, size) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 3),
                    boxShadow: [
                      BoxShadow(color: _accent.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white, size: 16),
                ),
                const SizedBox(height: 4),
                _Chip(label: widget.restaurantName, dark: false),
              ],
            ),
          ),

          // Bag bounce while just picked up
          if (_phase == DeliveryPhase.pickedUp)
            _AnimatedMarkerOverlay(
              anchors: _routeAnchors,
              t: 0,
              offsetY: -44,
              builder: (context, size) => AnimatedBuilder(
                animation: _bagBounceController,
                builder: (context, _) => Transform.translate(
                  offset: Offset(0, -6 * _bagBounceController.value),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.shopping_bag, color: Color(0xFF0A0A0A), size: 15),
                  ),
                ),
              ),
            ),

          // Destination pin + label
          _AnimatedMarkerOverlay(
            anchors: _routeAnchors,
            t: 1,
            offsetY: -30,
            builder: (context, size) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Color(0xFF18181B), size: 34),
                const SizedBox(height: 2),
                const _Chip(label: 'You', dark: false),
              ],
            ),
          ),

          // Rider marker (bike/car), follows the route with rotation
          if (_showRider)
            _AnimatedMarkerOverlay(
              anchors: _routeAnchors,
              t: _combinedT,
              rotate: true,
              builder: (context, size) => Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 3),
                  boxShadow: [
                    BoxShadow(color: _accent.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Icon(
                  widget.vehicleType == RiderVehicleType.car
                      ? Icons.directions_car
                      : Icons.pedal_bike,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundIconButton(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.maybePop(context)),
                  _LiveBadge(color: _like),
                ],
              ),
            ),
          ),

          // Bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomSheet(
              phase: _phase,
              etaMin: _etaMin,
              routeProgressWithinLeg: _routeT,
              searchAnim: _searchBarController,
              riderName: widget.riderName,
              riderRating: widget.riderRating,
              vehiclePlate: widget.vehiclePlate,
              vehicleType: widget.vehicleType,
              bg1: _bg1,
              bg3: _bg3,
              accent: _accent,
              accentLight: _accentLight,
              fgMute: _fgMute,
              fgFaint: _fgFaint,
            ),
          ),

          // Delivered overlay
          if (_phase == DeliveryPhase.delivered)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _checkPopController,
                builder: (context, _) {
                  final pop = Curves.elasticOut.transform(_checkPopController.value.clamp(0, 1));
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
                              decoration: const BoxDecoration(color: _success, shape: BoxShape.circle),
                              child: const Icon(Icons.check, color: Colors.white, size: 52),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Delivered',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text('Enjoy your order', style: TextStyle(color: _fgMute, fontSize: 13)),
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
// Map painter — white/light base, black roads, faint route base + solid
// progress overlay drawn as a rounded, dashed-to-solid stroke.
// ============================================================
class _MapPainter extends CustomPainter {
  final Color mapBg, roadMajor, roadMinor, block, park, accent;
  final List<Offset> routeAnchors;
  final double routeProgress; // 0..1

  _MapPainter({
    required this.mapBg,
    required this.roadMajor,
    required this.roadMinor,
    required this.block,
    required this.park,
    required this.routeAnchors,
    required this.routeProgress,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = mapBg);

    void hLine(double yFrac, double w, Color c) {
      canvas.drawLine(Offset(0, size.height * yFrac), Offset(size.width, size.height * yFrac),
          Paint()..color = c..strokeWidth = w);
    }

    void vLine(double xFrac, double w, Color c) {
      canvas.drawLine(Offset(size.width * xFrac, 0), Offset(size.width * xFrac, size.height),
          Paint()..color = c..strokeWidth = w);
    }

    // Major roads (black)
    hLine(0.107, 9, roadMajor);
    hLine(0.302, 10, roadMajor);
    hLine(0.486, 8, roadMajor);
    hLine(0.717, 9, roadMajor);
    vLine(0.141, 8, roadMajor);
    vLine(0.474, 10, roadMajor);
    vLine(0.846, 7, roadMajor);
    canvas.drawLine(Offset(0, size.height * 0.901), Offset(size.width, size.height * 0.664),
        Paint()..color = roadMajor..strokeWidth = 12);

    // Minor roads (gray)
    hLine(0.178, 4, roadMinor);
    hLine(0.391, 4, roadMinor);
    hLine(0.592, 4, roadMinor);
    vLine(0.308, 4, roadMinor);
    vLine(0.667, 4, roadMinor);

    // City blocks
    final blockRects = <Rect>[
      Rect.fromLTWH(0.026 * size.width, 0.018 * size.height, 0.087 * size.width, 0.065 * size.height),
      Rect.fromLTWH(0.179 * size.width, 0.018 * size.height, 0.244 * size.width, 0.065 * size.height),
      Rect.fromLTWH(0.513 * size.width, 0.018 * size.height, 0.115 * size.width, 0.065 * size.height),
      Rect.fromLTWH(0.692 * size.width, 0.018 * size.height, 0.115 * size.width, 0.071 * size.height),
      Rect.fromLTWH(0.026 * size.width, 0.201 * size.height, 0.087 * size.width, 0.077 * size.height),
      Rect.fromLTWH(0.179 * size.width, 0.196 * size.height, 0.103 * size.width, 0.083 * size.height),
      Rect.fromLTWH(0.333 * size.width, 0.196 * size.height, 0.115 * size.width, 0.083 * size.height),
      Rect.fromLTWH(0.026 * size.width, 0.320 * size.height, 0.087 * size.width, 0.053 * size.height),
      Rect.fromLTWH(0.333 * size.width, 0.320 * size.height, 0.115 * size.width, 0.053 * size.height),
      Rect.fromLTWH(0.513 * size.width, 0.503 * size.height, 0.115 * size.width, 0.071 * size.height),
      Rect.fromLTWH(0.692 * size.width, 0.503 * size.height, 0.115 * size.width, 0.071 * size.height),
    ];
    final parkIdx = {0, 4, 8};
    for (var i = 0; i < blockRects.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(blockRects[i], const Radius.circular(3)),
        Paint()..color = parkIdx.contains(i) ? park : block,
      );
    }

    // Route path from anchors (quadratic-ish smoothing through points)
    final path = Path();
    final pts = routeAnchors.map((o) => Offset(o.dx * size.width, o.dy * size.height)).toList();
    path.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    // Faint full-route base
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Solid progress overlay up to routeProgress
    final metrics = path.computeMetrics().toList();
    final totalLen = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final target = totalLen * routeProgress.clamp(0.0, 1.0);
    double consumed = 0;
    final progressPath = Path();
    for (final m in metrics) {
      if (consumed >= target) break;
      final remaining = target - consumed;
      final take = math.min(remaining, m.length);
      progressPath.addPath(m.extractPath(0, take), Offset.zero);
      consumed += m.length;
    }
    canvas.drawPath(
      progressPath,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.routeProgress != routeProgress;
}

/// Computes a point (+ tangent angle) at fraction [t] along the route built
/// from [anchors], and positions [builder]'s child there. Used for pins,
/// pulses, and the moving rider marker.
class _AnimatedMarkerOverlay extends StatelessWidget {
  final List<Offset> anchors;
  final double t;
  final bool rotate;
  final double offsetY;
  final Widget Function(BuildContext, Size) builder;

  const _AnimatedMarkerOverlay({
    required this.anchors,
    required this.t,
    required this.builder,
    this.rotate = false,
    this.offsetY = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final pts = anchors.map((o) => Offset(o.dx * size.width, o.dy * size.height)).toList();
      final path = Path();
      path.moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final prev = pts[i - 1];
        final cur = pts[i];
        final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
        path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      }
      path.lineTo(pts.last.dx, pts.last.dy);

      final metrics = path.computeMetrics().toList();
      final totalLen = metrics.fold<double>(0, (sum, m) => sum + m.length);
      final target = (totalLen * t.clamp(0.0, 1.0));
      double consumed = 0;
      Offset pos = pts.first;
      double angle = 0;
      for (final m in metrics) {
        if (target <= consumed + m.length) {
          final tangent = m.getTangentForOffset(math.max(0, target - consumed));
          if (tangent != null) {
            pos = tangent.position;
            angle = tangent.angle;
          }
          break;
        }
        consumed += m.length;
        pos = metrics.last.getTangentForOffset(metrics.last.length)?.position ?? pos;
      }

      return Stack(
        children: [
          Positioned(
            left: pos.dx,
            top: pos.dy + offsetY,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: rotate ? Transform.rotate(angle: angle, child: builder(context, size)) : builder(context, size),
            ),
          ),
        ],
      );
    });
  }
}

class _RadarRings extends StatelessWidget {
  final double progress; // 0..1 looping
  final Color color;
  const _RadarRings({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(3, (i) {
          final localT = ((progress + i / 3) % 1.0);
          return Opacity(
            opacity: (1 - localT) * 0.55,
            child: Transform.scale(
              scale: 0.5 + localT * 3.4,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool dark;
  const _Chip({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 4))],
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

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.25).animate(_c),
            child: Container(width: 6, height: 6, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 6),
          const Text('LIVE',
              style: TextStyle(color: Color(0xFF18181B), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
        ],
      ),
    );
  }
}

// ============================================================
// Bottom sheet — Googer chrome card: title/subtitle, ETA pill, 3-segment
// progress bar, and either the "searching" row or the rider info card.
// ============================================================
class _BottomSheet extends StatelessWidget {
  final DeliveryPhase phase;
  final int etaMin;
  final double routeProgressWithinLeg;
  final Animation<double> searchAnim;
  final String riderName;
  final double riderRating;
  final String vehiclePlate;
  final RiderVehicleType vehicleType;
  final Color bg1, bg3, accent, accentLight, fgMute, fgFaint;

  const _BottomSheet({
    required this.phase,
    required this.etaMin,
    required this.routeProgressWithinLeg,
    required this.searchAnim,
    required this.riderName,
    required this.riderRating,
    required this.vehiclePlate,
    required this.vehicleType,
    required this.bg1,
    required this.bg3,
    required this.accent,
    required this.accentLight,
    required this.fgMute,
    required this.fgFaint,
  });

  String get _title {
    switch (phase) {
      case DeliveryPhase.findingRider:
        return 'Finding rider';
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
      case DeliveryPhase.findingRider:
        return 'Matching you with a nearby rider';
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
      case DeliveryPhase.findingRider:
        return '—';
      case DeliveryPhase.pickedUp:
        return '9 MIN';
      case DeliveryPhase.onTheWay:
        return (etaMin <= 0 ? '<1' : '$etaMin') + ' MIN';
      case DeliveryPhase.delivered:
        return '0 MIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final seg2Done = phase != DeliveryPhase.findingRider;
    final seg2Active = phase == DeliveryPhase.findingRider;
    final seg3Done = phase == DeliveryPhase.delivered;
    final seg3Active = phase == DeliveryPhase.onTheWay;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: bg1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 50, offset: const Offset(0, -20))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999))),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    Text(_subtitle, style: TextStyle(color: fgMute, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  border: Border.all(color: accent.withValues(alpha: 0.20)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Column(
                  children: [
                    Text('ETA', style: TextStyle(color: accentLight, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                    const SizedBox(height: 2),
                    Text(_eta, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _segment(filled: true)),
              const SizedBox(width: 6),
              Expanded(child: _segment(filled: true)),
              const SizedBox(width: 6),
              Expanded(
                child: _segment(
                  filled: seg2Done,
                  activeBuilder: seg2Active
                      ? (w) => AnimatedBuilder(
                            animation: searchAnim,
                            builder: (_, __) => Align(
                              alignment: Alignment(-1 + 2.8 * searchAnim.value, 0),
                              child: FractionallySizedBox(widthFactor: 0.4, child: _fillBar()),
                            ),
                          )
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _segment(
                  filled: seg3Done,
                  activeBuilder: seg3Active ? (w) => FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: routeProgressWithinLeg.clamp(0, 1), child: _fillBar()) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (phase == DeliveryPhase.findingRider)
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: Color(0xFF121212), shape: BoxShape.circle),
                  child: Icon(Icons.search, color: accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Matching you with the closest available rider nearby.',
                      style: TextStyle(color: fgMute, fontSize: 13, height: 1.5)),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bg3, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(Icons.person, color: accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(riderName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            Icon(Icons.star, color: Colors.white.withValues(alpha: 0.5), size: 11),
                            const SizedBox(width: 2),
                            Text('$riderRating', style: TextStyle(color: fgMute, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicleType == RiderVehicleType.car ? 'Car' : 'Bike'} • $vehiclePlate',
                          style: TextStyle(color: fgFaint, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  _circleBtn(Icons.call_outlined, Colors.transparent, Colors.white),
                  const SizedBox(width: 8),
                  _circleBtn(Icons.chat_bubble_outline, accent, Colors.white),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _fillBar() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent, accentLight]),
          borderRadius: BorderRadius.circular(999),
        ),
      );

  Widget _segment({required bool filled, Widget Function(Widget)? activeBuilder}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(color: filled ? accent : const Color(0xFF2A2A30)),
            if (activeBuilder != null) activeBuilder(const SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color bg, Color fg) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg == Colors.transparent ? Colors.transparent : bg,
          shape: BoxShape.circle,
          border: bg == Colors.transparent ? Border.all(color: Colors.white24) : null,
        ),
        child: Icon(icon, color: fg, size: 16),
      );
}
