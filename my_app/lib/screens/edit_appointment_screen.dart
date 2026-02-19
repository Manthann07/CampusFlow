import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/appointment_service.dart';
import '../services/api_service.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const EditAppointmentScreen({super.key, required this.appointment});

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  late TextEditingController _timeController;
  late TextEditingController _subjectController;
  String _period = 'AM';
  bool _isUpdating = false;
  Map<String, dynamic>? _freshData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final timeStr = widget.appointment['time']?.toString() ?? '';
    _timeController = TextEditingController(text: timeStr.split(' ').first);
    _period = timeStr.contains('PM') ? 'PM' : 'AM';
    _subjectController = TextEditingController(text: widget.appointment['subject'] ?? widget.appointment['reason'] ?? '');
    _loadFreshData();
  }

  Future<void> _loadFreshData() async {
    final String id = widget.appointment['id']?.toString() ?? widget.appointment['_id']?.toString() ?? '';
    final data = await ApiService.fetchSingleAppointment(id);
    if (mounted) {
      setState(() {
        _freshData = data ?? widget.appointment;
        _isLoading = false;
        final freshTime = _freshData!['time']?.toString() ?? '';
        _timeController.text = freshTime.split(' ').first;
        _period = freshTime.contains('PM') ? 'PM' : 'AM';
      });
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_timeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter time')));
      return;
    }

    setState(() => _isUpdating = true);
    
    try {
      final String id = widget.appointment['id']?.toString() ?? widget.appointment['_id']?.toString() ?? '';
      await AppointmentService().updateAppointment(
        id,
        {
          'time': '${_timeController.text.trim()} $_period',
          'subject': _subjectController.text.trim(),
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment updated successfully'), backgroundColor: AppTheme.successColor),
        );
        Navigator.pop(context, true); // Return true to indicate update happened
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = _freshData?['status']?.toString().toLowerCase() ?? 'pending';
    final rejectionReason = _freshData?['rejectionReason'];
    final isRejected = status.contains('reject');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Appointment'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Faculty:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(_freshData?['facultyName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Text('Date:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(_freshData?['date'] ?? 'No date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (isRejected && rejectionReason != null && rejectionReason.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.report_problem_outlined, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Faculty Feedback:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(rejectionReason, style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),

              Text('Purpose of Meeting', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Project Review',
                  prefixIcon: Icon(Icons.subject),
                ),
              ),

              const SizedBox(height: 24),

              Text('Preferred Time', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 11:30',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: 'AM',
                        groupValue: _period,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => setState(() => _period = val!),
                      ),
                      const Text('AM'),
                      Radio<String>(
                        value: 'PM',
                        groupValue: _period,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) => setState(() => _period = val!),
                      ),
                      const Text('PM'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isUpdating ? null : _handleUpdate,
                child: _isUpdating 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
              ),
              
              const SizedBox(height: 16),
              
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
