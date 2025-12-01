import 'package:foundation_app/core/app_theme.dart';
import 'package:foundation_app/screens/pages/edit_log_screen.dart';
import 'package:foundation_app/services/finance_service.dart';
import 'package:foundation_app/services/user_service.dart';
import 'package:foundation_app/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    
    // 1. Optimistic Update (Remove from UI immediately)
    setState(() => _drafts.removeAt(index));

    // 2. Perform API Call
    final success = await _financeService.confirmLog(item['id']);

    if (!success && mounted) {
      // Revert if failed
      setState(() => _drafts.insert(index, item));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save. Try again.")));
    }
  }

  Future<void> _onSwipeDiscard(int index) async {
    final item = _drafts[index];
    
    setState(() => _drafts.removeAt(index));

    final success = await _financeService.deleteLog(item['id']);

    if (!success && mounted) {
      setState(() => _drafts.insert(index, item));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete. Try again.")));
    }
  }

  Future<void> _onVerifyAll() async {
    if (_drafts.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Approve All?"),
        content: Text("This will confirm ${_drafts.length} transactions immediately."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Approve All"),
          ),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      // Parallel execution for speed
      await Future.wait(_drafts.map((log) => _financeService.confirmLog(log['id'])));
      
      if (mounted) {
        setState(() {
          _drafts.clear();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All Verified! 🎉")));
        Navigator.pop(context, true); // Go back to dashboard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Review Transactions"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_drafts.isNotEmpty)
            TextButton.icon(
              onPressed: _onVerifyAll,
              icon: const Icon(Icons.done_all, color: Colors.blue),
              label: const Text("Approve All", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: ResponsiveCenter(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty 
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _drafts.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final log = _drafts[index];
                  // Use ID as Key so Flutter knows which widget is which during swipes
                  return Dismissible(
                    key: Key(log['id']),
                    direction: DismissDirection.horizontal,
                    
                    // 🟢 SWIPE RIGHT (SAVE)
                    background: _buildSwipeBackground(
                      color: Colors.green, 
                      icon: Icons.check_circle_outline, 
                      alignment: Alignment.centerLeft,
                      label: "Confirm"
                    ),
                    
                    // 🔴 SWIPE LEFT (DISCARD)
                    secondaryBackground: _buildSwipeBackground(
                      color: Colors.red, 
                      icon: Icons.delete_outline, 
                      alignment: Alignment.centerRight,
                      label: "Discard"
                    ),
                    
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        _onSwipeSave(index);
                      } else {
                        _onSwipeDiscard(index);
                      }
                    },
                    
                    child: _buildDraftCard(log),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSwipeBackground({required Color color, required IconData icon, required Alignment alignment, required String label}) {
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
          ? [Icon(icon, color: Colors.white, size: 32), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]
          : [Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(width: 8), Icon(icon, color: Colors.white, size: 32)],
      ),
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> log) {
    final currencySymbol = UserService().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
    final amount = (log['amount'] as num).toDouble();
    final isExpense = log['type'] == 'expense';
    
    return InkWell(
      onTap: () async {
        // Allow editing before confirming
        final result = await Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => EditLogScreen(log: log))
        );
        if (result == true) _fetchDrafts(); // Refresh if they edited/saved it inside the screen
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice Text Bubble
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  bottomLeft: Radius.circular(0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "\"${log['original_text'] ?? '...'}\"",
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
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
                    color: (isExpense ? AppTheme.expenseColor : AppTheme.incomeColor).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(log['icon_emoji'] ?? '🤖', style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log['item_name'] ?? "Unknown Item", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      Text(
                        "${log['category_name'] ?? 'Uncategorized'} • ${log['account_name'] ?? 'Cash'}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 18,
                    color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text("Swipe to verify", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green[200]),
          const SizedBox(height: 16),
          const Text("All Caught Up!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("No pending drafts to review.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Go to Dashboard"),
          )
        ],
      ),
    );
  }
}