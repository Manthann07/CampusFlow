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
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedFaculty;
  String? _selectedTime;
  bool _isLoadingFaculty = true;
  bool _isBooking = false;
  List<Map<String, dynamic>> _faculties = [];

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    try {
      final faculties = await ApiService.fetchAllFaculties();
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

  List<String> get _timeSlots {
    if (_selectedFaculty == null) return [];
    
    final availability = _selectedFaculty?['availability'];
    if (availability == null || !(availability['enabled'] ?? true)) {
      return [];
    }

    final int start = availability['startHour'] ?? 9;
    final int end = availability['endHour'] ?? 17;
    
    List<String> slots = [];
    for (int i = start; i < end; i++) {
        final String hourStr = i > 12 ? '${i - 12}:00 PM' : '$i:00 ${i == 12 ? 'PM' : 'AM'}';
        slots.add(hourStr);
    }
    return slots;
  }

  Future<void> _handleBooking() async {
    final langService = Provider.of<LanguageService>(context, listen: false);
    if (_formKey.currentState!.validate() && _selectedFaculty != null && _selectedDate != null && _selectedTime != null) {
      setState(() => _isBooking = true);
      try {
        final user = AuthService().currentUser;
        if (user == null) return;

        await AppointmentService().createAppointment({
          'studentUid': user.uid,
          'studentName': AuthService().displayName,
          'facultyUid': _selectedFaculty!['uid'],
          'facultyName': _selectedFaculty!['name'],
          'date': _selectedDate!.toIso8601String(),
          'time': _selectedTime,
          'reason': _reasonController.text.trim(),
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
                    _selectedTime = null;
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
                if (_selectedFaculty == null)
                  Text(langService.translate('please_select_faculty'), style: const TextStyle(color: Colors.grey))
                else if (_timeSlots.isEmpty)
                  Text(langService.translate('not_accepting_appointments'), style: const TextStyle(color: AppTheme.errorColor))
                else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _timeSlots.map((slot) {
                    final isSelected = _selectedTime == slot;
                    return ChoiceChip(
                      label: Text(slot),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedTime = val ? slot : null),
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    );
                  }).toList(),
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
