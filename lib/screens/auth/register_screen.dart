import 'package:flutter/material.dart';
import 'package:foundation_app/l10n/app_localizations.dart';
import '../../widgets/responsive_center.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _currencyList = [];
  bool _isLoadingCurrencies = true;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _selectedCurrency;
  String _lang = 'en'; 

  bool _isPasswordVisible = false;
  
  double _passwordStrength = 0.0;
  Color _strengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _fetchCurrencyData();
  }

  Future<void> _fetchCurrencyData() async {
    final currencies = await _authService.getCurrencies();
    if (mounted) {
      setState(() {
        _currencyList = currencies;
        if (currencies.any((c) => c['code'] == 'INR')) {
          _selectedCurrency = 'INR';
        } else if (currencies.isNotEmpty) {
          _selectedCurrency = currencies.first['code'];
        }
        _isLoadingCurrencies = false;
      });
    }
  }

  void _updatePasswordStrength(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordStrength = 0.0;
        _strengthColor = Theme.of(context).colorScheme.outline; // Adaptive grey
      } else if (value.length < 6) {
        _passwordStrength = 0.3;
        _strengthColor = Theme.of(context).colorScheme.error; // Adaptive Red
      } else if (value.length < 9) {
        _passwordStrength = 0.6;
        _strengthColor = Colors.amber; // Semantic Amber (universal)
      } else {
        _passwordStrength = 1.0;
        _strengthColor = Colors.greenAccent[700]!; // Semantic Green
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrency == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _authService.registerUser(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        currencyCode: _selectedCurrency!,
        languageCode: _lang,
      );

      await _authService.initializeUserSession();

      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        String msg = "Registration failed. Please try again.";
        if (e.toString().contains("already registered")) msg = "This email is already in use.";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: TextStyle(color: theme.colorScheme.onError)), 
            backgroundColor: theme.colorScheme.error
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // ✅ Adaptive Colors (Matches Login Screen Logic)
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? theme.colorScheme.surface : theme.colorScheme.primary;
    final onBackgroundColor = isDark ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: backgroundColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: onBackgroundColor), // Adaptive Back Button
      ),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          child: Column(
            children: [
              Text(
                l10n.createAccountTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: onBackgroundColor
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.subtitle,
                style: TextStyle(fontSize: 16, color: onBackgroundColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 30),

              Card(
                elevation: 8,
                shadowColor: Colors.black26,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: theme.colorScheme.surface, // ✅ Adaptive Card
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Name
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: InputDecoration(
                            labelText: l10n.fullNameLabel,
                            prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: l10n.emailLabel,
                            prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          validator: (v) => (v != null && v.contains('@')) ? null : l10n.invalidEmail,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: !_isPasswordVisible,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: _updatePasswordStrength,
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                            prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible 
                                  ? Icons.visibility_outlined 
                                  : Icons.visibility_off_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (v) => (v != null && v.length >= 6) ? null : l10n.passwordTooShort,
                        ),
                        
                        // Visual Strength Meter (Gamification)
                        if (_passCtrl.text.isNotEmpty) 
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: LinearProgressIndicator(
                              value: _passwordStrength,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              color: _strengthColor,
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Currency Dropdown
                        _isLoadingCurrencies 
                          ? LinearProgressIndicator(color: theme.colorScheme.primary)
                          : DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              dropdownColor: theme.colorScheme.surfaceContainerHigh, // Adaptive Dropdown Menu
                              decoration: InputDecoration(
                                labelText: l10n.currencyLabel,
                                prefixIcon: Icon(Icons.currency_exchange, color: theme.colorScheme.onSurfaceVariant),
                              ),
                              items: _currencyList.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c['code'],
                                  child: Text("${c['symbol']} ${c['name']}"),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedCurrency = val),
                            ),
                        const SizedBox(height: 30),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: _isSubmitting
                              ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                              : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                  ),
                                  child: Text(l10n.getStartedBtn),
                                ),
                        ),
                      ],
                    ),
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
}