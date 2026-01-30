import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/appointment_card.dart';
import '../widgets/quick_action_card.dart';
import '../services/auth_service.dart';
import '../services/appointment_service.dart';
import 'book_appointment_screen.dart';
import 'profile_screen.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';

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

  Widget _buildHomeContent() {
    if (_isLoadingRole) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Syncing profile...',
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
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back, $_displayName!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userRole == 'Faculty' ? 'Faculty Member' : 'Student',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userRole == 'Faculty' 
                      ? 'Review and manage your pending appointments'
                      : 'Manage your faculty appointments efficiently',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions (Only for Students)
            if (_userRole == 'Student') ...[
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.add_circle_outline,
                      title: 'Book Appointment',
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
                      title: 'Faculty List',
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
                  _userRole == 'Faculty' ? 'Recent Requests' : 'Upcoming Appointments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1; // Go to Appointments tab
                    });
                  },
                  child: const Text('View All'),
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
                    'No appointments found',
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

  Widget _buildAppointmentsContent() {
    if (_isLoadingRole) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AppointmentService().getAppointments(_userRole ?? 'Student'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final appointments = snapshot.data ?? [];
        
        if (appointments.isEmpty) {
          return Center(child: Text('No appointments registered yet.'));
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

  Widget _buildSearchContent() {
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
                  Text('Error loading faculty list', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}), 
                    child: const Text('Retry'),
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
                  const Text('No faculty members found.'),
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
                    label: const Text('Refresh'),
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
                title: Text(faculty['name'] ?? 'Unknown Faculty', 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(faculty['department'] ?? 'Department unavailable'),
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
                      child: const Text('Book'),
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
          _showEditDialog(appointment);
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

  Future<void> _showEditDialog(Map<String, dynamic> appointment) async {
    // Show loading while fetching fresh data to ensure we see the rejection reason
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final String id = appointment['id']?.toString() ?? appointment['_id']?.toString() ?? '';
    final freshData = await ApiService.fetchSingleAppointment(id) ?? appointment;
    
    if (mounted) Navigator.pop(context); // Remove loading

    final TextEditingController timeController = TextEditingController(text: freshData['time']);
    final String? reason = freshData['rejectionReason'];
    final bool isRejected = (freshData['status']?.toString().toLowerCase().contains('reject') ?? false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Show Original Subject/Purpose
              Text('Subject:', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
              Text(freshData['subject'] ?? 'No subject provided', style: const TextStyle(fontSize: 14)),
              const Divider(height: 24),

              // 2. Show Faculty Note if Rejected
              if (isRejected && reason != null && reason.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.report_problem_outlined, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Faculty Rejection Note:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(reason, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ],
                  ),
                )
              else if (freshData['status']?.toString().toLowerCase() == 'approved')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('This appointment is Approved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),

              const Text('Update your preferred time:'),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  hintText: 'e.g. 11:00 AM',
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await AppointmentService().updateAppointment(
                  appointment['id'],
                  {'time': timeController.text.trim()},
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment time updated'), backgroundColor: Colors.blue),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );
    }
  }

  void _showApprovalDialog(String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Appointment'),
        content: const Text('Do you want to approve or reject this appointment request?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close current dialog
              _showRejectionReasonDialog(appointmentId); // Show nested reason dialog
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              AppointmentService().updateAppointment(appointmentId, {'status': 'approved'});
              Navigator.pop(context);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionReasonDialog(String appointmentId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Out of office, Please choose another time...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              AppointmentService().updateAppointment(appointmentId, {
                'status': 'rejected',
                'rejectionReason': reasonController.text.trim(),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment rejected with reason'), backgroundColor: Colors.orange),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Syncing profile...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final List<Widget> screens = [
      _buildHomeContent(),
      _buildAppointmentsContent(),
      _buildSearchContent(),
      const ProfileScreen(),
    ];

    final List<String> titles = [
      'CampusFlow',
      'Appointments',
      'Search',
      'My Profile'
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
              accountEmail: Text('${_userRole ?? 'User'} | ${AuthService().currentUser?.email ?? 'user@campusflow.com'}'),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('My Appointments'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signOut();
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
            label: const Text('Book'),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

