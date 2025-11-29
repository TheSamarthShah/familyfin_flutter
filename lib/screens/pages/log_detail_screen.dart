import 'package:familyfin/screens/pages/edit_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/user_service.dart';

class LogDetailSheet extends StatelessWidget {
  final Map<String, dynamic> log;

  const LogDetailSheet({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencySymbol = UserService().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    
    final bool isExpense = log['type'] == 'expense';
    final color = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final amount = (log['amount'] as num).toDouble();
    final date = DateTime.parse(log['log_date']);

    // Create a full combined date string
    final fullDateString = "${DateFormat('EEE, MMM d, y').format(date)} at ${DateFormat('h:mm a').format(date)}";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER (Icon + Amount)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(log['icon_emoji'] ?? "📄", style: const TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "${isExpense ? '-' : '+'}${currencyFormat.format(amount)}",
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              color: color, 
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            log['item_name'] ?? "Unknown Item",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 30),

          // 2. VOICE NOTE (If available)
          if (log['original_text'] != null && log['original_text'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.mic, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text("Voice Note", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "\"${log['original_text']}\"",
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                  ),
                ],
              ),
            ),

          // 3. DETAILS GRID
          Row(
            children: [
              _buildDetailItem("Category", log['category_name'] ?? "General", Icons.category_outlined),
              _buildDetailItem("Account", log['account_name'] ?? "Cash", Icons.account_balance_wallet_outlined),
            ],
          ),
          const SizedBox(height: 16),
          
          // ✅ CHANGED: Combined Date & Time into one Full Width row to prevent cutoff
          Row(
            children: [
               _buildDetailItem("Date & Time", fullDateString, Icons.calendar_today_outlined, isFullWidth: true),
            ],
          ),

          if (log['location_name'] != null) ...[
            const SizedBox(height: 16),
            _buildDetailItem("Location", log['location_name'], Icons.location_on_outlined, isFullWidth: true),
          ],

          const SizedBox(height: 30),
          
          // 4. ACTIONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
  // Close the sheet first
  Navigator.pop(context);
  
  // Navigate to Edit Screen
  final bool? result = await Navigator.push(
    context, 
    MaterialPageRoute(builder: (_) => EditLogScreen(log: log)),
  );
  
  // Note: The sheet is already closed, but if the parent screen 
  // needs to refresh, you might need to handle the result in the parent of the sheet.
}, 
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                     // Close sheet and return 'true' to indicate deletion/refresh needed
                     // Note: You need to implement the actual delete logic in the parent or here
                     Navigator.pop(context, true); 
                  }, 
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("Delete", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: const BorderSide(color: Colors.red),
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

  Widget _buildDetailItem(String label, String value, IconData icon, {bool isFullWidth = false}) {
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    value, 
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    // ✅ CHANGED: Removed maxLines: 1 so text can wrap if needed
                    // maxLines: 1, 
                    // overflow: TextOverflow.ellipsis
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