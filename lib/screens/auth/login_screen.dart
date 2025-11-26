import 'package:familyfin/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../widgets/responsive_center.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  // ✨ ADDED: State variable for visibility
  bool _isPasswordVisible = false;

  // 🧠 TONE OF VOICE: Gentle Error Handling
  void _handleError(dynamic e) {
    String message = "Something went wrong. Please try again.";
    if (e.toString().contains("Invalid login")) {
      message = "We couldn't find an account with those details.";
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700], // Darker red is less aggressive
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.signIn(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      if (mounted) _handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            child: Column(
              children: [
                // 1. BRAND & EMOTION
                const Icon(Icons.account_balance_wallet, size: 54, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  l10n.appTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your financial peace of mind starts here.",
                  style: TextStyle(color: Colors.purple[100], fontSize: 16),
                ),
                const SizedBox(height: 40),

                // 2. THE "TRUST" CONTAINER
                Card(
                  elevation: 8,
                  shadowColor: Colors.black38,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.emailLabel,
                              prefixIcon: const Icon(Icons.email_outlined),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                            validator: (v) => (v == null || !v.contains('@')) ? l10n.invalidEmail : null,
                          ),
                          const SizedBox(height: 20),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: !_isPasswordVisible, // ✨ UPDATED
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: l10n.passwordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                              // ✨ UPDATED: Interactive Toggle Icon
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible 
                                    ? Icons.visibility_outlined 
                                    : Icons.visibility_off_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ), 
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                          ),
                          const SizedBox(height: 30),

                          // 3. ACTION & BIOMETRICS
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    child: _isLoading 
                                      ? const SizedBox(
                                          height: 24, width: 24, 
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                        ) 
                                      : Text(l10n.loginBtn),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Biometric Mockup
                              Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.fingerprint, size: 28),
                                  color: theme.colorScheme.primary,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Biometrics enabled for future logins!")),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            child: Text(l10n.registerLink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. SECURITY FOOTER
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Text(
                      "Bank-Grade 256-bit Encryption",
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}