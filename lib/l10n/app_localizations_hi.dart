// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'फैमिली फिन';

  @override
  String get loginTitle => 'पुनः स्वागत है';

  @override
  String get loginBtn => 'लॉग इन करें';

  @override
  String get registerLink => 'नया खाता बनाएं';

  @override
  String get createAccountTitle => 'खाता बनाएं';

  @override
  String get subtitle => 'तुरंत अपने लॉग्स ट्रैक करना शुरू करें।';

  @override
  String get emailLabel => 'ईमेल पता';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get fullNameLabel => 'पूरा नाम';

  @override
  String get currencyLabel => 'मुद्रा';

  @override
  String get getStartedBtn => 'शुरू करें';

  @override
  String get requiredField => 'अनिवार्य है';

  @override
  String get invalidEmail => 'मान्य ईमेल दर्ज करें';

  @override
  String get passwordTooShort => 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get loginSubtitle => 'अपने खर्चों का प्रबंधन करने के लिए लॉग इन करें';

  @override
  String get dashboardTitle => 'मेरा डैशबोर्ड';

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
