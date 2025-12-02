class UserService {
  // 1. Singleton Setup
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // 2. Properties (Default to safe values)
  String _id = '';
  String _email = '';
  String _fullName = 'User';
  String _currencyCode = 'INR';
  String _currencySymbol = '₹';
  String _languageCode = 'en';

  // 3. Getters
  String get id => _id;
  String get email => _email;
  String get fullName => _fullName;
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  String get languageCode => _languageCode;

  // 4. Setter Method
  void setUserDetails({
    required String id,
    required String email,
    required String fullName,
    required String currencyCode,
    required String currencySymbol,
    required String languageCode,
  }) {
    _id = id;
    _email = email;
    _fullName = fullName;
    _currencyCode = currencyCode;
    _currencySymbol = currencySymbol;
    _languageCode = languageCode;
  }

  // 5. Clear Method (Logout)
  void clear() {
    _id = '';
    _email = '';
    _fullName = 'User';
    _currencyCode = 'INR';
    _currencySymbol = '₹';
    _languageCode = 'en';
  }
}