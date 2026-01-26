import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedFaculty;
  String? _selectedTime;

  final List<String> _faculties = [
    'Dr. Sarah Johnson (CS)',
    'Prof. Michael Chen (Math)',
    'Dr. Emily Rodriguez (Physics)',
    'Prof. James Wilson (CS)',
    'Dr. Lisa Wang (AI)'
  ];

  final List<String> _timeSlots = [
    '09:00 AM', '10:00 AM', '11:00 AM',
    '02:00 PM', '03:00 PM', '04:00 PM'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
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
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Choose a professor',
                  ),
                  items: _faculties.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) => setState(() => _selectedFaculty = val),
                  validator: (val) => val == null ? 'Please select a faculty' : null,
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Select Date',
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
                  children: _timeSlots.map((time) {
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
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Briefly describe your purpose (e.g., Project discussion)',
                  ),
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Appointment Requested Successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please complete all fields')),
                      );
                    }
                  },
                  child: const Text('Confirm Booking'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
