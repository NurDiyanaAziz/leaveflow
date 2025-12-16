import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveBalanceScreen extends StatefulWidget {
  const LeaveBalanceScreen({super.key});

  @override
  State<LeaveBalanceScreen> createState() => _LeaveBalanceScreenState();
}

class _LeaveBalanceScreenState extends State<LeaveBalanceScreen> {
  String selectedYear = 'All';
  
  // Get current user
  final user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> leaveTypes = [
    {
      'name': 'Annual Leave',
      'available': 11,
      'used': 8,
      'pending': 1,
      'total': 20,
      'color': Colors.blue,
      'icon': Icons.calendar_today,
    },
    {
      'name': 'Medical Leave',
      'available': 11,
      'used': 3,
      'pending': 0,
      'total': 14,
      'color': Colors.green,
      'icon': Icons.local_hospital,
    },
    {
      'name': 'Carry Forward Leave',
      'available': 2,
      'used': 2,
      'pending': 1,
      'total': 5,
      'color': Colors.purple,
      'icon': Icons.forward,
    },
    {
      'name': 'Compassionate Leave',
      'available': 3,
      'used': 4,
      'pending': 0,
      'total': 7,
      'color': Colors.orange,
      'icon': Icons.favorite,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Leave Balance',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Year Filter Buttons
          _buildYearFilter(),
          const SizedBox(height: 16),
          // Leave Cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: leaveTypes.length,
              itemBuilder: (context, index) {
                return _buildLeaveCard(leaveTypes[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildYearFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterButton('All'),
          const SizedBox(width: 8),
          _buildFilterButton('2025'),
          const SizedBox(width: 8),
          _buildFilterButton('2026'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String year) {
    final isSelected = selectedYear == year;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedYear = year;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[700] : Colors.blue[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              year,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.blue[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final available = leave['available'] as int;
    final used = leave['used'] as int;
    final pending = leave['pending'] as int;
    final total = leave['total'] as int;
    final color = leave['color'] as Color;
    final usedPercentage = (used / total);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leave['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  leave['icon'],
                  color: color[700],
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$available days available',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: usedPercentage,
              // ignore: deprecated_member_use
              backgroundColor: Colors.white.withOpacity(0.5),
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('$used Used', Colors.black87),
              if (pending > 0)
                _buildStatItem('$pending Pending', Colors.orange[700]!),
              _buildStatItem('$total Total', Colors.grey[700]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String text, Color color) {
    final parts = text.split(' ');
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${parts[0]} ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          TextSpan(
            text: parts[1],
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.person_outline, 'Profile', false),
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(Icons.settings_outlined, 'Settings', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.blue[600] : Colors.grey[600],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue[600] : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

extension on Color {
  Color? operator [](int other) {
    return null;
  }
}