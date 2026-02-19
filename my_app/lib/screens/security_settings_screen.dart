import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricsEnabled = false;
  bool _twoFactorEnabled = false;
  bool _appLockEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final profile = await AuthService().getUserProfile();
    if (mounted && profile != null) {
      setState(() {
        _biometricsEnabled = profile['biometricsEnabled'] ?? false;
        _twoFactorEnabled = profile['twoFactorEnabled'] ?? false;
        _appLockEnabled = profile['appLockEnabled'] ?? false;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSecuritySetting(String key, bool value) async {
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        await ApiService.saveUser({
          'uid': user.uid,
          key: value,
        });
        debugPrint("Successfully updated $key to $value in MongoDB");
      } catch (e) {
        debugPrint("Error updating security setting: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(langService.translate('security')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: langService.translate('login_security'),
              children: [
                _buildSecurityTile(
                  icon: Icons.lock_outline,
                  color: AppTheme.primaryColor,
                  title: langService.translate('change_password'),
                  subtitle: langService.translate('update_password_subtitle'),
                  onTap: _showChangePasswordDialog,
                ),
                _buildSecurityTile(
                  icon: Icons.fingerprint,
                  color: AppTheme.successColor,
                  title: langService.translate('biometric_login'),
                  subtitle: langService.translate('biometric_subtitle'),
                  trailing: Switch(
                    value: _biometricsEnabled,
                    onChanged: (val) {
                      setState(() => _biometricsEnabled = val);
                      _updateSecuritySetting('biometricsEnabled', val);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: langService.translate('extra_protection'),
              children: [
                _buildSecurityTile(
                  icon: Icons.verified_user_outlined,
                  color: AppTheme.secondaryColor,
                  title: langService.translate('two_factor_auth'),
                  subtitle: langService.translate('two_factor_subtitle'),
                  trailing: Switch(
                    value: _twoFactorEnabled,
                    onChanged: (val) {
                      setState(() => _twoFactorEnabled = val);
                      _updateSecuritySetting('twoFactorEnabled', val);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                _buildSecurityTile(
                  icon: Icons.phonelink_lock_outlined,
                  color: AppTheme.accentColor,
                  title: langService.translate('app_lock'),
                  subtitle: langService.translate('app_lock_subtitle'),
                  trailing: Switch(
                    value: _appLockEnabled,
                    onChanged: (val) {
                      setState(() => _appLockEnabled = val);
                      _updateSecuritySetting('appLockEnabled', val);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: langService.translate('device_management'),
              children: [
                _buildSecurityTile(
                  icon: Icons.devices_outlined,
                  color: Colors.orange,
                  title: langService.translate('active_sessions'),
                  subtitle: langService.translate('sessions_subtitle'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session management coming soon.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing else const Icon(Icons.chevron_right, color: AppTheme.textLight, size: 20),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final langService = Provider.of<LanguageService>(context, listen: false);
    final email = AuthService().currentUser?.email ?? 'your email';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langService.translate('change_password')),
        content: Text(
            '${langService.translate('password_reset_confirmation')} $email'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(langService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authEmail = AuthService().currentUser?.email;
                if (authEmail != null) {
                  await AuthService().sendPasswordResetEmail(authEmail);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reset link sent to $authEmail'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: Text(langService.translate('send_link')),
          ),
        ],
      ),
    );
  }
}
