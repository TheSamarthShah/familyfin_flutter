import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foundation_app/l10n/app_localizations.dart';
import 'package:foundation_app/screens/management/account_list_screen.dart';
import 'package:foundation_app/screens/management/category_list_screen.dart';
import 'package:foundation_app/screens/pages/all_logs_screen.dart';
import 'package:foundation_app/screens/pages/dashboard_screen.dart';
import 'package:foundation_app/screens/pages/settings_screen.dart';
import 'package:foundation_app/screens/pages/voice_log_sheet.dart';
import 'package:foundation_app/services/master_data_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:home_widget/home_widget.dart';

import 'core/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'services/auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zpzfmbtfaqnpewztblol.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwemZtYnRmYXFucGV3enRibG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5ODQyNDEsImV4cCI6MjA3NzU2MDI0MX0.VPoiOJchcPBXHp2uVcawHI1toPqwUS0RcaoMOTAX-EA',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MasterDataProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Only listen for clicks when app is ALREADY running (Warm Start)
    // Cold start is handled by SplashScreen now to avoid conflicts
    HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
  }

  void _handleWidgetLaunch(Uri? uri) {
    if (uri?.host == 'voice_log') {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const VoiceLogSheet(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(
        type: FoundationAppType.finance,
        brightness: Brightness.light,
      ),
      darkTheme: AppTheme.getTheme(
        type: FoundationAppType.finance,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('gu'),
      ],
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // Point to our new Launcher Wrapper
        '/dashboard': (context) => const DashboardLauncher(), 
        '/all_logs': (context) => const AllLogsScreen(),
        '/categories': (context) => const CategoryListScreen(),
        '/accounts': (context) => const AccountListScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // 1. Wait for delay & check widget launch in parallel
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 1)),
      HomeWidget.initiallyLaunchedFromHomeWidget(),
    ]);

    final widgetUri = results[1] as Uri?;

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    await _authService.initializeUserSession();
    if (mounted) {
      await Provider.of<MasterDataProvider>(context, listen: false).initialize();
    }

    if (mounted) {
      // 2. Pass "true" if launched by widget
      final shouldOpenVoice = (widgetUri?.host == 'voice_log');
      
      Navigator.pushReplacementNamed(
        context, 
        '/dashboard', 
        arguments: shouldOpenVoice // <--- Passing the signal here
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

// -----------------------------------------------------------------------------
// NEW: Wrapper Widget to Handle Auto-Opening the Sheet
// -----------------------------------------------------------------------------
class DashboardLauncher extends StatefulWidget {
  const DashboardLauncher({super.key});

  @override
  State<DashboardLauncher> createState() => _DashboardLauncherState();
}

class _DashboardLauncherState extends State<DashboardLauncher> {
  @override
  void initState() {
    super.initState();
    // Wait for the UI to build, then check if we need to open the sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      // If SplashScreen passed "true", open the sheet immediately
      if (args == true) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const VoiceLogSheet(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Just render the normal Dashboard
    return const DashboardScreen();
  }
}