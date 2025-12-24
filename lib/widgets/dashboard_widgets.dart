import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/user_service.dart';

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
    final Color headerTextColor = theme.colorScheme.onPrimary.withOpacity(0.8);
    final Color headerIconColor = theme.colorScheme.onPrimary;

    final currencyFormat = NumberFormat.currency(
      symbol: UserService().currencySymbol, 
      decimalDigits: 2
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        // Uses the new teal primary color
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... inside BalanceHero build ...
          Row(
            children: [
              Text(
                "Net Worth", 
                style: theme.textTheme.titleSmall?.copyWith(
                  color: headerTextColor, 
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              
              // Visibility Toggle
              IconButton(
                icon: Icon(
                  isHidden ? Icons.visibility_off : Icons.visibility, 
                  color: headerIconColor,
                  size: 20,
                ),
                onPressed: onTogglePrivacy,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(), // Removes default padding
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 8),

              // ✅ NEW: Settings Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.settings, color: headerIconColor, size: 20),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                     // ✅ UPDATED: Go to main settings menu
                     Navigator.pushNamed(context, '/settings'); 
                  },
                ),
              ),  ],
          ),
          const SizedBox(height: 8),
          Text(
            isHidden ? "••••••" : currencyFormat.format(balance),
            style: theme.textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
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
    final theme = Theme.of(context);
    
    // ✅ NEW: Use the custom action color defined in AppTheme
    final Color actionColor = AppTheme.actionColor; 
    final Color actionBgColor = actionColor.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // Use the action color for the shadow
            color: actionColor.withOpacity(0.2),
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
                    color: actionBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.history_edu, color: actionColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Verify Transactions",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color, 
                        ),
                      ),
                      Text(
                        "$count drafts waiting for review",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant, 
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios, 
                  size: 16, 
                  color: theme.colorScheme.onSurface.withOpacity(0.5)
                ),
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
    // FIX: Compact currency with User Symbol (e.g. $1.2K or ₹1.2L)
    final currencyFormat = NumberFormat.compactCurrency(symbol: UserService().currencySymbol);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              "Income", 
              currencyFormat.format(income), 
              // Uses the new incomeColor
              AppTheme.incomeColor,
              Icons.arrow_downward
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              "Expense", 
              currencyFormat.format(expense), 
              // Uses the new expenseColor
              AppTheme.expenseColor,
              Icons.arrow_upward
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String amount, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label, 
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, 
                  fontWeight: FontWeight.bold
                )
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: theme.colorScheme.onSurface
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
    final currencyFormat = NumberFormat.compactCurrency(symbol: UserService().currencySymbol);
    final balance = (account['balance'] as num).toDouble();
    final type = account['type'] ?? 'cash';
    final theme = Theme.of(context);

    IconData icon = Icons.account_balance_wallet;
    if (type == 'bank') icon = Icons.account_balance;
    if (type == 'credit') icon = Icons.credit_card;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon uses the new teal primary color
          Icon(icon, color: theme.colorScheme.primary),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account['name'] ?? "Unknown",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), 
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormat.format(balance),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), 
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
          // Voice Log uses the expense color (Red/Coral)
          _buildBtn(context, Icons.mic, "Voice Log", AppTheme.expenseColor, onVoice),
          const SizedBox(width: 16),
          // ✅ NEW: Manual Log uses the theme's secondary color 
          _buildBtn(context, Icons.edit, "Manual", Theme.of(context).colorScheme.secondary, onManual),
        ],
      ),
    );
  }

  Widget _buildBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface, 
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(
                  label, 
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), 
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- SECTION HEADER ---
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            // TextButton uses the new teal primary color
            child: Text("See All", style: TextStyle(color: theme.colorScheme.primary)), 
          ),
        ],
      ),
    );
  }
}

// --- RECENT LOG TILE (UPDATED) ---
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
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: UserService().currencySymbol, 
      decimalDigits: 2
    );
    
    // --- UPDATED LOGIC FOR TRANSFER ---
    final String type = log['type'] ?? 'expense';
    final bool isTransfer = type == 'transfer';
    final bool isExpense = type == 'expense';

    Color color;
    String prefix;
    String emoji;

    if (isTransfer) {
      color = Colors.blue;
      prefix = ""; // Transfers are neutral
      emoji = "💸"; 
    } else if (isExpense) {
      color = AppTheme.expenseColor;
      prefix = "-";
      emoji = log['icon_emoji'] ?? "📄";
    } else {
      color = AppTheme.incomeColor;
      prefix = "+";
      emoji = log['icon_emoji'] ?? "💰";
    }
    
    // Use log_date preferably, fallback to created_at
    final dateStr = log['log_date'] ?? log['created_at'];
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    // 1. Use Padding for the outer spacing (margin)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      // 2. Use Material instead of Container for the actual card
      child: Material(
        color: theme.colorScheme.surface,
        // 3. This is the fix: Clip the content (and the ripple) to the border radius
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          title: Text(
            log['item_name'] ?? (isTransfer ? "Transfer" : "Unknown"), 
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
          ), 
          subtitle: Text(
            DateFormat('MMM d').format(date),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), 
          ),
          trailing: Text(
            "$prefix${currencyFormat.format(log['amount'])}",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}