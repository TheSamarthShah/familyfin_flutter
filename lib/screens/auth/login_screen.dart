import 'package:flutter/material.dart';
import 'package:foundation_app/l10n/app_localizations.dart';
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
  bool _isPasswordVisible = false;

  void _handleError(dynamic e) {
    // 1. Get Theme for error colors
    final theme = Theme.of(context);
    String message = "Something went wrong. Please try again.";
    
    if (e.toString().contains("Invalid login")) {
      message = "We couldn't find an account with those details.";
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: theme.colorScheme.onError)),
        backgroundColor: theme.colorScheme.error, // ✅ Adaptive Error Color
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
      await _authService.initializeUserSession();
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

    // Determine branding colors based on brightness
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? theme.colorScheme.surface : theme.colorScheme.primary;
    final onBackgroundColor = isDark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: backgroundColor, 
      body: Center(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            child: Column(
              children: [
                // 1. BRAND & EMOTION
                Icon(Icons.account_balance_wallet, size: 54, color: onBackgroundColor),
                const SizedBox(height: 16),
                Text(
                  l10n.appTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onBackgroundColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your financial peace of mind starts here.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onBackgroundColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 40),

                // 2. THE "TRUST" CARD
                Card(
                  elevation: 8,
                  shadowColor: Colors.black26, // Subtler shadow
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: theme.colorScheme.surface, // ✅ Adaptive Card Color
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
                              prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.onSurfaceVariant),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                            validator: (v) => (v == null || !v.contains('@')) ? l10n.invalidEmail : null,
                          ),
                          const SizedBox(height: 20),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: !_isPasswordVisible,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: l10n.passwordLabel,
                              prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible), 
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
                                    // Use Primary Color for Button
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: theme.colorScheme.onPrimary,
                                    ),
                                    child: _isLoading 
                                      ? SizedBox(
                                          height: 24, width: 24, 
                                          child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2)
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
                                  // ✅ Adaptive Container Color
                                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.colorScheme.outlineVariant),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.fingerprint, size: 28),
                                  color: theme.colorScheme.primary,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text("Biometrics enabled for future logins!"),
                                        backgroundColor: theme.colorScheme.inverseSurface,
                                      ),
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
                    Icon(Icons.shield_outlined, size: 14, color: onBackgroundColor.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Text(
                      "Bank-Grade 256-bit Encryption",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onBackgroundColor.withOpacity(0.7),
                      ),
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