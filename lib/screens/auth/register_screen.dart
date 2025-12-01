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

  // ✨ ADDED: State variable for visibility
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
        _strengthColor = Colors.grey;
      } else if (value.length < 6) {
        _passwordStrength = 0.3;
        _strengthColor = Colors.redAccent;
      } else if (value.length < 9) {
        _passwordStrength = 0.6;
        _strengthColor = Colors.amber;
      } else {
        _passwordStrength = 1.0;
        _strengthColor = Colors.greenAccent; // Visual reward
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrency == null) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Register
      await _authService.registerUser(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        currencyCode: _selectedCurrency!,
        languageCode: _lang,
      );

      // 2. ✅ Initialize Session Data
      // (Even though we just sent it, we need to fetch the joined 'symbol' from the DB)
      await _authService.initializeUserSession();

      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } catch (e) {
      if (mounted) {
        String msg = "Registration failed. Please try again.";
        if (e.toString().contains("already registered")) msg = "This email is already in use.";
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red[700]));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white), // Back Anchor
      ),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          child: Column(
            children: [
              Text(
                l10n.createAccountTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.subtitle,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 30),

              Card(
                elevation: 8,
                shadowColor: Colors.black38,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: InputDecoration(
                            labelText: l10n.fullNameLabel,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: l10n.emailLabel,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (v) => (v != null && v.contains('@')) ? null : l10n.invalidEmail,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passCtrl,
                          obscureText: !_isPasswordVisible, // ✨ UPDATED
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: _updatePasswordStrength,
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
                          validator: (v) => (v != null && v.length >= 6) ? null : l10n.passwordTooShort,
                        ),
                        
                        // Visual Strength Meter (Gamification)
                        if (_passCtrl.text.isNotEmpty) 
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: LinearProgressIndicator(
                              value: _passwordStrength,
                              backgroundColor: Colors.grey[200],
                              color: _strengthColor,
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                        const SizedBox(height: 16),

                        _isLoadingCurrencies 
                          ? const LinearProgressIndicator()
                          : DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              decoration: InputDecoration(
                                labelText: l10n.currencyLabel,
                                prefixIcon: const Icon(Icons.currency_exchange),
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

                        SizedBox(
                          width: double.infinity,
                          child: _isSubmitting
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
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