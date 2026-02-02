import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/services/language_service.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  final List<String> _languages = ['English', 'Hindi', 'Gujarati', 'Spanish', 'French'];

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
    final langService = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(langService.translate('settings')),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader(langService.translate('preferences')),
          SwitchListTile(
            title: Text(langService.translate('push_notifications')),
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
            title: Text(langService.translate('dark_mode')),
            subtitle: const Text('Enable dark theme interface'),
            value: themeService.isDarkMode,
            onChanged: (val) => themeService.toggleTheme(val),
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          ListTile(
            title: Text(langService.translate('language')),
            subtitle: Text(langService.translate(langService.currentLanguage.toLowerCase())),
            leading: const Icon(Icons.language_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(langService),
          ),
          const Divider(),
          _buildSectionHeader(langService.translate('account')),
          ListTile(
            title: Text(langService.translate('change_password')),
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
            title: Text(langService.translate('privacy_policy')),
            leading: const Icon(Icons.privacy_tip_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionHeader(langService.translate('danger_zone')),
          ListTile(
            title: Text(langService.translate('delete_account'), style: const TextStyle(color: Colors.red)),
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(langService.translate('delete_account') + '?'),
                  content: const Text('This action is permanent and cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(langService.translate('cancel'))),
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
                          navigator.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );                          
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
                                    child: Text(langService.translate('ok')),
                                  ),
                                ],
                              ),
                            );
                        }
                      }, 
                      child: Text(langService.translate('delete_account'), style: const TextStyle(color: Colors.red))
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

  void _showLanguageDialog(LanguageService langService) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                langService.translate('select_language'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ..._languages.map((lang) => ListTile(
                title: Text(langService.translate(lang.toLowerCase())),
                trailing: langService.currentLanguage == lang 
                    ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                    : null,
                onTap: () async {
                  await langService.setLanguage(lang);
                  Navigator.pop(context);
                  
                  final user = AuthService().currentUser;
                  if (user != null) {
                    await ApiService.saveUser({
                      'uid': user.uid,
                      'language': lang,
                    });
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(langService.translate('language') + ' ' + langService.translate('changed_to') + ' ' + lang),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                },
              )).toList(),
            ],
          ),
        );
      },
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
