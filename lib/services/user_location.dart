import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's delivery location (GPS-detected or manually chosen).
class UserLocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String city;

  const UserLocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

/// One town we deliver in: a centre point and a serving radius.
class ServiceArea {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;

  const ServiceArea(this.name, this.latitude, this.longitude,
      {this.radiusKm = 8});
}

/// Holds the app-wide user location, persists it, and answers whether the
/// user is inside our Sri Lanka service area.
class UserLocation {
  UserLocation._();

  static const _prefsKeyLat = 'user_location_lat';
  static const _prefsKeyLng = 'user_location_lng';
  static const _prefsKeyAddress = 'user_location_address';
  static const _prefsKeyCity = 'user_location_city';

  /// Towns we currently serve (North-Western Sri Lanka).
  static const List<ServiceArea> serviceAreas = [
    ServiceArea('Kuliyapitiya', 7.4696, 80.0403),
    ServiceArea('Udubaddawa', 7.4176, 79.9917),
    ServiceArea('Nattandiya', 7.4083, 79.8673),
    ServiceArea('Marawila', 7.4198, 79.8281),
    ServiceArea('Wennappuwa', 7.3491, 79.8442),
    ServiceArea('Dummalasuriya', 7.3861, 79.9096),
  ];

  /// Current location; UI listens to this to rebuild.
  static final ValueNotifier<UserLocationData?> current = ValueNotifier(null);

  /// True when we have a location and it is NOT inside any service area.
  static bool get outsideServiceArea {
    final loc = current.value;
    if (loc == null) return false;
    return !isInServiceArea(loc.latitude, loc.longitude);
  }

  static bool isInServiceArea(double lat, double lng) {
    for (final area in serviceAreas) {
      if (_distanceKm(lat, lng, area.latitude, area.longitude) <=
          area.radiusKm) {
        return true;
      }
    }
    return false;
  }

  /// Loads the saved location; when none is saved, tries GPS detection
  /// (asking for permission on first run).
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_prefsKeyLat);
    final lng = prefs.getDouble(_prefsKeyLng);
    if (lat != null && lng != null) {
      current.value = UserLocationData(
        latitude: lat,
        longitude: lng,
        address: prefs.getString(_prefsKeyAddress) ?? '',
        city: prefs.getString(_prefsKeyCity) ?? '',
      );
      return;
    }
    await detectCurrentLocation();
  }

  /// Requests permission (first launch) and resolves the GPS position into
  /// an address + city. Returns false when permission is denied or GPS fails.
  static Future<bool> detectCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));

      String address = '';
      String city = '';
      try {
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city = (p.locality?.isNotEmpty == true
                  ? p.locality
                  : p.subAdministrativeArea) ??
              '';
          address = [p.street, p.locality, p.administrativeArea]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
        }
      } catch (_) {
        // Keep coordinates even when reverse geocoding fails.
      }

      await save(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: city,
      );
      return true;
    } catch (e) {
      debugPrint('detectCurrentLocation failed: $e');
      return false;
    }
  }

  /// Saves a (possibly manually chosen) location and notifies listeners.
  static Future<void> save({
    required double latitude,
    required double longitude,
    required String address,
    String? city,
  }) async {
    var resolvedCity = city ?? '';
    if (resolvedCity.isEmpty) {
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          resolvedCity = (p.locality?.isNotEmpty == true
                  ? p.locality
                  : p.subAdministrativeArea) ??
              '';
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKeyLat, latitude);
    await prefs.setDouble(_prefsKeyLng, longitude);
    await prefs.setString(_prefsKeyAddress, address);
    await prefs.setString(_prefsKeyCity, resolvedCity);

    current.value = UserLocationData(
      latitude: latitude,
      longitude: longitude,
      address: address,
      city: resolvedCity,
    );
  }

  static double _distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLng = (lng2 - lng1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadiusKm * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
