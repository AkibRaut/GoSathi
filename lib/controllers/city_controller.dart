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
  }

  void setDestinationCity(String value) {
    destinationCity.value = value;
    destinationTextController.text = value;
    destinationLatLng.value = null;
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

  void startTrip() async {
    if (formKey.currentState!.validate()) {
      // if (startLatLng.value == null || destinationLatLng.value == null) {
      //   Get.snackbar('Error', 'Please select valid places from suggestions');
      //   return;
      // }
      await _getCurrentLocation();
      Get.to(
        () => TripHomeScreen(
          startLatLng: _currentLocation ?? LatLng(18.52028, 73.85667),
          destinationLatLng: LatLng(19.07611, 72.87750),
          startAddress: "Pune, Maharashtra, India",
          destinationAddress: "Mumbai, Maharashtra, India",
        ),
      );
    }
  }

  @override
  void onClose() {
    startTextController.dispose();
    destinationTextController.dispose();
    super.onClose();
  }
}
