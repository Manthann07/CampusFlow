import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
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

  List<String> get _timeSlots {
    if (_selectedFaculty == null) return [];
    
    final availability = _selectedFaculty?['availability'];
    if (availability == null) {
        // Default 9-5
        return ['09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', '02:00 PM', '03:00 PM', '04:00 PM'];
    }

    // Check if enabled
    if (availability['enabled'] == false) return [];

    int start = availability['startHour'] ?? 9;
    int end = availability['endHour'] ?? 17;
    List<String> slots = [];
    
    for (int i = start; i < end; i++) {
      if (i == 13) continue; // Skip lunch 1PM usually
      final hour = i > 12 ? i - 12 : i;
      final ampm = i >= 12 ? 'PM' : 'AM';
      slots.add('${hour.toString().padLeft(2, '0')}:00 $ampm');
    }
    return slots;
  }

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculties() async {
    try {
      final list = await AuthService().getFacultyList();
      if (mounted) {
        setState(() {
          _faculties = list;
          _isLoadingFaculty = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading faculties: $e");
      if (mounted) {
        setState(() {
          _isLoadingFaculty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load faculty: $e')),
        );
      }
    }
  }

  Future<void> _handleBooking() async {
    if (_formKey.currentState!.validate() && 
        _selectedDate != null && 
        _selectedTime != null && 
        _selectedFaculty != null) {
      
      setState(() => _isBooking = true);
      
      try {
        await AppointmentService().createAppointment(
          facultyId: _selectedFaculty!['uid'],
          facultyName: _selectedFaculty!['name'],
          date: '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          time: _selectedTime!,
          subject: _reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment Requested Successfully!'),
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
        const SnackBar(content: Text('Please complete all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: _isLoadingFaculty 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select Faculty',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (_faculties.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(child: Text('No faculty found in MongoDB database. Ensure they registered as Faculty.', style: TextStyle(fontSize: 12))),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Choose a professor',
                    ),
                    value: _selectedFaculty,
                    items: _faculties.map((f) => DropdownMenuItem(
                      value: f, 
                      child: Text('${f['name']} (${f['department'] ?? 'Dept'})')
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedFaculty = val;
                        _selectedTime = null; // Reset time when faculty changes
                        _selectedDate = null; // Reset date
                      });
                    },
                    validator: (val) => val == null ? 'Please select a faculty' : null,
                  ),
                  
                 if (_selectedFaculty != null && _selectedFaculty?['availability']?['enabled'] == false)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        "This faculty is currently not accepting appointments.",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Select Date',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final availability = _selectedFaculty?['availability'];
                    final List<dynamic> allowedDays = availability?['days'] ?? [1, 2, 3, 4, 5]; // Default Mon-Fri
                    
                    DateTime start = DateTime.now().add(const Duration(days: 1));
                    DateTime end = DateTime.now().add(const Duration(days: 30));
                    
                    // Find first valid date for initialDate
                    DateTime initialDate = start;
                    while (!allowedDays.contains(initialDate.weekday) && initialDate.isBefore(end)) {
                      initialDate = initialDate.add(const Duration(days: 1));
                    }

                    if (initialDate.isAfter(end)) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No available dates found for this faculty in the next 30 days.'))
                       );
                       return;
                    }

                    final date = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime.now(),
                      lastDate: end,
                      selectableDayPredicate: (day) {
                        return allowedDays.contains(day.weekday);
                      },
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null 
                            ? 'Choose a date' 
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: TextStyle(
                            color: _selectedDate == null ? AppTheme.textLight : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Available Time Slots',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _timeSlots.isEmpty 
                    ? [const Text("No slots available/Select Faculty first", style: TextStyle(color: Colors.grey))] 
                    : _timeSlots.map((time) {
                    final isSelected = _selectedTime == time;
                    return ChoiceChip(
                      label: Text(time),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedTime = selected ? time : null);
                      },
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Reason for Appointment',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Briefly describe your purpose (e.g., Project discussion)',
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter a reason' : null,
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: _isBooking ? null : _handleBooking,
                  child: _isBooking 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Booking'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
