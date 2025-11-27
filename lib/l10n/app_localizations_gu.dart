// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appTitle => 'ફેમિલી ફિન';

  @override
  String get loginTitle => 'ફરી સ્વાગત છે';

  @override
  String get loginBtn => 'લોગ ઇન';

  @override
  String get registerLink => 'નવું ખાતું બનાવો';

  @override
  String get createAccountTitle => 'ખાતું બનાવો';

  @override
  String get subtitle => 'તમારા લોગ્સને તરત જ ટ્રેક કરવાનું શરૂ કરો.';

  @override
  String get emailLabel => 'ઇમેઇલ સરનામું';

  @override
  String get passwordLabel => 'પાસવર્ડ';

  @override
  String get fullNameLabel => 'પૂરું નામ';

  @override
  String get currencyLabel => 'ચલણ';

  @override
  String get getStartedBtn => 'શરૂ કરો';

  @override
  String get requiredField => 'આવશ્યક છે';

  @override
  String get invalidEmail => 'કૃપા કરીને માન્ય ઇમેઇલ દાખલ કરો';

  @override
  String get passwordTooShort => 'પાસવર્ડ ઓછામાં ઓછા 6 અક્ષરોનો હોવો જોઈએ';

  @override
  String get loginSubtitle => 'તમારા ખર્ચનું સંચાલન કરવા માટે લોગ ઇન કરો';

  @override
  String get dashboardTitle => 'મારું ડેશબોર્ડ';

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
