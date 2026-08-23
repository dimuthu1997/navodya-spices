import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.customer;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isSignUpMode = false;
  bool _usePinMode = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handlePinLogin(AppProvider provider) {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter your 4-digit Staff PIN code.');
      return;
    }

    final success = provider.loginWithPin(pin);
    if (!success) {
      setState(() => _errorMessage = 'Invalid Staff PIN. Default Admin: 0468 | Cashier: 9710');
    } else {
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _handleEmailAuth(AppProvider provider) async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address and password.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    if (_isSignUpMode) {
      final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Customer';
      // Real-world security: Public registrations are strictly Customer accounts!
      final success = await provider.registerUser(
        name: name,
        email: email,
        password: pass,
        role: UserRole.customer,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Customer Account created successfully! Logged in.'),
              backgroundColor: AppTheme.cardamomGreen,
            ),
          );
        } else {
          setState(() => _errorMessage = 'Failed to create account. Password must be at least 6 characters.');
        }
      }
    } else {
      final success = await provider.loginWithEmail(email, pass);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚡ Logged in successfully!'),
              backgroundColor: AppTheme.cardamomGreen,
            ),
          );
        } else {
          setState(() => _errorMessage = 'Invalid email or password. Please check your credentials.');
        }
      }
    }
  }

  void _handleSocialLogin(AppProvider provider, String providerName) async {
    setState(() => _errorMessage = '');
    final ok = await provider.loginWithSocialProvider(providerName);
    if (mounted) {
      if (ok) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Logged in successfully via $providerName Auth!'),
            backgroundColor: AppTheme.cardamomGreen,
          ),
        );
      } else {
        setState(() => _errorMessage = 'Failed to authenticate with $providerName.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 440,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
              border: Border.all(
                color: AppTheme.royalGoldPrimary.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row with Close Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    // Logo Image
                    ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.dry_cleaning, size: 50, color: AppTheme.royalGoldPrimary),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded, size: 22),
                      tooltip: 'Close Modal',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'NAVODYA SPICES',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const Text(
                  'නාවෝද්‍යා කුළුබඩු • ONLINE PORTAL',
                  style: TextStyle(fontSize: 11, color: AppTheme.royalGoldPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Auth Mode Tabs (LOG IN vs CREATE ACCOUNT)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _isSignUpMode = false;
                            _errorMessage = '';
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isSignUpMode ? AppTheme.royalGoldPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'LOG IN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isSignUpMode ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _isSignUpMode = true;
                            _usePinMode = false;
                            _selectedRole = UserRole.customer;
                            _errorMessage = '';
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isSignUpMode ? AppTheme.royalGoldPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'CREATE ACCOUNT',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isSignUpMode ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Registration Mode Security Notice
                if (_isSignUpMode)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.royalGoldPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.royalGoldPrimary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.person_add_outlined, color: AppTheme.royalGoldPrimary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '✨ Customer Registration (Staff/Admin accounts are assigned by system management).',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Staff PIN Mode Indicator Banner
                if (!_isSignUpMode && _usePinMode)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardamomGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardamomGreen.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.pin, color: AppTheme.cardamomGreen, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Staff PIN Access Mode',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cardamomGreen),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => setState(() => _usePinMode = false),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          child: const Text('Use Email', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                // Error Message Banner
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12))),
                      ],
                    ),
                  ),

                // Sign Up Full Name Field
                if (_isSignUpMode) ...[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Form Inputs: PIN Code vs Email & Password
                if (!_isSignUpMode && _usePinMode) ...[
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 10),
                    decoration: InputDecoration(
                      hintText: '••••',
                      counterText: '',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalGoldPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _handlePinLogin(provider),
                      child: const Text(
                        'LOGIN WITH STAFF PIN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address *',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalGoldPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSubmitting ? null : () => _handleEmailAuth(provider),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _isSignUpMode ? 'CREATE CUSTOMER ACCOUNT' : 'LOG IN TO ACCOUNT',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                    ),
                  ),
                ],

                // Staff PIN Mode Button (For Admins & Cashiers)
                if (!_isSignUpMode && !_usePinMode) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => setState(() => _usePinMode = true),
                    icon: const Icon(Icons.pin, size: 16, color: AppTheme.royalGoldPrimary),
                    label: const Text(
                      'Staff & Admin PIN Login',
                      style: TextStyle(color: AppTheme.royalGoldPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('OR CONNECT WITH', style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 14),

                // Social Single Sign-On SSO Buttons (Google, Facebook, Apple)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _handleSocialLogin(provider, 'Google'),
                        icon: const Icon(Icons.g_mobiledata, color: Colors.redAccent, size: 22),
                        label: const Text('Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _handleSocialLogin(provider, 'Facebook'),
                        icon: const Icon(Icons.facebook, color: Colors.blue, size: 18),
                        label: const Text('Facebook', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
