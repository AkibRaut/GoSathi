import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_sathi/models/route_data.dart';
import '../utils/app_colors.dart';

class RoutesScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onBackToMap;
  final TripRouteData routeData;
  final ValueChanged<RouteAmenity>? onNavigateToAmenity;

  const RoutesScreen({
    super.key,
    required this.routeData,
    this.embedded = false,
    this.onBackToMap,
    this.onNavigateToAmenity,
  });

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  int _selectedNavIndex = 0;
  String _selectedCategory = 'All';
  final Set<String> _visitedAmenityIds = {};

  final List<String> _categories = ['All', 'Petrol', 'EV', 'Food', 'Hotels'];
  final List<String> _navItems = ['Routes', 'Safety', 'Expenses', 'Settings'];
  final List<IconData> _navIcons = [
    Icons.route,
    Icons.security,
    Icons.receipt,
    Icons.settings,
  ];

  List<RouteAmenity> get _filteredAmenities {
    final source = widget.routeData.amenities;

    if (_selectedCategory == 'All') {
      return source;
    }

    return source
        .where((amenity) => amenity.category == _selectedCategory)
        .toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Petrol':
        return Colors.orange;
      case 'EV':
        return Colors.blue;
      case 'Food':
        return Colors.deepOrange;
      case 'Hotels':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Petrol':
        return Icons.local_gas_station;
      case 'EV':
        return Icons.ev_station;
      case 'Food':
        return Icons.restaurant;
      case 'Hotels':
        return Icons.hotel;
      default:
        return Icons.grid_view_rounded;
    }
  }

  void _navigateToPlace(RouteAmenity amenity) {
    if (widget.onNavigateToAmenity != null) {
      widget.onNavigateToAmenity!(amenity);
      return;
    }

    Get.snackbar(
      'Navigate',
      'Opening navigation for ${amenity.name}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _markDone(RouteAmenity amenity) {
    setState(() {
      _visitedAmenityIds.add(amenity.id);
    });
    Get.snackbar(
      'Done',
      '${amenity.name} marked as visited',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildRouteHeader(),
        _buildCategoryFilter(),
        Expanded(child: _buildAmenitiesContent()),
        if (!widget.embedded) _buildBottomNavigation(),
      ],
    );

    if (widget.embedded) {
      return SafeArea(child: content);
    }

    return Scaffold(backgroundColor: Colors.grey[50], body: content);
  }

  Widget _buildAmenitiesContent() {
    if (widget.routeData.isLoadingAmenities &&
        widget.routeData.amenities.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_filteredAmenities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _selectedCategory == 'All'
                ? 'No route stops available yet. Start navigation to load upcoming petrol pumps and EV chargers.'
                : 'No ${_selectedCategory.toLowerCase()} stops available on this route right now.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemBuilder: (_, index) => _buildAmenityCard(_filteredAmenities[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _filteredAmenities.length,
    );
  }

  Widget _buildRouteHeader() {
    final startLabel = widget.routeData.startAddress.isEmpty
        ? 'Start'
        : widget.routeData.startAddress;
    final aheadCount = _filteredAmenities.length.toString();
    final distance = widget.routeData.distance.isEmpty
        ? '0 km'
        : widget.routeData.distance;
    final duration = widget.routeData.duration.isEmpty
        ? '0 min'
        : widget.routeData.duration;

    return Container(
      color: const Color(0xFF1A1F2E),
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 14, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        startLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'End',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatWidget(distance, 'Route'),
              const SizedBox(width: 24),
              _buildStatWidget(aheadCount, 'Ahead'),
              const SizedBox(width: 24),
              _buildStatWidget(duration, 'ETA'),
            ],
          ),
          if (widget.embedded && widget.onBackToMap != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.onBackToMap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Back to map',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
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
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = category);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 14,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
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

  Widget _buildAmenityCard(RouteAmenity amenity) {
    final color = _getCategoryColor(amenity.category);
    final isVisited = _visitedAmenityIds.contains(amenity.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(amenity.icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        amenity.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        amenity.address,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amenity.distanceLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (amenity.rating != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            amenity.rating!.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isVisited)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Visited',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _navigateToPlace(amenity),
                  icon: const Icon(Icons.navigation, size: 14),
                  label: Text(
                    'Navigate',
                    style: GoogleFonts.inter(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.18),
                    foregroundColor: Colors.orange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _markDone(amenity),
                  icon: const Icon(Icons.check, size: 14),
                  label: Text('Done', style: GoogleFonts.inter(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.18),
                    foregroundColor: Colors.green,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey[400],
        items: List.generate(
          _navItems.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(_navIcons[index]),
            label: _navItems[index],
          ),
        ),
      ),
    );
  }
}
