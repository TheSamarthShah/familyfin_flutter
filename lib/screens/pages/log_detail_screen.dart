import 'package:foundation_app/screens/pages/edit_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/finance_service.dart';

class LogDetailSheet extends StatelessWidget {
  final Map<String, dynamic> log;

  const LogDetailSheet({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencySymbol = UserService().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    
    // --- DETERMINE TYPE ---
    final String type = log['type'] ?? 'expense';
    final bool isTransfer = type == 'transfer';
    final bool isExpense = type == 'expense';

    // --- DETERMINE COLORS & ICONS ---
    Color color;
    String emoji;
    String sign;

    if (isTransfer) {
      color = Colors.blue;
      emoji = "💸"; // Transfer Symbol
      sign = "";
    } else if (isExpense) {
      color = AppTheme.expenseColor;
      emoji = log['icon_emoji'] ?? "📄";
      sign = "-";
    } else {
      color = AppTheme.incomeColor;
      emoji = log['icon_emoji'] ?? "💰";
      sign = "+";
    }

    final amount = (log['amount'] as num).toDouble();
    final date = DateTime.parse(log['log_date']);
    final fullDateString = "${DateFormat('EEE, MMM d, y').format(date)} at ${DateFormat('h:mm a').format(date)}";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, 
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "$sign${currencyFormat.format(amount)}",
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              color: color, 
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            log['item_name'] ?? (isTransfer ? "Transfer" : "Unknown Item"),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: 30),

          // 2. VOICE NOTE (If available)
          if (log['original_text'] != null && log['original_text'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mic, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text("Voice Note", style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("\"${log['original_text']}\"", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16, color: theme.colorScheme.onSurface)),
                ],
              ),
            ),

          // 3. DETAILS GRID (✅ UPDATED FOR TRANSFER)
          if (isTransfer) 
            // --- TRANSFER LAYOUT ---
            Row(
              children: [
                _buildDetailItem(theme, "From Account", log['account_name'] ?? "Unknown", Icons.arrow_upward_rounded),
                _buildDetailItem(theme, "To Account", log['target_account_name'] ?? "Unknown", Icons.arrow_downward_rounded),
              ],
            )
          else 
            // --- STANDARD LAYOUT ---
            Row(
              children: [
                _buildDetailItem(theme, "Category", log['category_name'] ?? "General", Icons.category_outlined),
                _buildDetailItem(theme, "Account", log['account_name'] ?? "Cash", Icons.account_balance_wallet_outlined),
              ],
            ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildDetailItem(theme, "Date & Time", fullDateString, Icons.calendar_today_outlined, isFullWidth: true),
            ],
          ),

         /* if (log['location_name'] != null) ...[
            const SizedBox(height: 16),
            _buildDetailItem(theme, "Location", log['location_name'], Icons.location_on_outlined, isFullWidth: true),
          ],*/

          const SizedBox(height: 30),
          
          // 4. ACTIONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final bool? result = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => EditLogScreen(log: log)),
                    );
                    if (context.mounted) {
                      Navigator.pop(context, result); 
                    }
                  }, 
                  icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                  label: Text("Edit", style: TextStyle(color: theme.colorScheme.primary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Log?"),
                        content: const Text("Are you sure you want to delete this transaction?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text("Delete", style: TextStyle(color: theme.colorScheme.error)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await FinanceService().deleteLog(log['id']);
                        if (context.mounted) Navigator.pop(context, true); 
                      } catch (e) {
                         debugPrint("Error deleting log: $e");
                      }
                    }
                  }, 
                  icon: Icon(Icons.delete, color: theme.colorScheme.error),
                  label: Text("Delete", style: TextStyle(color: theme.colorScheme.error)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailItem(ThemeData theme, String label, String value, IconData icon, {bool isFullWidth = false}) {
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label, 
                    style: TextStyle(
                      fontSize: 11, 
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8), 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value, 
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}