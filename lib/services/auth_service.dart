import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 🌍 UTILITIES
  // ---------------------------------------------------------------------------
  
  /// Fetches the list of available currencies from the database.
  Future<List<Map<String, dynamic>>> getCurrencies() async {
    try {
      final data = await _supabase
          .from('currencies')
          .select('code, name, symbol')
          .order('name', ascending: true);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Error fetching currencies: $e");
      return [
        {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
        {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
      ];
    }
  }

  // ---------------------------------------------------------------------------
  // 📝 REGISTRATION
  // ---------------------------------------------------------------------------
  Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String currencyCode,
    required String languageCode,
  }) async {
    try {
      // 1. Create Auth User
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user == null) {
        throw Exception("Sign up failed: No user returned.");
      }

      // 2. Create DB Entry via RPC
      // Call the simplified 'register_new_user' function
      await _supabase.rpc('register_new_user', params: {
        'full_name': fullName,
        'currency_code': currencyCode,
        'language_code': languageCode,
      });
      
    } catch (e) {
      // 🧹 CLEANUP: Force sign out if DB setup fails
      await _supabase.auth.signOut();
      print("Registration Error: $e");
      rethrow; 
    }
  }

  // ---------------------------------------------------------------------------
  // 🔐 AUTH ACTIONS
  // ---------------------------------------------------------------------------
  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}