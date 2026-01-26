import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.surfaceColor,
                          child: Icon(Icons.person, size: 80, color: AppTheme.primaryColor),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manthan Sharma',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Student ID: CF2024001',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Stats Row
            Row(
              children: [
                _buildStatCard(context, '12', 'Total', AppTheme.primaryColor),
                const SizedBox(width: 12),
                _buildStatCard(context, '03', 'Pending', AppTheme.warningColor),
                const SizedBox(width: 12),
                _buildStatCard(context, '09', 'Completed', AppTheme.successColor),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Settings List
            _buildSettingTile(Icons.school_outlined, 'Academic Details', 'Computer Science Dept.'),
            _buildSettingTile(Icons.email_outlined, 'Email Address', 'manthan.s@campus.edu'),
            _buildSettingTile(Icons.phone_outlined, 'Phone Number', '+91 98765 43210'),
            _buildSettingTile(Icons.lock_outline, 'Change Password', 'Update your security credentials'),
            
            const SizedBox(height: 24),
            
            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                label: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textLight),
        ],
      ),
    );
  }
}
