import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'app_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'widgets/small_wave_loader.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({Key? key, this.initialLocation})
      : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _address = '';
  bool _isLoading = true;
  bool _isMoving = false;
  bool _isFetchingAddress = false;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];
  Timer? _debounce;
  final String _apiKey = 'AIzaSyBedirf6s8EnSButbonv6EWzAq7tqjmYns';

  final String _mapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "on"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#eeeeee"}]},
    {"featureType": "poi", "elementType": "labels.icon", "stylers": [{"visibility": "on"}]},
    {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#e5e5e5"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
    {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#dadada"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#c9c9c9"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    // Priority: 1. Passed initialLocation, 2. Last known position, 3. Real-time poll, 4. Fallback
    if (widget.initialLocation != null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedLocation = widget.initialLocation;
        });
        _getAddress(_selectedLocation!);
      }
      return;
    }

    try {
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null && mounted) {
        setState(() {
          _isLoading = false;
          _selectedLocation =
              LatLng(lastPosition.latitude, lastPosition.longitude);
        });
        _mapController
            ?.moveCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 17));
        _getAddress(_selectedLocation!);
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 1));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return _setFallbackLocation();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          return _setFallbackLocation();
      }

      if (permission == LocationPermission.deniedForever)
        return _setFallbackLocation();

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation, // Highest accuracy
        timeLimit: const Duration(seconds: 5), // Reduced timeout for speed
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
              _selectedLocation!, 18), // Deeper zoom for better precision
        );
        _getAddress(_selectedLocation!);
      }
    } catch (e) {
      debugPrint('Fast location fetch error: $e');
      if (mounted && _selectedLocation == null) {
        _setFallbackLocation();
      }
    }
  }

  void _setFallbackLocation() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedLocation =
            widget.initialLocation ?? const LatLng(6.9271, 79.8612);
      });
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
    }
  }

  Future<void> _getAddress(LatLng location) async {
    if (_isFetchingAddress) return;
    setState(() => _isFetchingAddress = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        String addr = '';
        if (place.street != null && place.street!.isNotEmpty)
          addr += '${place.street}, ';
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          addr += '${place.subLocality}, ';
        if (place.locality != null && place.locality!.isNotEmpty)
          addr += '${place.locality}';

        setState(() {
          _address = addr;
          _isFetchingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('Geocoding Error: $e');
      if (mounted) setState(() => _isFetchingAddress = false);
    }
  }

  // Search logic
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.length > 2) {
        _getSuggestions(value);
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  Future<void> _getSuggestions(String query) async {
    // Note: sessiontoken could be added to reduce costs, but we'll stick to basic for now
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_apiKey&components=country:lk';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _suggestions = data['predictions'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Places Autocomplete Error: $e');
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['place_id'];
    _searchController.clear();
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();

    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['result']['geometry']['location'];
        final lat = location['lat'];
        final lng = location['lng'];

        final newLocation = LatLng(lat, lng);
        _mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 17));

        setState(() {
          _selectedLocation = newLocation;
          _address = suggestion['description'];
        });
      }
    } catch (e) {
      debugPrint('Place Details Error: $e');
      // If Places Detail fails, fallback to geocoding
      try {
        List<Location> locations =
            await locationFromAddress(suggestion['description']);
        if (locations.isNotEmpty) {
          final newLoc = LatLng(locations[0].latitude, locations[0].longitude);
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLoc, 17));
          setState(() {
            _selectedLocation = newLoc;
            _address = suggestion['description'];
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset:
          false, // Prevents bottom pane from jumping up when keyboard appears
      appBar: AppBar(
        title: Text(
          AppLocalization.getText('selectLocation'),
          style: const TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: SmallWaveLoader(
                  color: Color(0xFF4A22A8))) // Switched to premium loader
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: _selectedLocation!, zoom: 17),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _mapController!
                        .setMapStyle(_mapStyle); // Set style immediately
                    // Small delay to ensure tiles are drawn before showing anything else
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) setState(() {});
                    });
                  },
                  onCameraMove: (position) {
                    _selectedLocation = position.target;
                    if (!_isMoving) setState(() => _isMoving = true);
                  },
                  onCameraIdle: () {
                    setState(() => _isMoving = false);
                    _getAddress(_selectedLocation!);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                ),

                // Search Bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          cursorColor: const Color(0xFF4A22A8),
                          style: const TextStyle(
                            color: Color(0xFF4A22A8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: AppLocalization.getText('searchAddress'),
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.black54, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _suggestions = []);
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),

                      // Suggestions List
                      if (_suggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _suggestions.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, indent: 50),
                            itemBuilder: (context, index) {
                              final suggestion = _suggestions[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on_outlined,
                                    size: 20, color: Colors.grey),
                                title: Text(
                                  suggestion['description'],
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectSuggestion(suggestion),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Clean Centered Pin
                IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(bottom: _isMoving ? 15 : 0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.black, size: 38),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                              ),
                            ],
                          ),
                        ),
                        if (_isMoving)
                          Container(
                            width: 12,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4)
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  right: 20,
                  bottom: 220, // Adjusted back for slightly smaller pane
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () async {
                      Position position = await Geolocator.getCurrentPosition();
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(
                            LatLng(position.latitude, position.longitude)),
                      );
                    },
                    child: const Icon(Icons.my_location, color: Colors.black),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 22),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            spreadRadius: 5)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Delivery details",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.map_outlined,
                                  color: Colors.black54, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _address.isEmpty
                                    ? "Searching location..."
                                    : _address,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (_isMoving || _isFetchingAddress)
                                ? null
                                : () {
                                    Navigator.pop(context, {
                                      'location': _selectedLocation,
                                      'address': _address,
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A22A8),
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                              elevation: 0,
                            ),
                            child: _isFetchingAddress
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text(
                                    "Confirm Location",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
