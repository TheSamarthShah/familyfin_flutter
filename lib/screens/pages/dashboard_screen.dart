import 'package:familyfin/l10n/app_localizations.dart';
import 'package:familyfin/screens/pages/edit_log_screen.dart';
import 'package:familyfin/screens/pages/log_detail_screen.dart';
import 'package:familyfin/screens/pages/verify_batch_screen.dart';
import 'package:familyfin/widgets/dashboard_widgets.dart'; // Ensure this matches your file structure
import 'package:flutter/material.dart';
import '../../widgets/responsive_center.dart';
import '../../services/finance_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FinanceService _financeService = FinanceService();

  bool _isLoading = true;
  bool _isBalanceHidden = true;

  TimeRange _selectedRange = TimeRange.month;

  double _totalBalance = 0.0;
  List<Map<String, dynamic>> _unverifiedLogs = [];
  List<Map<String, dynamic>> _recentLogs = [];
  List<Map<String, dynamic>> _accounts = [];
  Map<String, double> _stats = {'income': 0.0, 'expense': 0.0};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _financeService.getTotalBalance(),
        _financeService.getUnverifiedLogs(),
        _financeService.getRecentLogs(),
        _financeService.getAccounts(),
        _financeService.getStats(_selectedRange),
      ]);

      if (mounted) {
        setState(() {
          _totalBalance = results[0] as double;
          _unverifiedLogs = results[1] as List<Map<String, dynamic>>;
          _recentLogs = results[2] as List<Map<String, dynamic>>;
          _accounts = results[3] as List<Map<String, dynamic>>;
          _stats = results[4] as Map<String, double>;
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onRangeChanged(TimeRange? newRange) {
    if (newRange != null) {
      setState(() => _selectedRange = newRange);
      _fetchData();
    }
  }

  // ✅ NEW: Handle opening the details sheet
  void _onLogTap(Map<String, dynamic> log) async {
    final bool? shouldRefresh = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Required for rounded corners
      builder: (context) => LogDetailSheet(log: log),
    );

    // If returns true, it means a log was deleted/edited -> Refresh UI
    if (shouldRefresh == true) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ResponsiveCenter(
        padding: EdgeInsets.zero,
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              // 1. HERO HEADER
              SliverToBoxAdapter(
                child: BalanceHero(
                  balance: _totalBalance,
                  isHidden: _isBalanceHidden,
                  onTogglePrivacy: () =>
                      setState(() => _isBalanceHidden = !_isBalanceHidden),
                ),
              ),

              // 2. ACTION CARD
              /*if (_unverifiedLogs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: ActionRequiredCard(
                      count: _unverifiedLogs.length,
                      onTap: () async {
                        // Fetch drafts first or pass them if you have them
                        // For now, let's just pick the first one as an example,
                        // or navigate to a "Drafts List" screen.

                        // Assuming you want to verify the first draft in the list for now:
                        if (_unverifiedLogs.isNotEmpty) {
                          final bool? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditLogScreen(log: _unverifiedLogs.first),
                            ),
                          );
                          if (result == true) _fetchData(); // Refresh dashboard
                        }
                      },
                    ),
                  ),
                ),*/
              // 2. ACTION CARD
              if (_unverifiedLogs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: ActionRequiredCard(
                      count: _unverifiedLogs.length,
                      onTap: () async {
                        // ✅ Navigate to the Batch Screen
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VerifyBatchScreen(),
                          ),
                        );
                        // Refresh Dashboard when returning (in case logs were cleared)
                        _fetchData();
                      },
                    ),
                  ),
                ),
              // 3. ANALYSIS HEADER
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
                          color: Colors.grey[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TimeRange>(
                            value: _selectedRange,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: TimeRange.week,
                                child: Text("This Week"),
                              ),
                              DropdownMenuItem(
                                value: TimeRange.month,
                                child: Text("This Month"),
                              ),
                              DropdownMenuItem(
                                value: TimeRange.year,
                                child: Text("This Year"),
                              ),
                            ],
                            onChanged: _onRangeChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. MONTHLY PULSE
              SliverToBoxAdapter(
                child: MonthlyPulse(
                  income: _stats['income']!,
                  expense: _stats['expense']!,
                ),
              ),

              // 5. ACCOUNTS RAIL
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        "My Accounts",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AccountsRail(accounts: _accounts),
                  ],
                ),
              ),

              // 6. QUICK ACTIONS
              SliverToBoxAdapter(
                child: QuickActions(
                  onVoice: () {
                    // Placeholder for Voice Feature
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Voice feature coming up next!"),
                      ),
                    );
                  },
                  onManual: () async {
                    final bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditLogScreen(log: null),
                      ), // Null = New
                    );
                    if (result == true) _fetchData(); // Refresh dashboard
                  },
                ),
              ),

              // 7. RECENT ACTIVITY HEADER
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: l10n.recentActivityTitle, // e.g. "Recent Activity"
                  onSeeAll: () {
                    // ✅ NAVIGATE TO ALL LOGS
                    Navigator.pushNamed(context, '/all_logs');
                  },
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recentLogs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No recent activity",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => RecentTransactionTile(
                      log: _recentLogs[index],
                      onTap: () =>
                          _onLogTap(_recentLogs[index]), // ✅ Pass Callback
                    ),
                    childCount: _recentLogs.length,
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
