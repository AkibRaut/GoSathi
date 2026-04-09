import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:go_sathi/models/route_data.dart';
import 'package:go_sathi/view/routes_screen.dart';
import '../utils/app_colors.dart';

class TripMapScreen extends StatefulWidget {
  final LatLng startLatLng;
  final LatLng destinationLatLng;
  final String startAddress;
  final String destinationAddress;
  final VoidCallback? onViewRoutes;
  final ValueChanged<TripRouteData>? onRouteDataChanged;
  final RouteAmenity? navigateAmenityRequest;
  final ValueChanged<String>? onNavigateAmenityHandled;

  const TripMapScreen({
    super.key,
    required this.startLatLng,
    required this.destinationLatLng,
    required this.startAddress,
    required this.destinationAddress,
    this.onViewRoutes,
    this.onRouteDataChanged,
    this.navigateAmenityRequest,
    this.onNavigateAmenityHandled,
  });

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  static const double _routeCorridorKm = 1.2;
  late GoogleMapController _mapController;
  final Set<Marker> _coreMarkers = {};
  final Set<Polyline> _polylines = {};
  final Location _location = Location();
  LatLng? _currentLocation;
  List<LatLng> _routePoints = [];
  List<RouteAmenity> _upcomingAmenities = [];
  bool _isLoadingRoute = true;
  bool _isLoadingAmenities = false;
  bool _isNavigationActive = false;
  bool _showUpcomingStopsPanel = false;
  bool _isUpcomingStopsCollapsed = false;
  LatLng? _activeDestinationLatLng;
  String _activeDestinationTitle = '';
  String _activeDestinationSnippet = '';
  String _distance = '';
  String _duration = '';
  String _selectedCategory = 'All';
  bool _showRoutesOverlay = false;

  static const String _apiKey = "AIzaSyCnfQ-TTa0kZzAPvcgc9qyorD34aIxaZhk";
  final List<String> _categories = [
    'All',
    'Petrol',
    'EV',
    'Food',
    'Hotels',
    "CNG",
  ];

  @override
  void initState() {
    super.initState();
    _activeDestinationLatLng = widget.destinationLatLng;
    _activeDestinationTitle = 'Destination';
    _activeDestinationSnippet = widget.destinationAddress;
    _initializeMap();
    _getCurrentLocation();
    _fetchRouteDetails(destinationLatLng: widget.destinationLatLng);
  }

