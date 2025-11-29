import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum TimeRange { week, month, year }

class FinanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. Get Total Balance (Keeps using Table)
  Future<double> getTotalBalance() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('accounts')
          .select('balance')
          .eq('user_id', userId);

      double total = 0.0;
      for (var account in response) {
        total += (account['balance'] as num).toDouble();
      }
      return total;
    } catch (e) {
      debugPrint("Balance Error: $e");
      return 0.0;
    }
  }

  /// 2. Get Accounts (Keeps using Table)
  Future<List<Map<String, dynamic>>> getAccounts() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('accounts')
          .select()
          .eq('user_id', userId)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// 3. Get Stats (✅ Uses 'view_confirmed_logs')
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

      // Changed: Use View. No need to filter status='confirmed' anymore.
      final response = await _supabase
          .from('view_confirmed_logs')
          .select('amount, type')
          .eq('user_id', userId)
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

  /// 4. Get Unverified Logs (✅ Uses 'view_draft_logs')
  Future<List<Map<String, dynamic>>> getUnverifiedLogs() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Changed: Much simpler query using the View
      final response = await _supabase
          .from('view_draft_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Drafts Error: $e");
      return [];
    }
  }

  /// 5. Get Recent History (✅ Uses 'view_confirmed_logs')
  Future<List<Map<String, dynamic>>> getRecentLogs() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Changed: Use View. The view already has 'icon_emoji' flattened.
      final response = await _supabase
          .from('view_confirmed_logs')
          .select()
          .eq('user_id', userId)
          .order('log_date', ascending: false)
          .limit(10);

      // No need to map/flatten anymore!
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Recent Logs Error: $e");
      return [];
    }
  }

  /// 6. Get All Logs (✅ Uses 'view_confirmed_logs')
  Future<List<Map<String, dynamic>>> getAllLogs({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('view_confirmed_logs')
          .select()
          .order('log_date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching all logs: $e');
      return [];
    }
  }

  /// 7. Delete Log (Keeps using Table - Writes go to tables)
  Future<bool> deleteLog(String logId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase
          .from('logs')
          .delete()
          .eq('id', logId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error deleting log: $e');
      return false;
    }
  }

  /// 8. Get Categories (Keeps using Table)
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('categories')
          .select()
          .or('user_id.eq.$userId,user_id.is.null')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  /// 9. Create or Update Log
  Future<bool> upsertLog({
    String? logId,
    required double amount,
    required String type,
    required String categoryId,
    required String accountId,
    required DateTime date,
    String? itemName,
    String? note,
    // NEW OPTIONAL FIELDS
    double? foreignAmount,
    String? foreignCurrency,
    String? locationName,
    List<String>? tags,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = {
        'user_id': userId,
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'account_id': accountId,
        'log_date': date.toIso8601String(),
        'item_name': itemName,
        'original_text': note,
        'status': 'confirmed',
        // NEW COLUMNS
        'foreign_amount': foreignAmount,
        'foreign_currency_code': foreignCurrency,
        'location_name': locationName,
        'tags': tags,
      };

      if (logId != null) {
        await _supabase.from('logs').update(data).eq('id', logId);
      } else {
        await _supabase.from('logs').insert(data);
      }
      return true;
    } catch (e) {
      debugPrint("Error upserting log: $e");
      return false;
    }
  }

  /// 10. Confirm Log (Quick Verify)
  Future<bool> confirmLog(String logId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      // Just flip the status. The DB triggers handle the balance math!
      await _supabase
          .from('logs')
          .update({'status': 'confirmed'})
          .eq('id', logId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint("Error confirming log: $e");
      return false;
    }
  }

  /// 11. Get Currencies
  Future<List<Map<String, dynamic>>> getCurrencies() async {
    try {
      final response = await _supabase
          .from('currencies')
          .select('code, symbol')
          .order('code');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [
        {'code': 'USD', 'symbol': '\$'},
      ]; // Fallback
    }
  }
}
