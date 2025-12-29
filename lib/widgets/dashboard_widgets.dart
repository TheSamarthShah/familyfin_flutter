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
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 8),

              // Settings Button
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
                     Navigator.pushNamed(context, '/settings'); 
                  },
                ),
              ),
            ],
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
    
    final Color actionColor = AppTheme.actionColor; 
    final Color actionBgColor = actionColor.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
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
  final bool isHidden;

  const AccountsRail({
    super.key, 
    required this.accounts,
    this.isHidden = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Empty State: Simple text instead of a big card
    if (accounts.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              "No accounts added", 
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 150, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        // ✅ Removed "+ 1" logic. It strictly shows the accounts.
        itemCount: accounts.length, 
        itemBuilder: (context, index) {
          final acc = accounts[index];
          return _buildAccountCard(context, acc);
        },
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Map<String, dynamic> account) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.compactCurrency(symbol: UserService().currencySymbol);
    
    // Formatter for the dialog (Exact figure)
    final fullCurrencyFormat = NumberFormat.currency(
      symbol: UserService().currencySymbol, 
      decimalDigits: 2
    );

    final balance = (account['balance'] as num).toDouble();
    final type = account['type'] ?? 'cash';
    final bool isCredit = account['is_credit'] ?? false;

    // --- SMART DISPLAY LOGIC FOR RAIL ---
    String amountToDisplay = currencyFormat.format(balance);
    Color amountColor = theme.textTheme.titleMedium!.color!;
    String iconStr;

    switch (type) {
      case 'cash': iconStr = '💵'; break;
      case 'bank': iconStr = '🏦'; break;
      case 'credit': iconStr = '💳'; break;
      case 'wallet': iconStr = '👛'; break;
      case 'investment': iconStr = '📈'; break;
      default: iconStr = '📁';
    }

    if (isCredit && balance < 0) {
       // Show debt as positive number in RED
       amountToDisplay = currencyFormat.format(balance.abs());
       amountColor = theme.colorScheme.error;
    }

    return GestureDetector(
      // Handle Tap: Show Exact Figure Dialog
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            String dialogAmount = fullCurrencyFormat.format(balance);
            Color dialogColor = balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor;
            
            if (isCredit && balance < 0) {
              dialogAmount = fullCurrencyFormat.format(balance.abs());
              dialogColor = theme.colorScheme.error;
            }

            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Text(iconStr, style: const TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    account['name'] ?? "Unknown",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCredit && balance < 0 ? "Outstanding Debt" : "Current Balance",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dialogAmount,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dialogColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 140),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color, 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Text(iconStr, style: const TextStyle(fontSize: 20)),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account['name'] ?? "Unknown",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ), 
                ),
                const SizedBox(height: 4),
                
                if (isHidden)
                  Text(
                    "••••••",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  )
                else
                  Text(
                    amountToDisplay,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ), 
                  ),
              ],
            ),
          ],
        ),
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
          _buildBtn(context, Icons.mic, "Voice Log", AppTheme.expenseColor, onVoice),
          const SizedBox(width: 16),
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
            child: Text("See All", style: TextStyle(color: theme.colorScheme.primary)), 
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
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: UserService().currencySymbol, 
      decimalDigits: 2
    );
    
    final String type = log['type'] ?? 'expense';
    final bool isTransfer = type == 'transfer';
    final bool isExpense = type == 'expense';

    Color color;
    String prefix;
    String emoji;

    if (isTransfer) {
      color = Colors.blue;
      prefix = ""; 
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
    
    final dateStr = log['log_date'] ?? log['created_at'];
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: theme.colorScheme.surface,
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