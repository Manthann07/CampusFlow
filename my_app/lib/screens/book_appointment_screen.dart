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
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(langService.translate('booking_success')),
              ]),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isBooking = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(langService.translate('please_complete_all_fields')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langService = Provider.of<LanguageService>(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(langService.translate('book_appointment')),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoadingFaculty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step indicator
                    _buildStepHeader(langService),
                    const SizedBox(height: 24),

                    // ── Faculty ──────────────────────────────────
                    _buildSectionLabel(langService.translate('select_faculty'), Icons.person_search_outlined),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: InputDecoration(
                          hintText: langService.translate('choose_professor'),
                          hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(
                            _selectedFaculty != null ? Icons.check_circle : Icons.person_outline,
                            size: 20,
                            color: _selectedFaculty != null ? AppTheme.successColor : AppTheme.textSecondary,
                          ),
                        ),
                        value: _selectedFaculty,
                        isExpanded: true,
                        items: _faculties.map((f) => DropdownMenuItem(
                          value: f,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  (f['name'] ?? 'F').substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  langService.tryTranslate(f['name'] ?? 'Unknown Faculty'),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedFaculty = val),
                        validator: (v) => v == null ? langService.translate('select_faculty') : null,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Date ─────────────────────────────────────
                    _buildSectionLabel(langService.translate('select_date'), Icons.calendar_month_outlined),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
                            ),
                            child: child!,
                          ),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedDate != null
                              ? AppTheme.primaryColor.withOpacity(0.05)
                              : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedDate != null ? AppTheme.primaryColor.withOpacity(0.4) : Colors.grey.shade200,
                            width: _selectedDate != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.today_outlined,
                              size: 20,
                              color: _selectedDate != null ? AppTheme.primaryColor : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate == null
                                  ? langService.translate('choose_date')
                                  : '${_dayName(_selectedDate!)}, ${_selectedDate!.day} ${_monthName(_selectedDate!)} ${_selectedDate!.year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDate != null ? AppTheme.textPrimary : AppTheme.textLight,
                                fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_drop_down,
                              color: _selectedDate != null ? AppTheme.primaryColor : AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Time ──────────────────────────────────────
                    _buildSectionLabel(langService.translate('available_time_slots'), Icons.schedule_outlined),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_outlined, size: 20, color: AppTheme.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _timeController,
                              keyboardType: TextInputType.datetime,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: '9:10',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Please enter time' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // AM/PM Segmented control
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: ['AM', 'PM'].map((p) {
                                final selected = _period == p;
                                return GestureDetector(
                                  onTap: () => setState(() => _period = p),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected ? AppTheme.primaryColor : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p,
                                      style: TextStyle(
                                        color: selected ? Colors.white : AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Reason ────────────────────────────────────
                    _buildSectionLabel(langService.translate('reason_for_appointment'), Icons.notes_outlined),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: langService.translate('purpose_hint'),
                        hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.errorColor),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty ? langService.translate('please_select_reason') : null,
                    ),

                    const SizedBox(height: 36),

                    // ── Submit ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isBooking ? null : _handleBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isBooking
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_today, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    langService.translate('confirm_booking'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepHeader(LanguageService langService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.08), AppTheme.secondaryColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_available_outlined, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Appointment',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                Text('Fill in the details below to request a meeting',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) => Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
        ],
      );

  String _dayName(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  String _monthName(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[d.month - 1];
  }
}
