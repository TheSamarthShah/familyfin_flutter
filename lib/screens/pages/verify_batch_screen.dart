import 'package:foundation_app/core/app_theme.dart';
import 'package:foundation_app/screens/pages/edit_log_screen.dart';
import 'package:foundation_app/services/finance_service.dart';
import 'package:foundation_app/services/master_data_service.dart';
import 'package:foundation_app/services/user_service.dart';
import 'package:foundation_app/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VerifyBatchScreen extends StatefulWidget {
  const VerifyBatchScreen({super.key});

  @override
  State<VerifyBatchScreen> createState() => _VerifyBatchScreenState();
}

class _VerifyBatchScreenState extends State<VerifyBatchScreen> {
  final FinanceService _financeService = FinanceService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _drafts = [];

  @override
  void initState() {
    super.initState();
    _fetchDrafts();
  }

  Future<void> _fetchDrafts() async {
    setState(() => _isLoading = true);
    final data = await _financeService.getUnverifiedLogs();
    if (mounted) {
      setState(() {
        _drafts = data;
        _isLoading = false;
      });
    }
  }

  // --- ACTIONS ---

  Future<void> _onSwipeSave(int index) async {
    final item = _drafts[index];
    setState(() => _drafts.removeAt(index));

    // ✅ CHANGED: No context arg
    final success = await _financeService.confirmLog(item['id']);

    if (!success && mounted) {
      setState(() => _drafts.insert(index, item));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save. Try again.")));
    } else if (success && mounted) {
       // ✅ ADDED: Update global state silently
       context.read<MasterDataProvider>().refreshDashboard();
    }
  }

  Future<void> _onSwipeDiscard(int index) async {
    final item = _drafts[index];
    setState(() => _drafts.removeAt(index)); 

    // ✅ CHANGED: No context arg
    final success = await _financeService.deleteLog(item['id']);

    if (!success && mounted) {
      setState(() => _drafts.insert(index, item)); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete. Try again.")));
    } else if (success && mounted) {
       // ✅ ADDED: Update global state silently
       context.read<MasterDataProvider>().refreshDashboard();
    }
  }

  Future<void> _onVerifyAll() async {
    if (_drafts.isEmpty) return;

    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Approve All?"),
        content: Text(
          "This will confirm ${_drafts.length} transactions immediately.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text("Approve All"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      // ✅ CHANGED: No context arg
      await Future.wait(
        _drafts.map((log) => _financeService.confirmLog(log['id'])),
      ); 

      if (mounted) {
        setState(() {
          _drafts.clear();
          _isLoading = false;
        });
        // ✅ ADDED: Update global state
        context.read<MasterDataProvider>().refreshDashboard();
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All Verified! 🎉")));
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Adaptive Background
      appBar: AppBar(
        title: const Text("Review Transactions"),
        backgroundColor: theme.scaffoldBackgroundColor, // ✅ Blends with body
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_drafts.isNotEmpty)
            TextButton.icon(
              onPressed: _onVerifyAll,
              icon: Icon(Icons.done_all, color: theme.colorScheme.primary),
              label: Text(
                "Approve All",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: ResponsiveCenter(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _drafts.isEmpty
            ? _buildEmptyState(theme)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _drafts.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final log = _drafts[index];
                  return Dismissible(
                    key: Key(log['id']),
                    direction: DismissDirection.horizontal,

                    // 🟢 SWIPE RIGHT (SAVE)
                    background: _buildSwipeBackground(
                      color: AppTheme.incomeColor, // Green
                      icon: Icons.check_circle_outline,
                      alignment: Alignment.centerLeft,
                      label: "Confirm",
                    ),

                    // 🔴 SWIPE LEFT (DISCARD)
                    secondaryBackground: _buildSwipeBackground(
                      color: theme.colorScheme.error, // Red
                      icon: Icons.delete_outline,
                      alignment: Alignment.centerRight,
                      label: "Discard",
                    ),

                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        _onSwipeSave(index);
                      } else {
                        _onSwipeDiscard(index);
                      }
                    },

                    child: _buildDraftCard(log, theme),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft
            ? [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 32),
              ],
      ),
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> log, ThemeData theme) {
    final currencySymbol = UserService().currencySymbol;
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );
    final amount = (log['amount'] as num).toDouble();
    final isExpense = log['type'] == 'expense';

    // 1. Container handles the Shadow (Shadows can't be clipped, so they stay outside)
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // 2. Material handles Color, Border, Shape, and CLIPPING
      child: Material(
        color: theme.colorScheme.surface,
        clipBehavior:
            Clip.hardEdge, // <--- THE FIX: Clips the InkWell to the corners
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        // 3. InkWell is now INSIDE the Material
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditLogScreen(log: log)),
            );
            if (result == true) _fetchDrafts();
          },
          // 4. Padding is applied to the content inside the InkWell
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Voice Text Bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                      bottomLeft: Radius.circular(0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mic,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "\"${log['original_text'] ?? '...'}\"",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Extracted Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            (isExpense
                                    ? AppTheme.expenseColor
                                    : AppTheme.incomeColor)
                                .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        log['icon_emoji'] ?? '🤖',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['item_name'] ?? "Unknown Item",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "${log['category_name'] ?? 'Uncategorized'} • ${log['account_name'] ?? 'Cash'}",
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isExpense
                            ? AppTheme.expenseColor
                            : AppTheme.incomeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Swipe to verify",
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "All Caught Up!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No pending drafts to review.",
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Go to Dashboard"),
          ),
        ],
      ),
    );
  }
}
