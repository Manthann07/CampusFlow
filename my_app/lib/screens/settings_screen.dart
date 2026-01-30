import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    final profile = await AuthService().getUserProfile();
    if (mounted) {
      setState(() {
        _notificationsEnabled = profile?['notificationsEnabled'] ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Preferences'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts for appointment updates'),
            value: _notificationsEnabled,
            onChanged: (val) async {
              setState(() => _notificationsEnabled = val);
              final user = AuthService().currentUser;
              if (user != null) {
                await ApiService.saveUser({
                  'uid': user.uid,
                  'notificationsEnabled': val,
                });
              }
            },
            secondary: const Icon(Icons.notifications_outlined),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme interface'),
            value: themeService.isDarkMode,
            onChanged: (val) => themeService.toggleTheme(val),
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('English'),
            leading: const Icon(Icons.language_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language selection coming soon')),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader('Account'),
          ListTile(
            title: const Text('Change Password'),
            leading: const Icon(Icons.lock_outline),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final email = AuthService().currentUser?.email;
              if (email != null) {
                try {
                  await AuthService().sendPasswordResetEmail(email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password reset link sent to $email')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionHeader('Danger Zone'),
          ListTile(
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account?'),
                  content: const Text('This action is permanent and cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () async {
                        // Capture navigator before async gap to avoid mounted issues
                        final navigator = Navigator.of(context);
                        
                        navigator.pop(); // Close confirmation dialog
                        
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          await AuthService().deleteUserAccount().timeout(const Duration(seconds: 10));
                          
                          // Use captured navigator to close loading and go back
                          navigator.pop(); // Pop loading dialog
                          navigator.popUntil((route) => route.isFirst); 
                          
                        } catch (e) {
                           // If unmounted, we can still try to pop using captured navigator
                           navigator.pop(); // Pop loading dialog
                           
                            String errorMessage = e.toString();
                            if (e is TimeoutException) errorMessage = "Operation timed out. Please check connection.";

                            showDialog(
                              context: context, // Context might be stale, but we try
                              builder: (context) => AlertDialog(
                                title: const Text('Deletion Failed'),
                                content: Text(errorMessage.replaceAll('Exception:', '').trim()),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      if (errorMessage.contains('re-login')) {
                                        AuthService().signOut();
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      }
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                        }
                      }, 
                      child: const Text('Delete', style: TextStyle(color: Colors.red))
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
