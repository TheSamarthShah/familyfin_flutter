// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Fin';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginBtn => 'Login';

  @override
  String get registerLink => 'Create New Account';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get subtitle => 'Start tracking your logs instantly.';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get getStartedBtn => 'Get Started';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidEmail => 'Please enter a valid email';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get loginSubtitle => 'Login to manage your expenses';

  @override
  String get dashboardTitle => 'Overview';

  @override
  String get totalBalanceLabel => 'Total Balance';

  @override
  String get safeToSpendLabel => 'Safe to Spend';

  @override
  String get unverifiedCardTitle => 'Action Required';

  @override
  String unverifiedCardSubtitle(Object count) {
    return 'You have $count unverified transactions.';
  }

  @override
  String get reviewBtn => 'Review Now';

  @override
  String get recentActivityTitle => 'Recent Activity';

  @override
  String get voiceLogBtn => 'Voice Log';

  @override
  String get manualLogBtn => 'Manual Entry';
}
