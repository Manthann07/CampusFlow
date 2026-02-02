import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/services/language_service.dart';
import 'package:my_app/theme/app_theme.dart';
import '../widgets/appointment_card.dart';
import '../widgets/quick_action_card.dart';
import '../services/auth_service.dart';
import '../services/appointment_service.dart';
import 'package:my_app/screens/book_appointment_screen.dart';
import 'package:my_app/screens/profile_screen.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:my_app/screens/notifications_screen.dart';
import 'package:my_app/screens/edit_appointment_screen.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:my_app/screens/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    // Small delay to let Firebase state settle
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _loadUserRole();
    });
  }

  Future<void> _loadUserRole() async {
    try {
      final profile = await AuthService().getUserProfile();
      if (mounted) {
        setState(() {
          _userRole = profile?['role'] ?? 'Student';
          // Store the profile name as a local variable for the header
          _displayName = profile?['name'] ?? AuthService().displayName;
          _isLoadingRole = false;
        });
      }
    } catch (e) {
      debugPrint("Dashboard error loading profile: $e");
      if (mounted) {
        setState(() {
          _isLoadingRole = false;
        });
      }
    }
  }

  String _displayName = 'User';

  Widget _buildHomeContent(LanguageService langService) {
    
    if (_isLoadingRole) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              langService.translate('syncing_profile'),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${langService.translate('welcome_back')}, ${langService.tryTranslate(_displayName)}!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userRole == 'Faculty' ? langService.translate('faculty_member') : langService.translate('student_member'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userRole == 'Faculty' 
                      ? langService.translate('faculty_subtitle')
                      : langService.translate('student_subtitle'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions (Only for Students)
            if (_userRole == 'Student') ...[
              Text(
                langService.translate('quick_actions'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.add_circle_outline,
                      title: langService.translate('book_appointment'),
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.people_outline,
                      title: langService.translate('faculty_list'),
                      color: AppTheme.secondaryColor,
                      onTap: () {
                        setState(() {
                          _selectedIndex = 2; // Go to Search tab
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            
            // Recent Appointments Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _userRole == 'Faculty' ? langService.translate('recent_requests') : langService.translate('upcoming_appointments'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1; // Go to Appointments tab
                    });
                  },
                  child: Text(langService.translate('view_all')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildRecentAppointmentsList(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAppointmentsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AppointmentService().getAppointments(_userRole ?? 'Student'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final appointments = snapshot.data ?? [];
        
        if (appointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    langService.translate('no_appointments'),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Show only first 3 in home
        final recentApps = appointments.take(3).toList();
        
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentApps.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final appointment = recentApps[index];
            return _buildAppointmentCard(appointment);
          },
        );
      },
    );
  }

  Widget _buildAppointmentsContent(LanguageService langService) {
    if (_isLoadingRole) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AppointmentService().getAppointments(_userRole ?? 'Student'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final appointments = snapshot.data ?? [];
        
        if (appointments.isEmpty) {
          return Center(child: Text(langService.translate('no_appointments')));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildAppointmentCard(appointments[index]),
        );
      },
    );
  }

  Widget _buildSearchContent(LanguageService langService) {
    if (_isLoadingRole) return const Center(child: CircularProgressIndicator());

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AuthService().getFacultyList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(langService.translate('error_loading_list'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}), 
                    child: Text(langService.translate('retry')),
                  ),
                ],
              ),
            ),
          );
        }
        
        final faculties = snapshot.data ?? [];
        
        if (faculties.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(langService.translate('no_faculty_found')),
                  const SizedBox(height: 8),
                  Text(
                    'Ensure users are registered with the role "Faculty" in MongoDB.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => setState(() {}), 
                    icon: const Icon(Icons.refresh),
                    label: Text(langService.translate('refresh')),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: faculties.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final faculty = faculties[index];
            return Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                title: Text(langService.tryTranslate(faculty['name'] ?? 'Unknown Faculty'), 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(langService.tryTranslate(faculty['department'] ?? 'Department unavailable')),
                trailing: _userRole == 'Student' 
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
                        );
                      }, 
                      child: Text(langService.translate('book')),
                    )
                  : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    debugPrint("DEBUG UI: Rendering Card for ${appointment['studentName']} | Status: ${appointment['status']} | Reason: ${appointment['rejectionReason']}");
    String status = appointment['status'] ?? 'pending';
    Color statusColor = AppTheme.warningColor;
    if (status == 'approved' || status == 'Confirmed') statusColor = AppTheme.successColor;
    if (status == 'rejected' || status == 'Rejected') statusColor = Colors.red;

    return AppointmentCard(
      title: _userRole == 'Faculty' 
        ? appointment['studentName'] ?? 'Student'
        : appointment['facultyName'] ?? 'Faculty',
      subtitle: appointment['subject'] ?? appointment['reason'] ?? 'Meeting',
      dateTime: '${appointment['date']}, ${appointment['time']}',
      status: status,
      statusColor: statusColor,
      rejectionReason: appointment['rejectionReason'],
      trailing: _userRole == 'Student' ? IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
        onPressed: () => _confirmDelete(appointment['id']),
      ) : null,
      onTap: () {
        if (_userRole == 'Faculty' && (status == 'pending' || status == 'Pending')) {
          _showApprovalDialog(appointment['id']);
        } else if (_userRole == 'Student') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditAppointmentScreen(appointment: appointment),
            ),
          );
        }
      },
    );
  }

  void _confirmDelete(String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel and delete this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await AppointmentService().deleteAppointment(appointmentId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Removed _showEditDialog as it's now a full screen


  void _showApprovalDialog(String appointmentId) {
    final langService = Provider.of<LanguageService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langService.translate('manage_appointment')),
        content: Text(langService.translate('approve_reject_question')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close current dialog
              _showRejectionReasonDialog(appointmentId); // Show nested reason dialog
            },
            child: Text(langService.translate('rejected'), style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              AppointmentService().updateAppointment(appointmentId, {'status': 'approved'});
              Navigator.pop(context);
            },
            child: Text(langService.translate('approved')),
          ),
        ],
      ),
    );
  }

  void _showRejectionReasonDialog(String appointmentId) {
    final langService = Provider.of<LanguageService>(context, listen: false);
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(langService.translate('rejection_reason')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(langService.translate('provide_rejection_reason')),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. ${langService.tryTranslate('not_possible_on_that_day')}...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(langService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(langService.translate('please_select_reason'))),
                );
                return;
              }
              AppointmentService().updateAppointment(appointmentId, {
                'status': 'rejected',
                'rejectionReason': reasonController.text.trim(),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(langService.translate('rejected')), backgroundColor: Colors.orange),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(langService.translate('confirm_reject')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);
    if (_isLoadingRole) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(langService.translate('syncing_profile'), style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final List<Widget> screens = [
      _buildHomeContent(langService),
      _buildAppointmentsContent(langService),
      _buildSearchContent(langService),
      ProfileScreen(),
    ];

    final List<String> titles = [
      langService.translate('home'),
      langService.translate('appointments'),
      langService.translate('search'),
      langService.translate('profile')
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: NotificationService(),
            builder: (context, _) {
              final unread = NotificationService().unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _displayName.isNotEmpty ? _displayName[0] : 'U',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ),
              accountName: Text(_displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text('${langService.tryTranslate(_userRole ?? 'user')} | ${AuthService().currentUser?.email ?? 'user@campusflow.com'}'),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(langService.translate('home')),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(langService.translate('appointments')),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(langService.translate('profile')),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(langService.translate('settings')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(langService.translate('logout'), style: const TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: screens[_selectedIndex],
      floatingActionButton: _userRole == 'Student' 
        ? FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookAppointmentScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(langService.translate('book')),
            backgroundColor: AppTheme.primaryColor,
          )
        : FloatingActionButton(
            onPressed: () => setState(() {}),
            child: const Icon(Icons.refresh),
          ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: langService.translate('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: langService.translate('appointments'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: langService.translate('search'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: langService.translate('profile'),
          ),
        ],
      ),
    );
  }
}

