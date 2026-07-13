# Map UI — Flutter drop-in (NicoMart rider tracking)

Uber-style live tracking screen matching the approved design exactly:

- **Google-Maps-style light map** — cream canvas, white roads with soft
  casings, beige building blocks with white outlines, green parks, rotated
  street name, blue place label.
- **Solid black route** — only the remaining path ahead of the rider is
  drawn (Uber behavior), with round caps/joins.
- **Black rounded-rect vehicle marker** that follows the route and rotates
  to its heading.
- **White map pills** — "Pickup spot", live "0.x miles", "You".
- **Full Uber lifecycle** — Order placed (kitchen preparing + radar rider
  matching) → rider drives TO the restaurant while food preps → pickup (bag
  bounce) → drive to customer → Delivered overlay. Loops for demo.
- **Googer dark bottom sheet** — ETA pill, 3-segment progress, veggie-hop
  preparing animation, rider card with call/chat.

## Install

1. Copy `lib/map_ui_screen.dart` into your `nicomart-LK/lib/`.
2. No extra packages — pure Flutter (`dart:math` + Material).
3. Navigate to it:

```dart
import 'map_ui_screen.dart';

Navigator.push(context, MaterialPageRoute(
  builder: (_) => const MapUiScreen(
    vehicleType: RiderVehicleType.bike, // or .car
    riderName: 'Kasun Perera',
    riderRating: 4.9,
    vehiclePlate: 'WP CAB-4521',
  ),
));
```

## Wiring real data

The lifecycle is simulated with timers/tickers so the file runs standalone.
For production:

- Drive `_phase` from your Firestore/socket order-status stream instead of
  `_cycle()` timers.
- Feed rider GPS progress (0..1 along the polyline) into `_ta` (approach
  leg) and `_t` (delivery leg).
- Replace `_approachAnchors` / `_routeAnchors` with your decoded
  Directions API polylines (normalized to 0..1 view space), or swap the
  painted map for `google_maps_flutter` and keep the sheet + markers.
