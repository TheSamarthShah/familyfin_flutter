import 'package:flutter/material.dart';
import 'package:foundation_app/core/app_theme.dart';
import 'package:foundation_app/services/finance_service.dart';
import 'package:foundation_app/services/master_data_service.dart';
import 'package:provider/provider.dart';

class AddEditAccountSheet extends StatefulWidget {
  final Map<String, dynamic>? account; // Null = New

  const AddEditAccountSheet({super.key, this.account});

  @override
  State<AddEditAccountSheet> createState() => _AddEditAccountSheetState();
}

class _AddEditAccountSheetState extends State<AddEditAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  
  // Default values matching your DB schema
  String _selectedType = 'cash'; 
  bool _isCredit = false;
  bool _isLoading = false;

  // Options matching your Postgres Enum: 
  // ('cash', 'bank', 'credit', 'wallet', 'investment', 'other')
  final List<Map<String, dynamic>> _accountTypes = [
    {'value': 'cash', 'label': 'Cash', 'icon': '💵'},
    {'value': 'bank', 'label': 'Bank Account', 'icon': '🏦'},
    {'value': 'credit', 'label': 'Credit Card', 'icon': '💳'},
    {'value': 'wallet', 'label': 'Digital Wallet', 'icon': '👛'},
    {'value': 'investment', 'label': 'Investment', 'icon': '📈'},
    {'value': 'other', 'label': 'Other', 'icon': '📁'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameCtrl.text = widget.account!['name'];
      _selectedType = widget.account!['type'] ?? 'cash';
      _isCredit = widget.account!['is_credit'] ?? false;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await FinanceService().upsertAccount(
      id: widget.account?['id'],
      name: _nameCtrl.text.trim(),
      type: _selectedType,
      isCredit: _isCredit,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.read<MasterDataProvider>().refreshDashboard();
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Find icon for currently selected type
    final currentIcon = _accountTypes.firstWhere(
      (t) => t['value'] == _selectedType,
      orElse: () => _accountTypes.last
    )['icon'];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.account == null ? "New Account" : "Edit Account",
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // --- 1. Name Input ---
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Account Name",
                hintText: "e.g. HDFC Salary",
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(currentIcon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 20),

            // --- 2. Type Selector ---
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: "Account Type"),
              items: _accountTypes.map((type) {
                // ✅ FIX: Explicitly specify DropdownMenuItem<String> and cast value
                return DropdownMenuItem<String>(
                  value: type['value'] as String, 
                  child: Row(
                    children: [
                      Text(type['icon']),
                      const SizedBox(width: 12),
                      Text(type['label']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                    // Auto-set "is_credit" if user selects Credit Card
                    if (val == 'credit') _isCredit = true;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // --- 3. Credit Switch ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Is this a debt/credit account?"),
              subtitle: const Text("Balances will be treated as liabilities."),
              value: _isCredit,
              activeColor: theme.colorScheme.error, // Red for debt
              onChanged: (val) => setState(() => _isCredit = val),
            ),
            
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Save Account"),
            ),
          ],
        ),
      ),
    );
  }
}