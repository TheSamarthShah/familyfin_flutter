import 'package:familyfin/l10n/app_localizations.dart';
import 'package:familyfin/screens/pages/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zpzfmbtfaqnpewztblol.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwemZtYnRmYXFucGV3enRibG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5ODQyNDEsImV4cCI6MjA3NzU2MDI0MX0.VPoiOJchcPBXHp2uVcawHI1toPqwUS0RcaoMOTAX-EA',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, 

      locale: const Locale('en'), 

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('gu'), // Gujarati
      ],

      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(), 
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
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Artificial delay to show splash logo
    await Future.delayed(const Duration(seconds: 1));

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // 🛑 FIX: Wrap DB call in try-catch to prevent "Infinite Loading"
    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        // Real issue: Auth exists but Data is missing. Logout.
        await supabase.auth.signOut();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        // All good
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      // ⚠️ NETWORK ERROR / OFFLINE
      // If the DB check fails (e.g. no internet), we should still let the user in
      // if they are authenticated locally. The Dashboard will handle offline/error states.
      debugPrint("Splash DB Error: $e");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary, // Brand color splash
      body: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}