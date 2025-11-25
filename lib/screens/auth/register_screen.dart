import 'package:flutter/material.dart';
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

  // Data State
  List<Map<String, dynamic>> _currencyList = [];
  bool _isLoadingCurrencies = true;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _selectedCurrency;
  String _lang = 'en'; 

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrency == null) return;

    setState(() => _isSubmitting = true);

    try {
      // ✅ UPDATED: Calling the new 'registerUser' method
      // Matches the "Solo-First" architecture (No family creation logic here)
      await _authService.registerUser(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        currencyCode: _selectedCurrency!,
        languageCode: _lang,
      );

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().contains("Exception:") 
            ? e.toString().split("Exception:").last.trim() 
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Start tracking your logs instantly.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Name
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.contains('@') ? null : "Invalid email",
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
              ),
              const SizedBox(height: 16),

              // Currency
              _isLoadingCurrencies 
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: "Currency",
                      prefixIcon: Icon(Icons.currency_exchange),
                      border: OutlineInputBorder(),
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

              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("Get Started"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}