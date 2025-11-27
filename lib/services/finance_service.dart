import 'package:supabase_flutter/supabase_flutter.dart';

enum TimeRange { week, month, year }

class FinanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. Get Total Balance
  Future<double> getTotalBalance() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase.from('accounts').select('balance').eq('user_id', userId);
      
      double total = 0.0;
      for (var account in response) {
        total += (account['balance'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print("Balance Error: $e");
      return 0.0;
    }
  }

  /// 2. Get Accounts
  Future<List<Map<String, dynamic>>> getAccounts() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase.from('accounts').select().eq('user_id', userId).order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// 3. Get Stats (Income vs Expense)
  Future<Map<String, double>> getStats(TimeRange range) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now();
      
      DateTime startDate;
      DateTime endDate = now;

      switch (range) {
        case TimeRange.week:
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case TimeRange.month:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case TimeRange.year:
          startDate = DateTime(now.year, 1, 1);
          break;
      }

      final response = await _supabase
          .from('logs')
          .select('amount, type')
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .gte('log_date', startDate.toIso8601String())
          .lte('log_date', endDate.toIso8601String());

      double income = 0.0;
      double expense = 0.0;

      for (var log in response) {
        final amount = (log['amount'] as num).toDouble();
        if (log['type'] == 'income') income += amount;
        if (log['type'] == 'expense') expense += amount;
      }

      return {'income': income, 'expense': expense};
    } catch (e) {
      return {'income': 0.0, 'expense': 0.0};
    }
  }

  /// 4. Get Unverified Logs (Drafts)
  Future<List<Map<String, dynamic>>> getUnverifiedLogs() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      // ✅ FIX: Join categories to get the emoji, but don't crash if null
      final response = await _supabase
          .from('logs')
          .select('id, item_name, amount, type, created_at, original_text')
          .eq('user_id', userId)
          .eq('status', 'draft')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Drafts Error: $e");
      return [];
    }
  }

  /// 5. Get Recent History (Confirmed)
  Future<List<Map<String, dynamic>>> getRecentLogs() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // ✅ FIX: The Bug was here. We must fetch 'categories(icon_emoji)' 
      // instead of 'icon_emoji' directly from logs.
      final response = await _supabase
          .from('logs')
          .select('id, item_name, amount, type, created_at, categories(icon_emoji)')
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .order('log_date', ascending: false)
          .limit(10);

      // ✅ FIX: Flatten the response so UI doesn't break
      // UI expects log['icon_emoji'], but DB returns log['categories']['icon_emoji']
      return List<Map<String, dynamic>>.from(response).map((log) {
        if (log['categories'] != null) {
          log['icon_emoji'] = log['categories']['icon_emoji'];
        }
        return log;
      }).toList();
      
    } catch (e) {
      print("Recent Logs Error: $e");
      return [];
    }
  }
}