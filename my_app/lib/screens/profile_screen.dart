import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:my_app/screens/security_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  int _total = 0;
  int _pending = 0;
  int _completed = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final profile = await AuthService().getUserProfile();
      if (profile != null) {
        final role = profile['role'] ?? 'Student';
        final uid = profile['uid'] ?? '';
        
        final appointments = await ApiService.fetchAppointments(uid, role);
        
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _total = appointments.length;
            _pending = appointments.where((a) => a['status'].toString().toLowerCase() == 'pending').length;
            _completed = appointments.where((a) => a['status'].toString().toLowerCase() == 'completed' || a['status'].toString().toLowerCase() == 'approved').length;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Profile load error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _userProfile?['name'] ?? AuthService().displayName);
    final deptController = TextEditingController(text: _userProfile?['department'] ?? 'Computer Science');
    final phoneController = TextEditingController(text: _userProfile?['phone'] ?? '+91 98765 43210');
    final idController = TextEditingController(text: _userProfile?['idNumber'] ?? 'CF2024001');
    final yearController = TextEditingController(text: _userProfile?['yearOfStudy'] ?? '1st Year');
    final String role = _userProfile?['role'] ?? 'Student';

    final langService = Provider.of<LanguageService>(context, listen: false);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langService.translate('edit_profile')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: langService.translate('full_name'))),
              TextField(controller: deptController, decoration: InputDecoration(labelText: langService.translate('department'))),
              TextField(controller: idController, decoration: InputDecoration(labelText: langService.translate('id_number'))),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: langService.translate('phone_number'))),
              if (role == 'Student')
                TextField(controller: yearController, decoration: InputDecoration(labelText: langService.translate('year_of_study'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(langService.translate('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final user = AuthService().currentUser;
              if (user != null) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  await ApiService.saveUser({
                    'uid': user.uid,
                    'name': nameController.text.trim(),
                    'department': deptController.text.trim(),
                    'idNumber': idController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'yearOfStudy': role == 'Student' ? yearController.text.trim() : null,
                    'role': role,
                    'email': user.email,
                  });
                  
                  await user.updateDisplayName(nameController.text.trim());
                  
                  if (mounted) {
                    Navigator.pop(context); // Pop loading
                    Navigator.pop(context); // Pop dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(langService.translate('profile_updated')), backgroundColor: Colors.green),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Pop loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: Text(langService.translate('save')),
          ),
        ],
      ),
    );
  }

  // --- FACULTY AVAILABILITY HELPERS ---
  
  Future<void> _selectTime(bool isStart) async {
    final availability = _userProfile?['availability'] ?? {};
    final int currentHour = isStart 
        ? (availability['startHour'] ?? 9) 
        : (availability['endHour'] ?? 17);
        
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
    );
    
    if (picked != null) {
      final newAvailability = Map<String, dynamic>.from(availability);
      if (isStart) {
         newAvailability['startHour'] = picked.hour;
      } else {
         newAvailability['endHour'] = picked.hour;
      }
      _updateAvailability(newAvailability);
    }
  }

  void _toggleDay(int dayIndex) {
    final availability = _userProfile?['availability'] ?? {};
    List<dynamic> days = List.from(availability['days'] ?? [1, 2, 3, 4, 5]);
    
    if (days.contains(dayIndex)) {
      days.remove(dayIndex);
    } else {
      days.add(dayIndex);
    }
    
    final newAvailability = Map<String, dynamic>.from(availability);
    newAvailability['days'] = days;
    _updateAvailability(newAvailability);
  }
  
  void _toggleAvailabilityEnabled(bool enabled) {
    final availability = _userProfile?['availability'] ?? {};
    final newAvailability = Map<String, dynamic>.from(availability);
    newAvailability['enabled'] = enabled;
    _updateAvailability(newAvailability);
  }

  Future<void> _updateAvailability(Map<String, dynamic> newAvailability) async {
    setState(() {
      if (_userProfile != null) {
        _userProfile!['availability'] = newAvailability;
      }
    });

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        await ApiService.saveUser({
          'uid': user.uid,
          'availability': newAvailability
        });
      }
    } catch (e) {
      debugPrint("Error updating availability: $e");
    }
  }

  Widget _buildAvailabilityCard() {
    final langService = Provider.of<LanguageService>(context);
    final availability = _userProfile?['availability'] ?? {};
    final bool isEnabled = availability['enabled'] ?? true;
    final int startHour = availability['startHour'] ?? 9;
    final int endHour = availability['endHour'] ?? 17;
    final List<dynamic> days = availability['days'] ?? [1, 2, 3, 4, 5];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.access_time_filled, color: AppTheme.secondaryColor),
                  ),
                  const SizedBox(width: 12),
                  Text(langService.translate('office_hours'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Switch(
                value: isEnabled,
                onChanged: _toggleAvailabilityEnabled,
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 16),
            Text(langService.translate('working_days'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].asMap().entries.map((entry) {
                final int idx = entry.key + 1;
                final bool isSelected = days.contains(idx);
                return GestureDetector(
                  onTap: () => _toggleDay(idx),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
             Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Text(langService.translate('not_accepting_appointments'), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
             )
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String name = _userProfile?['name'] ?? AuthService().displayName;
    final String role = _userProfile?['role'] ?? 'Student';
    final String idNum = _userProfile?['idNumber'] ?? (role == 'Faculty' ? 'PROF-001' : '23IT007');
    final String dept = _userProfile?['department'] ?? 'Computer Science';
    final String email = _userProfile?['email'] ?? AuthService().userEmail;
    final String phone = _userProfile?['phone'] ?? '+91 98765 43210';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
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
                            child: GestureDetector(
                              onTap: _showEditProfileDialog,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 20, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        langService.tryTranslate(name),
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${langService.translate(role.toLowerCase())} ID: $idNum',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    _buildStatCard(context, _total.toString().padLeft(2, '0'), langService.translate('total'), AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    _buildStatCard(context, _pending.toString().padLeft(2, '0'), langService.translate('pending'), AppTheme.warningColor),
                    const SizedBox(width: 12),
                    _buildStatCard(context, _completed.toString().padLeft(2, '0'), langService.translate('completed'), AppTheme.successColor),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                if (role == 'Faculty') ...[
                  _buildAvailabilityCard(),
                  const SizedBox(height: 24),
                ],
                
                _buildSettingTile(Icons.school_outlined, langService.translate('academic_details'), langService.tryTranslate(dept), 
                  onTap: _showEditProfileDialog),
                if (role == 'Student' && _userProfile?['yearOfStudy'] != null)
                  _buildSettingTile(Icons.calendar_view_day, langService.translate('year_of_study'), langService.tryTranslate(_userProfile!['yearOfStudy']),
                    onTap: _showEditProfileDialog),
                _buildSettingTile(Icons.email_outlined, langService.translate('email_address'), email,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(langService.translate('edit_via_profile'))))),
                _buildSettingTile(Icons.phone_outlined, langService.translate('phone_number'), phone,
                  onTap: _showEditProfileDialog),
                _buildSettingTile(Icons.lock_outline, langService.translate('security'), langService.translate('password_privacy'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecuritySettingsScreen()))),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await AuthService().signOut();
                          if (mounted) {
                            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                        label: Text(langService.translate('logout'), style: const TextStyle(color: AppTheme.errorColor)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _loadData,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
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

  Widget _buildSettingTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textLight, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
