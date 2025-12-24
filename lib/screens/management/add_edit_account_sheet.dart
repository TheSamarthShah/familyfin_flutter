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
  final _emojiCtrl = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameCtrl.text = widget.account!['name'];
      // Handle case where icon_emoji might not exist in your old DB schema yet
      _emojiCtrl.text = widget.account!['icon_emoji'] ?? '🏦'; 
    } else {
      _emojiCtrl.text = '💳';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await FinanceService().upsertAccount(
      id: widget.account?['id'],
      name: _nameCtrl.text.trim(),
      iconEmoji: _emojiCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Refresh the Dashboard (because accounts list lives there)
        context.read<MasterDataProvider>().refreshDashboard();
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            
            Row(
              children: [
                // Emoji Icon
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _emojiCtrl,
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    decoration: const InputDecoration(
                      labelText: "Icon",
                      counterText: "",
                    ),
                    validator: (v) => v!.isEmpty ? "Req" : null,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Name
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Account Name",
                      hintText: "e.g. HDFC Bank",
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            if (widget.account == null)
              Text(
                "Tip: New accounts start with a 0 balance. Add a 'Balance Adjustment' log to set the opening balance.",
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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