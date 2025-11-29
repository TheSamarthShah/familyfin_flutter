import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/user_service.dart'; // ✅ Import UserService

// --- ZONE A: HERO HEADER ---
class BalanceHero extends StatelessWidget {
  final double balance;
  final bool isHidden;
  final VoidCallback onTogglePrivacy;

  const BalanceHero({
    super.key,
    required this.balance,
    required this.isHidden,
    required this.onTogglePrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // ✅ FIX: Use User's preferred currency symbol
    final currencyFormat = NumberFormat.currency(
      symbol: UserService().currencySymbol, 
      decimalDigits: 2
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Net Worth", 
                style: TextStyle(color: Colors.purple[100], fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility, color: Colors.purple[100]),
                onPressed: onTogglePrivacy,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isHidden ? "••••••" : currencyFormat.format(balance),
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontSize: 40,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// --- ZONE B: ACTION CARD ---
class ActionRequiredCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const ActionRequiredCard({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_edu, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Verify Transactions",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "$count drafts waiting for review",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- ZONE C: MONTHLY PULSE ---
class MonthlyPulse extends StatelessWidget {
  final double income;
  final double expense;

  const MonthlyPulse({super.key, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Compact currency with User Symbol (e.g. $1.2K or ₹1.2L)
    final currencyFormat = NumberFormat.compactCurrency(symbol: UserService().currencySymbol);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Income", 
              currencyFormat.format(income), 
              AppTheme.incomeColor,
              Icons.arrow_downward
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              "Expense", 
              currencyFormat.format(expense), 
              AppTheme.expenseColor,
              Icons.arrow_upward
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87
            ),
          ),
        ],
      ),
    );
  }
}

// --- ZONE D: ACCOUNTS RAIL ---
class AccountsRail extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;

  const AccountsRail({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final acc = accounts[index];
          return _buildAccountCard(context, acc);
        },
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Map<String, dynamic> account) {
    // ✅ FIX: Compact currency with User Symbol
    final currencyFormat = NumberFormat.compactCurrency(symbol: UserService().currencySymbol);
    
    final balance = (account['balance'] as num).toDouble();
    final type = account['type'] ?? 'cash';
    
    IconData icon = Icons.account_balance_wallet;
    if (type == 'bank') icon = Icons.account_balance;
    if (type == 'credit') icon = Icons.credit_card;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account['name'] ?? "Unknown",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormat.format(balance),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- QUICK ACTIONS ---
class QuickActions extends StatelessWidget {
  final VoidCallback onVoice;
  final VoidCallback onManual;

  const QuickActions({super.key, required this.onVoice, required this.onManual});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          _buildBtn(Icons.mic, "Voice Log", AppTheme.expenseColor, onVoice),
          const SizedBox(width: 16),
          _buildBtn(Icons.edit, "Manual", Colors.blueAccent, onManual),
        ],
      ),
    );
  }

  Widget _buildBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// --- SECTION HEADER (Add this to the bottom of the file) ---
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text("See All"),
          ),
        ],
      ),
    );
  }
}
// --- RECENT LOG TILE ---
class RecentTransactionTile extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback onTap;

  const RecentTransactionTile({
    super.key, 
    required this.log, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Use User's preferred currency symbol
    final currencyFormat = NumberFormat.currency(
      symbol: UserService().currencySymbol, 
      decimalDigits: 2
    );
    
    final bool isExpense = log['type'] == 'expense';
    final color = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final prefix = isExpense ? "-" : "+";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Text(log['icon_emoji'] ?? "📄", style: const TextStyle(fontSize: 20)),
        ),
        title: Text(log['item_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          DateFormat('MMM d').format(DateTime.parse(log['created_at'])),
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: Text(
          "$prefix${currencyFormat.format(log['amount'])}",
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}