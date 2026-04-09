import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_sathi/services/city_service.dart';
import 'package:go_sathi/view/trip_home_screen.dart';
import 'package:location/location.dart';

class CityController extends GetxController {
  final CityService _cityService;
  final String apiKey; // pass your Google API key

  CityController({required CityService cityService, required this.apiKey})
    : _cityService = cityService;

  final formKey = GlobalKey<FormState>();

  final startCity = ''.obs;
  final destinationCity = ''.obs;

  final startTextController = TextEditingController();
  final destinationTextController = TextEditingController();

  final startLatLng = Rxn<LatLng>();
  final destinationLatLng = Rxn<LatLng>();

  final startAddress = ''.obs;
  final destinationAddress = ''.obs;
  final isFetchingCurrentStart = false.obs;
  final isStartingTrip = false.obs;

  // Search places (returns list of predictions)
  Future<List<Map<String, String>>> searchPlaces(String input) async {
    return await _cityService.searchPlaces(input, apiKey);
  }

  // Select a place and fetch its lat/lng
  Future<void> selectStartPlace(String placeId, String description) async {
    final details = await _cityService.getPlaceDetails(placeId, apiKey);
    if (details != null && details['lat'] != null && details['lng'] != null) {
      startCity.value = description;
      startTextController.text = description;
      startAddress.value = details['address'] ?? description;
      startLatLng.value = LatLng(details['lat'], details['lng']);
    } else {
      Get.snackbar('Error', 'Could not fetch coordinates for this place');
    }
  }

  Future<void> selectDestinationPlace(
    String placeId,
    String description,
  ) async {
    final details = await _cityService.getPlaceDetails(placeId, apiKey);
    if (details != null && details['lat'] != null && details['lng'] != null) {
      destinationCity.value = description;
      destinationTextController.text = description;
      destinationAddress.value = details['address'] ?? description;
      destinationLatLng.value = LatLng(details['lat'], details['lng']);
    } else {
      Get.snackbar('Error', 'Could not fetch coordinates for this place');
    }
  }

  void setStartCity(String value) {
    startCity.value = value;
    startTextController.text = value;
    startLatLng.value = null;
    startAddress.value = value;
  }

  void setDestinationCity(String value) {
    destinationCity.value = value;
    destinationTextController.text = value;
    destinationLatLng.value = null;
    destinationAddress.value = value;
  }

  void setStartPlaceFromAutocomplete({
    required String description,
    required double latitude,
    required double longitude,
  }) {
    startCity.value = description;
    startTextController.text = description;
    startAddress.value = description;
    startLatLng.value = LatLng(latitude, longitude);
  }

  void setDestinationPlaceFromAutocomplete({
    required String description,
    required double latitude,
    required double longitude,
  }) {
    destinationCity.value = description;
    destinationTextController.text = description;
    destinationAddress.value = description;
    destinationLatLng.value = LatLng(latitude, longitude);
  }

  void swapCities() {
    final tempCity = startCity.value;
    final tempLatLng = startLatLng.value;
    final tempAddress = startAddress.value;

    startCity.value = destinationCity.value;
    startLatLng.value = destinationLatLng.value;
    startAddress.value = destinationAddress.value;

    destinationCity.value = tempCity;
    destinationLatLng.value = tempLatLng;
    destinationAddress.value = tempAddress;

    startTextController.text = startCity.value;
    destinationTextController.text = destinationCity.value;
  }

  void selectQuickRoute(String route) {
    final parts = route.split(' → ');
    startCity.value = parts[0];
    destinationCity.value = parts[1];
    startTextController.text = parts[0];
    destinationTextController.text = parts[1];
    // Clear coordinates – user must select from suggestions
    startLatLng.value = null;
    destinationLatLng.value = null;
  }

  final Location _location = Location();
  LatLng? _currentLocation;
  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      _currentLocation = LatLng(
        locationData.latitude!,
        locationData.longitude!,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  Future<void> useCurrentLocationAsStart() async {
    try {
      isFetchingCurrentStart.value = true;

      var serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          Get.snackbar(
            'Location disabled',
            'Please enable location service to use current location',
          );
          return;
        }
      }

      var permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
      }

      if (permissionGranted != PermissionStatus.granted &&
          permissionGranted != PermissionStatus.grantedLimited) {
        Get.snackbar(
          'Location permission',
          'Please allow location permission to set the starting point',
        );
        return;
      }

      await _getCurrentLocation();
      if (_currentLocation == null) {
        Get.snackbar(
          'Location unavailable',
          'Could not detect your current location right now',
        );
        return;
      }

      startCity.value = 'My current location';
      startTextController.text = 'My current location';
      startAddress.value = 'My current location';
      startLatLng.value = _currentLocation;

      Get.snackbar(
        'Starting point updated',
        'Current location set as starting point',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error setting current location as start: $e');
      Get.snackbar(
        'Location error',
        'Unable to set current location as starting point',
      );
    } finally {
      isFetchingCurrentStart.value = false;
    }
  }

  void startTrip() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (startLatLng.value == null || destinationLatLng.value == null) {
      Get.snackbar(
        'Route incomplete',
        'Please select both start and destination from suggestions',
      );
      return;
    }

    try {
      isStartingTrip.value = true;
      await _getCurrentLocation();
      Get.to(
        () => TripHomeScreen(
          startLatLng:
              startLatLng.value ??
              _currentLocation ??
              LatLng(18.52028, 73.85667),
          destinationLatLng:
              destinationLatLng.value ?? LatLng(19.07611, 72.87750),
          startAddress: startAddress.value,
          destinationAddress: destinationAddress.value,
        ),
      );
    } finally {
      isStartingTrip.value = false;
    }
  }

  @override
  void onClose() {
    startTextController.dispose();
    destinationTextController.dispose();
    super.onClose();
  }
}
