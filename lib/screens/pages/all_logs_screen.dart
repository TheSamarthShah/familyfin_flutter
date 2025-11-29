import 'package:familyfin/screens/pages/log_detail_screen.dart';
import 'package:familyfin/widgets/dashboard_widgets.dart';
import 'package:flutter/material.dart';
import '../../widgets/responsive_center.dart';
import '../../services/finance_service.dart';

class AllLogsScreen extends StatefulWidget {
  const AllLogsScreen({super.key});

  @override
  State<AllLogsScreen> createState() => _AllLogsScreenState();
}

class _AllLogsScreenState extends State<AllLogsScreen> {
  final FinanceService _financeService = FinanceService();
  
  bool _isLoading = true;
  String? _errorMessage; // New variable to track errors
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch logs
      final logs = await _financeService.getAllLogs(limit: 100);
      
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If the UI crashes, we'll know why
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onLogTap(Map<String, dynamic> log) async {
    final bool? shouldRefresh = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) => LogDetailSheet(log: log),
    );

    if (shouldRefresh == true) {
      _fetchLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("All Transactions", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ResponsiveCenter(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
            ? Center(child: Text("Error: $_errorMessage")) // Show error if any
            : _logs.isEmpty 
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 40),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return RecentTransactionTile(
                        log: _logs[index],
                        onTap: () => _onLogTap(_logs[index]),
                      );
                    },
                  ),
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No transactions found",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _fetchLogs,
            child: const Text("Refresh"),
          )
        ],
      ),
    );
  }
}