import 'package:flutter/material.dart';
import 'package:foundation_app/core/app_theme.dart'; // Import your theme file
import 'package:foundation_app/services/finance_service.dart';
import 'package:foundation_app/services/master_data_service.dart';
import 'package:provider/provider.dart';

class AddEditCategorySheet extends StatefulWidget {
  final Map<String, dynamic>? category; // Null = New

  const AddEditCategorySheet({super.key, this.category});

  @override
  State<AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends State<AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController();
  
  String _type = 'expense';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!['name'];
      _emojiCtrl.text = widget.category!['icon_emoji'] ?? '🏷️';
      _type = widget.category!['type'] ?? 'expense';
    } else {
      // Default emoji for new items
      _emojiCtrl.text = '🏷️';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await FinanceService().upsertCategory(
      id: widget.category?['id'],
      name: _nameCtrl.text.trim(),
      iconEmoji: _emojiCtrl.text.trim(),
      type: _type,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.read<MasterDataProvider>().refreshCategories();
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use your custom colors from AppTheme
    final incomeColor = AppTheme.incomeColor;
    final expenseColor = AppTheme.expenseColor;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, 
        right: 20, 
        top: 20
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.category == null ? "New Category" : "Edit Category",
              style: theme.textTheme.titleLarge, 
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // --- 1. Type Selector (Chips) ---
            Row(
              children: [
                _buildTypeChip("Expense", 'expense', expenseColor),
                const SizedBox(width: 12),
                _buildTypeChip("Income", 'income', incomeColor),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 2. Emoji Input ---
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _emojiCtrl,
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    decoration: const InputDecoration(
                      labelText: "Icon",
                      counterText: "",
                      // Input decoration comes from AppTheme automatically
                    ),
                    validator: (v) => v!.isEmpty ? "Req" : null,
                  ),
                ),
                const SizedBox(width: 16),
                
                // --- 3. Name Input ---
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: "Category Name",
                      hintText: "e.g. Groceries",
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- 4. Save Button ---
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              // Style comes from AppTheme automatically
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Save Category"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, Color color) {
    final isSelected = _type == value;
    final theme = Theme.of(context);

    return Expanded(
      child: FilterChip(
        label: Center(child: Text(label)),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) setState(() => _type = value);
        },
        // Styling matches your AppTheme identity
        checkmarkColor: Colors.white,
        selectedColor: color,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
          side: BorderSide(
            color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
    );
  }
}