  @override
  void didUpdateWidget(covariant TripMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final request = widget.navigateAmenityRequest;
    if (request != null && request.id != oldWidget.navigateAmenityRequest?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _navigateToAmenity(request);
        widget.onNavigateAmenityHandled?.call(request.id);
      });
    }
  }

  void _initializeMap() {
    _coreMarkers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: widget.startLatLng,
        infoWindow: InfoWindow(title: 'Start', snippet: widget.startAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    _syncDestinationMarker();
  }

  void _syncDestinationMarker() {
    final destination = _activeDestinationLatLng;
    if (destination == null) {
      return;
    }

    _coreMarkers.removeWhere(
      (marker) => marker.markerId == const MarkerId('destination'),
    );
    _coreMarkers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        infoWindow: InfoWindow(
          title: _activeDestinationTitle,
          snippet: _activeDestinationSnippet,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
      });
      _addCurrentLocationMarker();
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentLocation != null) {
      _coreMarkers.removeWhere(
        (marker) => marker.markerId == const MarkerId('current'),
      );
      _coreMarkers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Your location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  void _notifyRouteDataChanged() {
    widget.onRouteDataChanged?.call(
      TripRouteData(
        startAddress: widget.startAddress,
        destinationAddress: widget.destinationAddress,
        distance: _distance,
        duration: _duration,
        amenities: _upcomingAmenities,
        isLoadingAmenities: _isLoadingAmenities,
      ),
    );
  }

  bool get _isNavigatingToStop {
    final active = _activeDestinationLatLng;
    if (active == null) {
      return false;
    }

    return active.latitude != widget.destinationLatLng.latitude ||
        active.longitude != widget.destinationLatLng.longitude;
  }

  Future<void> _fetchRouteDetails({
    required LatLng destinationLatLng,
    String destinationTitle = 'Destination',
    String? destinationSnippet,
    bool refreshUpcomingStops = false,
  }) async {
    final originLatLng = _currentLocation ?? widget.startLatLng;

    setState(() {
      _isLoadingRoute = true;
      _activeDestinationLatLng = destinationLatLng;
      _activeDestinationTitle = destinationTitle;
      _activeDestinationSnippet =
          destinationSnippet ?? _activeDestinationSnippet;
      _polylines.removeWhere(
        (polyline) => polyline.polylineId == const PolylineId('route'),
      );
      _syncDestinationMarker();
    });

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${originLatLng.latitude},${originLatLng.longitude}'
      '&destination=${destinationLatLng.latitude},${destinationLatLng.longitude}'
      '&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'][0];
          _distance = legs['distance']['text'];
          _duration = legs['duration']['text'];

          final encodedPoints = route['overview_polyline']['points'];
          final List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(
            encodedPoints,
          );
          final List<LatLng> routePoints = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          setState(() {
            _routePoints = routePoints;
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: AppColors.primary,
                points: routePoints,
                width: 5,
              ),
            );
            _isLoadingRoute = false;
          });
          _notifyRouteDataChanged();

          _fitBounds(routePoints);
          if (_isNavigationActive && refreshUpcomingStops) {
            await _fetchUpcomingAmenities();
          }
        } else {
          setState(() => _isLoadingRoute = false);
          Get.snackbar('Error', 'No route found');
        }
      } else {
        setState(() => _isLoadingRoute = false);
        Get.snackbar('Error', 'Failed to fetch route');
      }
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      debugPrint('Route error: $e');
      Get.snackbar('Error', 'Could not calculate route');
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _toggleRoutesOverlay() {
    setState(() {
      _showRoutesOverlay = !_showRoutesOverlay;
    });
  }

  void _handleViewRoutes() {
    if (widget.onViewRoutes != null) {
      widget.onViewRoutes!();
    } else {
      _toggleRoutesOverlay();
    }
  }

  Future<void> _startNavigation() async {
    if (_routePoints.isEmpty) {
      Get.snackbar('Route', 'Please wait while the route loads');
      return;
    }

    setState(() {
      _isNavigationActive = true;
      _showUpcomingStopsPanel = true;
      _isUpcomingStopsCollapsed = false;
    });

    if (_upcomingAmenities.isEmpty) {
      await _fetchUpcomingAmenities();
    }
  }

  Future<void> _fetchUpcomingAmenities() async {
    setState(() {
      _isLoadingAmenities = true;
    });
    _notifyRouteDataChanged();

    try {
      final samples = _sampleRoutePoints(_routePoints, sampleCount: 6);
      final Map<String, RouteAmenity> amenityMap = {};

      for (final point in samples) {
        final petrolResults = await _fetchNearbyPlaces(
          point,
          category: 'Petrol',
          type: 'gas_station',
        );
        final evResults = await _fetchNearbyPlaces(
          point,
          category: 'EV',
          keyword: 'ev charging station',
        );
        final foodResults = await _fetchNearbyPlaces(
          point,
          category: 'Food',
          type: 'restaurant',
        );
        final hotelResults = await _fetchNearbyPlaces(
          point,
          category: 'Hotels',
          keyword: 'hotel',
        );
        final cngResults = await _fetchNearbyPlaces(
          point,
          category: 'CNG',
          keyword: 'cng station',
        );

        for (final amenity in [
          ...petrolResults,
          ...evResults,
          ...foodResults,
          ...hotelResults,
          ...cngResults,
        ]) {
          final existing = amenityMap[amenity.id];
          if (existing == null ||
              amenity.routePointIndex < existing.routePointIndex) {
            amenityMap[amenity.id] = amenity;
          }
        }
      }

      final amenities = amenityMap.values.toList()
        ..sort((a, b) => a.routePointIndex.compareTo(b.routePointIndex));

      setState(() {
        _upcomingAmenities = amenities.take(10).toList();
      });
      _notifyRouteDataChanged();
    } catch (e) {
      debugPrint('Amenity fetch error: $e');
      Get.snackbar(
        'Stops unavailable',
        'Could not load upcoming fuel and EV stops right now',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAmenities = false;
        });
        _notifyRouteDataChanged();
      }
    }
  }

  Future<void> _navigateToAmenity(RouteAmenity amenity) async {
    setState(() {
      _isNavigationActive = true;
      _showUpcomingStopsPanel = false;
    });

    await _fetchRouteDetails(
      destinationLatLng: amenity.location,
      destinationTitle: amenity.name,
      destinationSnippet: amenity.address,
      refreshUpcomingStops: false,
    );

    if (!mounted) return;
    Get.snackbar(
      'Navigating',
      'Route updated to ${amenity.name}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _resumeOriginalTrip() async {
    setState(() {
      _isNavigationActive = true;
      _showUpcomingStopsPanel = true;
      _isUpcomingStopsCollapsed = false;
    });

    await _fetchRouteDetails(
      destinationLatLng: widget.destinationLatLng,
      destinationTitle: 'Destination',
      destinationSnippet: widget.destinationAddress,
      refreshUpcomingStops: false,
    );

    if (!mounted) return;
    Get.snackbar(
      'Trip resumed',
      'Back to your original destination',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<List<RouteAmenity>> _fetchNearbyPlaces(
    LatLng origin, {
    required String category,
    String? type,
    String? keyword,
  }) async {
    final buffer = StringBuffer(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${origin.latitude},${origin.longitude}'
      '&radius=3500'
      '&key=$_apiKey',
    );

    if (type != null) {
      buffer.write('&type=$type');
    }
    if (keyword != null) {
      buffer.write('&keyword=${Uri.encodeQueryComponent(keyword)}');
    }

    final response = await http.get(Uri.parse(buffer.toString()));
    if (response.statusCode != 200) {
      return [];
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>? ?? []);

    return results
        .map((raw) {
          final place = raw as Map<String, dynamic>;
          final geometry = place['geometry'] as Map<String, dynamic>? ?? {};
          final location = geometry['location'] as Map<String, dynamic>? ?? {};
          final lat = (location['lat'] as num?)?.toDouble();
          final lng = (location['lng'] as num?)?.toDouble();

          if (lat == null || lng == null) {
            return null;
          }

          final amenityLocation = LatLng(lat, lng);
          final routeMatch = _findNearestRouteMatch(amenityLocation);
          final currentRouteIndex = _currentRoutePointIndex;

          if (routeMatch.distanceFromRouteKm > _routeCorridorKm ||
              routeMatch.routePointIndex < currentRouteIndex) {
            return null;
          }

          final distanceAheadKm = _distanceAlongRouteKm(
            amenityLocation,
            routeMatch.routePointIndex,
          );
          final rating = (place['rating'] as num?)?.toDouble();

          return RouteAmenity(
            id: place['place_id']?.toString() ?? '${category}_$lat$lng',
            name: place['name']?.toString() ?? category,
            address: place['vicinity']?.toString() ?? 'Upcoming stop',
            location: amenityLocation,
            category: category,
            rating: rating,
            routePointIndex: routeMatch.routePointIndex,
            distanceAheadKm: distanceAheadKm,
            routeOffsetKm: routeMatch.distanceFromRouteKm,
          );
        })
        .whereType<RouteAmenity>()
        .toList();
  }

  List<LatLng> _sampleRoutePoints(List<LatLng> points, {int sampleCount = 6}) {
    if (points.length <= sampleCount) {
      return points;
    }

    final step = (points.length - 1) / (sampleCount - 1);
    return List<LatLng>.generate(sampleCount, (index) {
      final sampledIndex = (index * step).round().clamp(0, points.length - 1);
      return points[sampledIndex];
    });
  }

  int _nearestRoutePointIndex(LatLng target) {
    if (_routePoints.isEmpty) return 0;

    var nearestIndex = 0;
    var nearestDistance = double.infinity;

    for (var index = 0; index < _routePoints.length; index++) {
      final distance = _distanceBetweenKm(_routePoints[index], target);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }

    return nearestIndex;
  }

  int get _currentRoutePointIndex {
    if (_currentLocation == null) {
      return 0;
    }
    return _nearestRoutePointIndex(_currentLocation!);
  }

  _RouteMatch _findNearestRouteMatch(LatLng target) {
    if (_routePoints.length < 2) {
      return _RouteMatch(
        routePointIndex: _nearestRoutePointIndex(target),
        distanceFromRouteKm: _routePoints.isEmpty
            ? 0
            : _distanceBetweenKm(_routePoints.first, target),
      );
    }

    var bestIndex = 0;
    var bestDistance = double.infinity;

    for (var index = 0; index < _routePoints.length - 1; index++) {
      final distance = _distancePointToSegmentKm(
        target,
        _routePoints[index],
        _routePoints[index + 1],
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index + 1;
      }
    }

    return _RouteMatch(
      routePointIndex: bestIndex,
      distanceFromRouteKm: bestDistance,
    );
  }

  double _distanceAlongRouteKm(LatLng target, int routePointIndex) {
    if (_routePoints.isEmpty) {
      return 0;
    }

    final startIndex = _currentRoutePointIndex;
    final safeStart = startIndex.clamp(0, _routePoints.length - 1);
    final safeEnd = routePointIndex.clamp(0, _routePoints.length - 1);

    if (safeEnd <= safeStart) {
      return _distanceBetweenKm(_routePoints[safeStart], target);
    }

    var total = 0.0;
    for (var index = safeStart; index < safeEnd; index++) {
      total += _distanceBetweenKm(_routePoints[index], _routePoints[index + 1]);
    }

    total += _distanceBetweenKm(_routePoints[safeEnd], target);
    return total;
  }

  double _distanceBetweenKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final haversine =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(lat1) * cos(lat2) * (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(haversine), sqrt(1 - haversine));

    return earthRadiusKm * c;
  }

  double _distancePointToSegmentKm(LatLng point, LatLng start, LatLng end) {
    final avgLat = _toRadians(
      (start.latitude + end.latitude + point.latitude) / 3,
    );
    final pointX = point.longitude * cos(avgLat);
    final startX = start.longitude * cos(avgLat);
    final endX = end.longitude * cos(avgLat);

    final pointY = point.latitude;
    final startY = start.latitude;
    final endY = end.latitude;

    final dx = endX - startX;
    final dy = endY - startY;

    if (dx == 0 && dy == 0) {
      return _distanceBetweenKm(point, start);
    }

    final projection =
        ((pointX - startX) * dx + (pointY - startY) * dy) / (dx * dx + dy * dy);
    final t = projection.clamp(0.0, 1.0);
    final closest = LatLng(
      start.latitude + (end.latitude - start.latitude) * t,
      start.longitude + (end.longitude - start.longitude) * t,
    );

    return _distanceBetweenKm(point, closest);
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;

  double _markerHueForCategory(String category) {
    switch (category) {
      case 'Petrol':
        return BitmapDescriptor.hueOrange;
      case 'EV':
        return BitmapDescriptor.hueAzure;
      case 'Food':
        return BitmapDescriptor.hueRose;
      case 'Hotels':
        return BitmapDescriptor.hueViolet;
      case 'CNG':
        return BitmapDescriptor.hueCyan;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  List<RouteAmenity> get _filteredAmenities {
    if (_selectedCategory == 'All') {
      return _upcomingAmenities;
    }

    return _upcomingAmenities
        .where((amenity) => amenity.category == _selectedCategory)
        .toList();
  }

  Set<Marker> get _visibleMarkers {
    final markers = <Marker>{..._coreMarkers};
    for (final amenity in _filteredAmenities) {
      markers.add(
        Marker(
          markerId: MarkerId('amenity_${amenity.id}'),
          position: amenity.location,
          infoWindow: InfoWindow(
            title: amenity.name,
            snippet: '${amenity.category} • ${amenity.distanceLabel} ahead',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _markerHueForCategory(amenity.category),
          ),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Header with Route Details
          _buildRouteHeader(),

          // Category Filter Chips
          _buildCategoryFilter(),

          // Main Content - Google Map
          Expanded(
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: widget.startLatLng,
                    zoom: 12,
                  ),
                  markers: _visibleMarkers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),

                if (_showRoutesOverlay)
                  Positioned.fill(child: Container(color: Colors.black54)),
                if (_showRoutesOverlay)
                  Positioned(
                    top: 80,
                    left: 16,
                    right: 16,
                    bottom: 80,
                    child: Material(
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.hardEdge,
                      child: Container(
                        color: Colors.grey[50],
                        child: RoutesScreen(
                          embedded: true,
                          onBackToMap: _toggleRoutesOverlay,
                          routeData: TripRouteData(
                            startAddress: widget.startAddress,
                            destinationAddress: widget.destinationAddress,
                            distance: _distance,
                            duration: _duration,
                            amenities: _upcomingAmenities,
                            isLoadingAmenities: _isLoadingAmenities,
                          ),
                          onNavigateToAmenity: (amenity) async {
                            _toggleRoutesOverlay();
                            await _navigateToAmenity(amenity);
                          },
                        ),
                      ),
                    ),
                  ),

                // Loading overlay
                if (_isLoadingRoute)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                if (_isLoadingAmenities)
                  Positioned(
                    top: 92,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Finding route stops...',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Back button
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Trip info card overlay
                if (!_isNavigationActive)
                  Positioned(
                    bottom: 80,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.route,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Trip Summary',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.startAddress,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_downward,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.destinationAddress,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (_distance.isNotEmpty && _duration.isNotEmpty) ...[
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timeline,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Distance: $_distance',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Duration: $_duration',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // Bottom action button
                if (_isNavigationActive && _showUpcomingStopsPanel)
                  _buildUpcomingStopsPanel(),
                if (_isNavigationActive && !_showUpcomingStopsPanel)
                  _buildUpcomingStopsReopenButton(),
                if (_isNavigationActive && _isNavigatingToStop)
                  _buildResumeTripButton(),

                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _handleViewRoutes,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.view_list,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Route list',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _startNavigation,
                        icon: Icon(
                          _isNavigationActive
                              ? Icons.my_location
                              : Icons.navigation,
                        ),
                        label: Text(
                          _isNavigationActive
                              ? 'Navigation Active'
                              : 'Start Navigation',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHeader() {
    final aheadCount = _filteredAmenities.length.toString();
    return Container(
      color: Colors.black87,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Mumbai',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    const Text(
                      'End',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatWidget(
                _distance.isNotEmpty ? _distance : '0 km',
                'Route',
              ),
              const SizedBox(width: 16),
              _buildStatWidget(aheadCount, 'Ahead'),
              const SizedBox(width: 16),
              _buildStatWidget(
                _duration.isNotEmpty ? _duration : '0 min',
                _isNavigationActive ? 'ETA' : 'Trip',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatWidget(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = category);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    if (category == 'Petrol')
                      Icon(
                        Icons.local_gas_station,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.orange,
                      )
                    else if (category == 'EV')
                      Icon(
                        Icons.ev_station,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      )
                    else if (category == 'Food')
                      Icon(
                        Icons.restaurant,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      )
                    else if (category == 'Hotels')
                      Icon(
                        Icons.hotel,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      )
                    else if (category == 'CNG')
                      Icon(
                        Icons.local_gas_station,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    if (category != 'All') const SizedBox(width: 6),
                    Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpcomingStopsPanel() {
    final amenities = _filteredAmenities.take(3).toList();

    return Positioned(
      left: 16,
      right: 16,
      bottom: 82,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.42,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _isUpcomingStopsCollapsed
                          ? Icons.explore_outlined
                          : Icons.explore,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isUpcomingStopsCollapsed
                            ? 'Upcoming stops'
                            : 'Upcoming stops on your route',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showUpcomingStopsPanel = false;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.close, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isUpcomingStopsCollapsed = !_isUpcomingStopsCollapsed;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isUpcomingStopsCollapsed ? 'Open stops' : 'Minimize',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isUpcomingStopsCollapsed
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                if (_isUpcomingStopsCollapsed) ...[
                  const SizedBox(height: 8),
                  Text(
                    _isLoadingAmenities
                        ? 'Scanning route stops...'
                        : '${amenities.length} stop${amenities.length == 1 ? '' : 's'} ready',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  if (_isLoadingAmenities)
                    Text(
                      'Scanning your route for petrol pumps and EV chargers...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else if (amenities.isEmpty)
                    Text(
                      _selectedCategory == 'All'
                          ? 'No upcoming petrol pumps or EV chargers found yet.'
                          : 'No upcoming ${_selectedCategory.toLowerCase()} stops found right now.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    ...amenities.map(_buildAmenityTile),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingStopsReopenButton() {
    return Positioned(
      left: 16,
      bottom: 88,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showUpcomingStopsPanel = true;
            _isUpcomingStopsCollapsed = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Upcoming stops',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumeTripButton() {
    return Positioned(
      right: 16,
      bottom: 88,
      child: GestureDetector(
        onTap: _resumeOriginalTrip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.alt_route, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Original trip',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityTile(RouteAmenity amenity) {
    final isPetrol = amenity.category == 'Petrol';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (isPetrol ? Colors.orange : Colors.lightBlue)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPetrol ? Icons.local_gas_station : Icons.ev_station,
                    color: isPetrol ? Colors.orange : Colors.lightBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        amenity.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        amenity.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amenity.distanceLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    if (amenity.rating != null)
                      Text(
                        '${amenity.rating!.toStringAsFixed(1)} star',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToAmenity(amenity),
                icon: const Icon(Icons.navigation, size: 16),
                label: Text(
                  'Navigate',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _RouteMatch {
  final int routePointIndex;
  final double distanceFromRouteKm;

  const _RouteMatch({
    required this.routePointIndex,
    required this.distanceFromRouteKm,
  });
}
