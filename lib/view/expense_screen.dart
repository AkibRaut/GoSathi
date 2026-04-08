import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int _selectedNavIndex = 2; // Expenses tab is selected
  bool _showEmptyState = true;

  List<Map<String, dynamic>> _expenses = [];

  final List<String> _navItems = ['Routes', 'Safety', 'Expenses', 'Settings'];
  final List<IconData> _navIcons = [
    Icons.route,
    Icons.security,
    Icons.receipt,
    Icons.settings,
  ];

  // Expense categories
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Fuel',
      'icon': Icons.local_gas_station,
      'color': Colors.orange,
      'total': 0.0,
    },
    {'name': 'Toll', 'icon': Icons.toll, 'color': Colors.orange, 'total': 0.0},
    {
      'name': 'Food',
      'icon': Icons.restaurant,
      'color': Colors.green,
      'total': 0.0,
    },
    {
      'name': 'Other',
      'icon': Icons.more_horiz,
      'color': Colors.blue,
      'total': 0.0,
    },
  ];

  double get _totalSpent {
    return _categories.fold(0.0, (sum, cat) => sum + (cat['total'] as double));
  }

  void _addExpense() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Expense',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_buildExpenseForm()],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _simulateAddExpense();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              'Add',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseForm() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter amount',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixText: '₹ ',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField(
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _categories
              .map(
                (cat) => DropdownMenuItem(
                  value: cat['name'],
                  child: Text(cat['name']),
                ),
              )
              .toList(),
          onChanged: (value) {},
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Optional',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  void _simulateAddExpense() {
    setState(() {
      _showEmptyState = false;
      // Add sample expense
      _categories[0]['total'] = 500.0; // Fuel
      _categories[1]['total'] = 150.0; // Toll
      _categories[2]['total'] = 300.0; // Food
      _categories[3]['total'] = 50.0; // Other
    });

    Get.snackbar(
      'Success',
      'Expense added successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

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
                  // Total Spent Card
                  _buildTotalSpentCard(),

                  const SizedBox(height: 24),

                  // Empty State or Expenses List
                  if (_showEmptyState)
                    _buildEmptyState()
                  else
                    _buildExpensesList(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Expenses',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: _addExpense,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSpentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spent',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_totalSpent.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          // Category Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _categories
                .map((category) => _buildCategoryBreakdown(category))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<String, dynamic> category) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            category['icon'] as IconData,
            color: category['color'] as Color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${(category['total'] as double).toStringAsFixed(0)}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          category['name'] as String,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            'No Expenses Yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log fuel, toll, and food expenses during your trip',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addExpense,
            icon: const Icon(Icons.add),
            label: Text(
              'Add First Expense',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expenses Breakdown',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._categories
            .where((cat) => (cat['total'] as double) > 0)
            .map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildExpenseItem(category),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> category) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (category['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              category['icon'] as IconData,
              color: category['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${((category['total'] as double) / _totalSpent * 100).toStringAsFixed(1)}% of total',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${(category['total'] as double).toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
