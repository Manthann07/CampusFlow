import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'notification_service.dart';

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controller to simulate real-time updates via polling (since MongoDB/Node setup is usually REST)
  final _appointmentStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Timer? _pollingTimer;
  Map<String, String> _lastKnownStatuses = {};

  // CREATE: Add Appointment
  Future<void> createAppointment({
    required String facultyId,
    required String facultyName,
    required String subject,
    required String date,
    required String time,
  }) async {
    User? user = _auth.currentUser;
    String uid = user?.uid ?? 'guest_student';
    String name = user?.displayName ?? 'Student';

    Map<String, dynamic> data = {
      'studentId': uid,
      'studentName': name,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'subject': subject,
      'date': date,
      'time': time,
      'status': 'pending',
    };

    await ApiService.createAppointment(data);
    _refreshList(uid, 'Student');
  }

  // READ: View Appointments
  Stream<List<Map<String, dynamic>>> getAppointments(String role) {
    User? user = _auth.currentUser;
    String uid = user?.uid ?? 'guest';
    
    // Start polling for "real-time" feel in lab setup
    _startPolling(uid, role);
    
    return _appointmentStreamController.stream;
  }

  void _startPolling(String uid, String role) {
    _pollingTimer?.cancel();
    _refreshList(uid, role); // Initial fetch
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshList(uid, role);
    });
  }

  Future<void> _refreshList(String uid, String role) async {
    try {
      final list = await ApiService.fetchAppointments(uid, role);
      // Map _id (MongoDB) to id for UI stability if needed
      final mappedList = list.map((item) {
        String id = item['_id']?.toString() ?? '';
        item['id'] = id;
        
        // Notification Logic for Students
        if (role == 'Student' && id.isNotEmpty) {
          String currentStatus = item['status']?.toString().toLowerCase() ?? 'pending';
          String? lastStatus = _lastKnownStatuses[id];

          if (lastStatus != null && lastStatus != currentStatus) {
            String facultyName = item['facultyName'] ?? 'Faculty';
            if (currentStatus == 'approved') {
              NotificationService().addNotification(
                'Appointment Approved!',
                'Prof. $facultyName has approved your meeting request.'
              );
            } else if (currentStatus == 'rejected') {
              NotificationService().addNotification(
                'Appointment Rejected',
                'Prof. $facultyName was unable to accept your request.'
              );
            }
          }
          _lastKnownStatuses[id] = currentStatus;
        }

        return item;
      }).toList();
      
      if (!_appointmentStreamController.isClosed) {
        _appointmentStreamController.add(mappedList);
      }
    } catch (e) {
      print("API Refresh Error: $e");
    }
  }

  // UPDATE: Edit Appointment
  Future<void> updateAppointment(dynamic id, Map<String, dynamic> data) async {
    await ApiService.updateAppointment(id.toString(), data);
    
    User? user = _auth.currentUser;
    if (user != null) _refreshList(user.uid, 'Student');
  }

  // DELETE: Cancel Appointment
  Future<void> deleteAppointment(dynamic id) async {
    await ApiService.deleteAppointment(id.toString());
    
    User? user = _auth.currentUser;
    if (user != null) _refreshList(user.uid, 'Student');
  }

  void dispose() {
    _pollingTimer?.cancel();
    _appointmentStreamController.close();
  }
}
