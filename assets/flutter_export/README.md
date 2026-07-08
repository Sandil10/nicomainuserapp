# Rider Tracking Map — Flutter drop-in

Real-time-style delivery tracking screen for the NicoMart app: white/light
map with black roads (matches real map apps), animated purple route line,
a bike/car marker that walks the restaurant → customer path, and a Googer
dark bottom sheet cycling **Finding rider → Picked up → On the way →
Delivered**.

## Install

1. Copy `lib/rider_tracking_map_screen.dart` into your `nicomart-LK/lib/`
   folder.
2. No extra packages required — it only uses Flutter's `dart:math` and
   `material.dart`. (Your existing `order_status_screen.dart` already
   depends on `google_maps_flutter` / `cloud_firestore` for the real map —
   this file is independent of those.)
3. Push it like any screen:

```dart
import 'rider_tracking_map_screen.dart';

Navigator.push(context, MaterialPageRoute(
  builder: (_) => const RiderTrackingMapScreen(
    vehicleType: RiderVehicleType.bike, // or .car
    riderName: 'Kasun Perera',
    riderRating: 4.9,
    vehiclePlate: 'WP CAB-4521',
    restaurantName: 'Nico Kitchen',
  ),
));
```

## What's simulated vs. real

Out of the box this file **simulates** the delivery lifecycle with timers so
it's runnable standalone (finding rider ~2.2s → picked up ~1.2s → drive
~7s → delivered, then loops). To wire it to your real backend:

- Swap `_runLifecycle()` / `_drive()` for listeners on your existing
  Firestore order doc (same fields `order_status_screen.dart` already
  reads: `finding_rider`, `picked_up`, `on_the_way`, delivered).
- Feed live rider lat/lng into `_routeT` (0..1 progress along the route) by
  projecting the rider's GPS point onto your Directions polyline, same as
  the existing `_riderLatLng` / `_routePoints` logic already does.
- `_routeAnchors` is a placeholder path in 0..1 widget-space. Replace with
  your decoded polyline points normalized to the map view, or keep using
  `google_maps_flutter` for the real map and reuse just the
  `_BottomSheet` widget + `DeliveryPhase` enum from this file for the UI.

## Design notes

- Map surface: light background (`#E9EDF1`), black/near-black roads
  (`#26282C`), gray minor streets, soft park/block fills — a realistic map
  look, distinct from the rest of the app's black chrome.
- Route + rider marker: Googer purple (`#A855F7`), matching `--accent`.
- Bottom sheet, ETA pill, progress bar, rider card: Googer dark chrome
  card tokens (`--bg-1` `#18181B`, `--bg-3` `#1E1E24`), 800/900 weight
  type, uppercase wide-tracking micro-labels — consistent with the rest of
  the design system.
