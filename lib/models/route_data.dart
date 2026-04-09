import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripRouteData {
  final String startAddress;
  final String destinationAddress;
  final String distance;
  final String duration;
  final List<RouteAmenity> amenities;
  final bool isLoadingAmenities;

  const TripRouteData({
    required this.startAddress,
    required this.destinationAddress,
    required this.distance,
    required this.duration,
    required this.amenities,
    this.isLoadingAmenities = false,
  });

  const TripRouteData.empty({
    this.startAddress = '',
    this.destinationAddress = '',
    this.distance = '',
    this.duration = '',
    this.amenities = const [],
    this.isLoadingAmenities = false,
  });
}

class RouteAmenity {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final String category;
  final double? rating;
  final int routePointIndex;
  final double distanceAheadKm;
  final double routeOffsetKm;

  const RouteAmenity({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.category,
    required this.rating,
    required this.routePointIndex,
    required this.distanceAheadKm,
    required this.routeOffsetKm,
  });

  String get distanceLabel {
    if (distanceAheadKm < 1) {
      return '${(distanceAheadKm * 1000).round()} m';
    }
    return '${distanceAheadKm.toStringAsFixed(1)} km';
  }

  IconData get icon {
    switch (category) {
      case 'Petrol':
        return Icons.local_gas_station;
      case 'EV':
        return Icons.ev_station;
      case 'Food':
        return Icons.restaurant;
      case 'Hotels':
        return Icons.hotel;
      case 'CNG':
        return Icons.local_gas_station;
      default:
        return Icons.place;
    }
  }
}
