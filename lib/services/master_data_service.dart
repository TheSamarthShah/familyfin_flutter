import 'package:flutter/material.dart';
import 'finance_service.dart';

class MasterDataProvider extends ChangeNotifier {
  final FinanceService _financeService = FinanceService();

  // --- DATA STORAGE ---
  
  // 1. Static Data (Loaded once on app start)
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _currencies = [];
  
  // 2. Dynamic Data (Reloaded often)
  List<Map<String, dynamic>> _accounts = []; 
  double _netWorth = 0.0;
  List<Map<String, dynamic>> _recentLogs = [];
  List<Map<String, dynamic>> _unverifiedLogs = [];
  Map<String, double> _cashFlow = {'income': 0.0, 'expense': 0.0};
  
  // UI State
  bool _isLoading = true;
  TimeRange _selectedTimeRange = TimeRange.month; 

  // --- GETTERS ---
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get currencies => _currencies;
  List<Map<String, dynamic>> get accounts => _accounts;
  
  double get netWorth => _netWorth;
  List<Map<String, dynamic>> get recentLogs => _recentLogs;
  List<Map<String, dynamic>> get unverifiedLogs => _unverifiedLogs;
  Map<String, double> get cashFlow => _cashFlow;
  
  bool get isLoading => _isLoading;
  TimeRange get selectedTimeRange => _selectedTimeRange;

  // --- ACTIONS ---

  /// ✅ 1. APP START: Fetches EVERYTHING (Static + Dynamic)
  /// Call this from Splash Screen
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _fetchStaticData(), // Categories, Currencies
        _refreshUserData(), // Accounts, Logs, Stats
      ]);
    } catch (e) {
      debugPrint("❌ Init Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ 2. THE NEW METHOD: Fetches ONLY dynamic data
  /// Call this after Adding/Editing/Deleting logs
  Future<void> refreshDashboard() async {
    // Note: We don't set isLoading=true here to prevent full-screen loaders
    await _refreshUserData();
    notifyListeners();
  }

  /// ✅ 3. TIME RANGE CHANGE: Updates only stats
  void updateTimeRange(TimeRange newRange) {
    if (_selectedTimeRange == newRange) return;
    _selectedTimeRange = newRange;
    notifyListeners(); // Immediate UI update for dropdown
    _updateCashFlowStats(); // Background fetch
  }

  // --- INTERNAL HELPERS ---

  Future<void> _fetchStaticData() async {
    final results = await Future.wait([
      _financeService.getCategories(),
      _financeService.getCurrencies(),
    ]);
    _categories = results[0];
    _currencies = results[1];
  }

  Future<void> _refreshUserData() async {
    final results = await Future.wait([
      _financeService.getAccounts(),         // 0. Accounts (Balances change!)
      _financeService.getTotalBalance(),     // 1. Net Worth
      _financeService.getUnverifiedLogs(),   // 2. Drafts
      _financeService.getRecentLogs(),       // 3. Recents
      _financeService.getStats(_selectedTimeRange), // 4. Stats
    ]);

    _accounts = results[0] as List<Map<String, dynamic>>;
    _netWorth = results[1] as double;
    _unverifiedLogs = results[2] as List<Map<String, dynamic>>;
    _recentLogs = results[3] as List<Map<String, dynamic>>;
    _cashFlow = results[4] as Map<String, double>;
  }

  Future<void> _updateCashFlowStats() async {
    final stats = await _financeService.getStats(_selectedTimeRange);
    _cashFlow = stats;
    notifyListeners();
  }

  Future<void> refreshCategories() async {
    // Fetches only categories, leaving other data intact
    final cats = await _financeService.getCategories();
    _categories = cats;
    notifyListeners();
  }
}