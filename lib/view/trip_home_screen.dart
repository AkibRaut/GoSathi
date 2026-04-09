import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_sathi/models/route_data.dart';
import '../utils/app_colors.dart';
import 'map_screen.dart';
import 'routes_screen.dart';
import 'safety_screen.dart';
import 'expense_screen.dart';
import 'setting_screen.dart';

class TripHomeScreen extends StatefulWidget {
  final LatLng startLatLng;
  final LatLng destinationLatLng;
  final String startAddress;
  final String destinationAddress;

  const TripHomeScreen({
    super.key,
    required this.startLatLng,
    required this.destinationLatLng,
    required this.startAddress,
    required this.destinationAddress,
  });

  @override
  State<TripHomeScreen> createState() => _TripHomeScreenState();
}

class _TripHomeScreenState extends State<TripHomeScreen> {
  int _selectedNavIndex = 0;

  final List<String> _navLabels = ['Route', 'Safety', 'Expenses', 'Settings'];
  final List<IconData> _navIcons = [
    Icons.route,
    Icons.security,
    Icons.receipt,
    Icons.settings,
  ];

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      RouteTabScreen(
        startLatLng: widget.startLatLng,
        destinationLatLng: widget.destinationLatLng,
        startAddress: widget.startAddress,
        destinationAddress: widget.destinationAddress,
      ),
      const SafetyScreen(),
      const ExpensesScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedNavIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navLabels.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _navIcons[index],
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 15,
            ),
            const SizedBox(height: 4),
            Text(
              _navLabels[index],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteTabScreen extends StatefulWidget {
  final LatLng startLatLng;
  final LatLng destinationLatLng;
  final String startAddress;
  final String destinationAddress;

  const RouteTabScreen({
    super.key,
    required this.startLatLng,
    required this.destinationLatLng,
    required this.startAddress,
    required this.destinationAddress,
  });

  @override
  State<RouteTabScreen> createState() => _RouteTabScreenState();
}

class _RouteTabScreenState extends State<RouteTabScreen> {
  bool _showRoutesView = false;
  TripRouteData _routeData = const TripRouteData.empty();
  RouteAmenity? _pendingAmenityNavigation;

  void _toggleRoutesView() {
    setState(() {
      _showRoutesView = !_showRoutesView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Offstage(
          offstage: _showRoutesView,
          child: TripMapScreen(
            startLatLng: widget.startLatLng,
            destinationLatLng: widget.destinationLatLng,
            startAddress: widget.startAddress,
            destinationAddress: widget.destinationAddress,
            onViewRoutes: _toggleRoutesView,
            navigateAmenityRequest: _pendingAmenityNavigation,
            onNavigateAmenityHandled: (amenityId) {
              if (!mounted) return;
              if (_pendingAmenityNavigation?.id != amenityId) return;
              setState(() {
                _pendingAmenityNavigation = null;
              });
            },
            onRouteDataChanged: (routeData) {
              if (!mounted) return;
              setState(() {
                _routeData = routeData;
              });
            },
          ),
        ),
        Offstage(
          offstage: !_showRoutesView,
          child: RoutesScreen(
            embedded: true,
            onBackToMap: _toggleRoutesView,
            routeData: _routeData,
            onNavigateToAmenity: (amenity) {
              setState(() {
                _pendingAmenityNavigation = amenity;
                _showRoutesView = false;
              });
            },
          ),
        ),
      ],
    );
  }
}
