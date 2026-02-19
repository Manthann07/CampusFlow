import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedRole = 'Student';
  final List<String> _roles = ['Student', 'Faculty'];
  bool _agreeToTerms = false;
  bool _subscribeNewsletter = true;
  String _yearOfStudy = '1st Year';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _selectedRole,
          extraData: {
            'yearOfStudy': _selectedRole == 'Student' ? _yearOfStudy : null,
            'notificationsEnabled': _subscribeNewsletter,
          },
        );
        await _authService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Account created! Please sign in.'),
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
              content: Text(e.toString()),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── COMPACT TOP BAR ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Create Account',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Join CampusFlow and streamline your campus life',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),
              ),

              // ── FORM ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!AuthService().isFirebaseAvailable)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Demo Mode — results will be simulated.',
                                    style: TextStyle(color: Colors.amber, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),

                      // ── Role selector (chips) ────────────────────
                      _buildLabel('I am a'),
                      const SizedBox(height: 10),
                      Row(
                        children: _roles.map((role) {
                          final selected = _selectedRole == role;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = role),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.only(right: role == 'Student' ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? AppTheme.primaryColor : Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      role == 'Student' ? Icons.school_outlined : Icons.person_outline,
                                      size: 18,
                                      color: selected ? Colors.white : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      role,
                                      style: TextStyle(
                                        color: selected ? Colors.white : AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Full Name
                      _buildLabel('Full Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDeco('Enter your full name', Icons.person_outline),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
                      ),

                      const SizedBox(height: 16),

                      // Email
                      _buildLabel('Email Address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDeco('Enter your email', Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password
                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDeco('Create a password', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 20, color: AppTheme.textSecondary),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter a password';
                          if (v.length < 6) return 'Must be at least 6 characters';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      _buildLabel('Confirm Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: _inputDeco('Confirm your password', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: 20, color: AppTheme.textSecondary),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm your password';
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),

                      // Year of Study (chips for students)
                      if (_selectedRole == 'Student') ...[
                        const SizedBox(height: 20),
                        _buildLabel('Year of Study'),
                        const SizedBox(height: 10),
                        Row(
                          children: ['1st Year', '2nd Year', '3rd Year', '4th Year'].map((year) {
                            final selected = _yearOfStudy == year;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _yearOfStudy = year),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected ? AppTheme.primaryColor : Colors.grey.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    year.replaceAll(' Year', ''),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Notifications toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: SwitchListTile.adaptive(
                          title: const Text('Enable Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Receive appointment updates', style: TextStyle(fontSize: 12)),
                          value: _subscribeNewsletter,
                          onChanged: (val) => setState(() => _subscribeNewsletter = val),
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Terms checkbox
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _agreeToTerms ? AppTheme.primaryColor.withOpacity(0.4) : Colors.grey.shade200,
                          ),
                        ),
                        child: CheckboxListTile(
                          title: RichText(
                            text: const TextSpan(
                              text: 'I agree to the ',
                              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                              children: [
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          value: _agreeToTerms,
                          onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                          activeColor: AppTheme.primaryColor,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Sign Up button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: (_isLoading || !_agreeToTerms) ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                            child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      );

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textLight),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
        ),
      );
}
