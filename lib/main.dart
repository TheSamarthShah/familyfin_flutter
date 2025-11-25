import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      title: 'Voice Logger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Start with the Splash Screen to decide where to go
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // Placeholder Dashboard for now
        '/dashboard': (context) => Scaffold(
          appBar: AppBar(title: const Text("Dashboard")),
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Logout (Testing)"),
            ),
          ),
        ),
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
    } else {
      // 🕵️ EXTRA SAFETY CHECK
      // Check if user has a profile. If DB failed during registration, 
      // they might exist in Auth but not DB.
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null && mounted) {
        // Limbo state - for MVP, we just sign them out and ask to register again
        await supabase.auth.signOut();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}