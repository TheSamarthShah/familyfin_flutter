import 'package:flutter/material.dart';
import 'package:foundation_app/core/app_theme.dart';
import 'package:foundation_app/services/finance_service.dart';
import 'package:foundation_app/services/master_data_service.dart';
import 'package:provider/provider.dart';
import 'add_edit_account_sheet.dart';

class AccountListScreen extends StatelessWidget {
  const AccountListScreen({super.key});

  static const String _defaultIcon = '🏦';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<MasterDataProvider>();
    final accounts = provider.accounts;

    return Scaffold(
      // Background handled by AppTheme
      appBar: AppBar(
        title: const Text("Manage Accounts"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () => _openSheet(context, null),
            icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            tooltip: "Add Account",
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTotalCard(context, provider.netWorth),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "My Accounts"),
          
          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text("No accounts found.")),
            )
          else
            ...accounts.map((acc) => _buildAccountTile(context, acc)),
        ],
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, double total) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            "Total Net Worth",
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "\$${total.toStringAsFixed(2)}", // You can use your currency formatter here
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, Map<String, dynamic> account) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // LOGIC: Check if it is the "Cash" account
    final isDefaultCash = account['name'].toString().toLowerCase() == 'cash';

    final String displayIcon = (account['icon_emoji'] != null) 
        ? account['icon_emoji'] 
        : _defaultIcon;

    final double balance = (account['balance'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(displayIcon, style: const TextStyle(fontSize: 22)),
        ),
        title: Text(
          account['name'],
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "Balance: ${balance.toStringAsFixed(2)}",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: isDefaultCash
          ? Tooltip(
              message: "Default Account (Cannot Delete)",
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock, size: 18, color: colorScheme.onSurfaceVariant),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: colorScheme.onSurfaceVariant),
                  onPressed: () => _openSheet(context, account),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: () => _deleteAccount(context, account['id']),
                ),
              ],
            ),
      ),
    );
  }

  void _openSheet(BuildContext context, Map<String, dynamic>? account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AddEditAccountSheet(account: account),
    );
  }

  Future<void> _deleteAccount(BuildContext context, String id) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: const Text("Delete Account?"),
        content: Text(
          "This will delete the account. All logs associated with this account will remain but might look broken.",
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Delete", style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FinanceService().deleteAccount(id);
      if (context.mounted) {
        context.read<MasterDataProvider>().refreshDashboard();
      }
    }
  }
}