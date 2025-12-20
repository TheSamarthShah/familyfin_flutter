// lib/screens/pages/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foundation_app/l10n/app_localizations.dart';
import 'package:foundation_app/screens/pages/edit_log_screen.dart';
import 'package:foundation_app/screens/pages/log_detail_screen.dart';
import 'package:foundation_app/screens/pages/verify_batch_screen.dart';
import 'package:foundation_app/services/master_data_service.dart';
import 'package:foundation_app/services/finance_service.dart'; // Needed for Enum TimeRange
import 'package:foundation_app/widgets/dashboard_widgets.dart';
import 'package:foundation_app/widgets/responsive_center.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Local UI state (Visual only)
  bool _isBalanceHidden = false; 

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    // ✅ 1. WATCH THE PROVIDER
    // This rebuilds the widget whenever notifyListeners() is called in the service.
    final provider = context.watch<MasterDataProvider>();

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ResponsiveCenter(
        padding: EdgeInsets.zero,
        child: RefreshIndicator(
          // ✅ 2. CONNECT REFRESH TO PROVIDER
          onRefresh: provider.refreshDashboard, 
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              // --- ZONE A: HERO HEADER ---
              SliverToBoxAdapter(
                child: BalanceHero(
                  balance: provider.netWorth, // From Provider
                  isHidden: _isBalanceHidden,
                  onTogglePrivacy: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                ),
              ),

              // --- ZONE B: ACTION CARD ---
              if (provider.unverifiedLogs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: ActionRequiredCard(
                      count: provider.unverifiedLogs.length,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VerifyBatchScreen()),
                        );
                        // Refresh after returning from verification
                        provider.refreshDashboard();
                      },
                    ),
                  ),
                ),

              // --- ZONE C: CASH FLOW HEADER ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Cash Flow",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      // Dropdown Logic
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TimeRange>(
                            value: provider.selectedTimeRange, // From Provider
                            isDense: true,
                            icon: Icon(Icons.arrow_drop_down, size: 20, color: theme.colorScheme.onSurface),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(value: TimeRange.week, child: Text("This Week")),
                              DropdownMenuItem(value: TimeRange.month, child: Text("This Month")),
                              DropdownMenuItem(value: TimeRange.year, child: Text("This Year")),
                            ],
                            // ✅ 3. UPDATE PROVIDER ON CHANGE
                            onChanged: (newRange) { 
                              if (newRange != null) provider.updateTimeRange(newRange);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- ZONE D: MONTHLY PULSE ---
              SliverToBoxAdapter(
                child: MonthlyPulse(
                  income: provider.cashFlow['income'] ?? 0.0, // From Provider
                  expense: provider.cashFlow['expense'] ?? 0.0, // From Provider
                ),
              ),

              // --- ZONE E: ACCOUNTS RAIL ---
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        "My Accounts",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AccountsRail(accounts: provider.accounts), // From Provider
                  ],
                ),
              ),

              // --- ZONE F: QUICK ACTIONS ---
              SliverToBoxAdapter(
                child: QuickActions(
                  onVoice: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Voice feature coming up next!")),
                    );
                  },
                  onManual: () async {
                    final bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditLogScreen(log: null)),
                    );
                    if (result == true) {
                      provider.refreshDashboard(); // Refresh on return
                    }
                  },
                ),
              ),

              // --- ZONE G: RECENT ACTIVITY ---
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: l10n.recentActivityTitle,
                  onSeeAll: () => Navigator.pushNamed(context, '/all_logs'),
                ),
              ),

              if (provider.recentLogs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.savings_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                          "No recent activity",
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => RecentTransactionTile(
                      log: provider.recentLogs[index], // From Provider
                      onTap: () async {
                        final bool? shouldRefresh = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => LogDetailSheet(log: provider.recentLogs[index]),
                        );
                        if (shouldRefresh == true) {
                          provider.refreshDashboard(); // Refresh if edited/deleted
                        }
                      },
                    ),
                    childCount: provider.recentLogs.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}