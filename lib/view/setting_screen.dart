import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Snooze categories state
  final Map<String, bool> _snoozeCategories = {
    'Petrol Pumps': true,
    'EV Chargers': false,
    'Restaurants': false,
    'Cafes': false,
    'Restrooms': false,
    'Toll Plazas': false,
  };

  final List<Map<String, dynamic>> _categoryIcons = [
    {
      'name': 'Petrol Pumps',
      'icon': Icons.local_gas_station,
      'color': Color(0xFFFF9800),
    },
    {
      'name': 'EV Chargers',
      'icon': Icons.ev_station,
      'color': Color(0xFF3F51B5),
    },
    {
      'name': 'Restaurants',
      'icon': Icons.restaurant,
      'color': Color(0xFF4CAF50),
    },
    {'name': 'Cafes', 'icon': Icons.local_cafe, 'color': Color(0xFF8D6E63)},
    {'name': 'Restrooms', 'icon': Icons.wc, 'color': Color(0xFF9C27B0)},
    {
      'name': 'Toll Plazas',
      'icon': Icons.directions_car,
      'color': Color(0xFF2196F3),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Snooze Categories Section
                  _buildSnoozeCategoriesSection(),

                  const SizedBox(height: 32),

                  _buildFeaturesSection(),

                  const SizedBox(height: 32),

                  // About Section
                  _buildAboutSection(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Navigation
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          Text(
            'Settings',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnoozeCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SNOOZE CATEGORIES',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Silence all alerts for these amenity types for the current trip',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(_snoozeCategories.length, (index) {
              final categoryName = _snoozeCategories.keys.elementAt(index);
              final isEnabled = _snoozeCategories[categoryName]!;
              final categoryIcon = _categoryIcons.firstWhere(
                (item) => item['name'] == categoryName,
              );

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (categoryIcon['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            categoryIcon['icon'] as IconData,
                            color: categoryIcon['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            categoryName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Switch(
                          value: isEnabled,
                          onChanged: (value) {
                            setState(() {
                              _snoozeCategories[categoryName] = value;
                            });
                            Get.snackbar(
                              'Alert Snoozed',
                              '$categoryName alerts ${value ? 'silenced' : 'enabled'}',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.primary,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          activeThumbColor: AppColors.primary,
                          inactiveThumbColor: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                  if (index < _snoozeCategories.length - 1)
                    Divider(
                      height: 1,
                      color: Colors.grey[200],
                      indent: 56,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'title': 'Route-side stops',
        'subtitle': 'Petrol, EV, Food, Hotels, and CNG along your route.',
        'icon': Icons.route,
        'color': AppColors.primary,
      },
      {
        'title': 'Offline route fallback',
        'subtitle': 'Shows an approximate route when internet is unavailable.',
        'icon': Icons.cloud_off,
        'color': Colors.teal,
      },
      {
        'title': 'SOS safety alert',
        'subtitle': 'Open WhatsApp with an emergency message from Safety.',
        'icon': Icons.sos,
        'color': Colors.red,
      },
      {
        'title': 'Trip expenses',
        'subtitle': 'Add fuel, toll, food, and other trip costs.',
        'icon': Icons.receipt_long,
        'color': Colors.orange,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APP FEATURES',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(features.length, (index) {
              final feature = features[index];
              return Column(
                children: [
                  _buildFeatureTile(
                    title: feature['title'] as String,
                    subtitle: feature['subtitle'] as String,
                    icon: feature['icon'] as IconData,
                    color: feature['color'] as Color,
                  ),
                  if (index < features.length - 1)
                    Divider(
                      height: 1,
                      color: Colors.grey[200],
                      indent: 56,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ABOUT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              // App Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'GS',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GoSaathi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'v1.0.0 · Highway Companion',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                'GoSaathi shows all upcoming petrol pumps, EV chargers, restaurants, restrooms, and toll plazas along your route. It automatically detects accidents and alerts your emergency contacts.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.snackbar(
                          'Rate App',
                          'Redirecting to app store...',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.primary,
                          colorText: Colors.white,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Rate',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.snackbar(
                          'Share App',
                          'Opening share menu...',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.primary,
                          colorText: Colors.white,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Share',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
