import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/appointment_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _timeController = TextEditingController(text: '9:10');
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedFaculty;
  String _period = 'AM';
  bool _isLoadingFaculty = true;
  bool _isBooking = false;
  List<Map<String, dynamic>> _faculties = [];

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculties() async {
    try {
      final faculties = await ApiService.fetchFaculties();
      if (mounted) {
        setState(() {
          _faculties = faculties;
          _isLoadingFaculty = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFaculty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading faculty list: $e')),
        );
      }
    }
  }

  Future<void> _handleBooking() async {
    final langService = Provider.of<LanguageService>(context, listen: false);
    final timeStr = _timeController.text.trim();

    if (_formKey.currentState!.validate() && _selectedFaculty != null && _selectedDate != null && timeStr.isNotEmpty) {
      setState(() => _isBooking = true);
      try {
        final user = AuthService().currentUser;
        if (user == null) return;

        final fullTime = '$timeStr $_period';

        await AppointmentService().createAppointment({
          'studentId': user.uid,
          'studentName': AuthService().displayName,
          'facultyId': _selectedFaculty!['uid'],
          'facultyName': _selectedFaculty!['name'],
          'date': _selectedDate!.toIso8601String(),
          'time': fullTime,
          'subject': _reasonController.text.trim(),
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(langService.translate('booking_success')),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isBooking = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(langService.translate('please_complete_all_fields'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(langService.translate('book_appointment')),
      ),
      body: _isLoadingFaculty 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langService.translate('select_faculty'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: InputDecoration(
                    hintText: langService.translate('choose_professor'),
                  ),
                  value: _selectedFaculty,
                  items: _faculties.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(langService.tryTranslate(f['name'] ?? 'Unknown Faculty')),
                  )).toList(),
                  onChanged: (val) => setState(() {
                    _selectedFaculty = val;
                  }),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  langService.translate('select_date'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedDate == null 
                          ? langService.translate('choose_date')
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  langService.translate('available_time_slots'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        decoration: InputDecoration(
                          hintText: '9:10',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.datetime,
                        validator: (val) => val == null || val.isEmpty ? 'Please enter time' : null,
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
                
                const SizedBox(height: 24),
                
                Text(
                  langService.translate('reason_for_appointment'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: langService.translate('purpose_hint'),
                  ),
                  validator: (val) => val == null || val.isEmpty ? langService.translate('please_select_reason') : null,
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: _isBooking ? null : _handleBooking,
                  child: _isBooking 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(langService.translate('confirm_booking')),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
