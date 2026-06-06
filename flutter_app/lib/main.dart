import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'utils/theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const HarmonyApp(),
    ),
  );
}

class HarmonyApp extends StatelessWidget {
  const HarmonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HarmonyAI',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _checking = true;
  bool _isLoggedIn = false;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.checkAuth();
    setState(() {
      _isLoggedIn = loggedIn;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('H', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFf43f5e))),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Color(0xFFf43f5e)),
            ],
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn) {
      return const HomeScreen();
    }

    if (_showRegister) {
      return RegisterScreen(
        onRegister: () => setState(() => _isLoggedIn = true),
        onLogin: () => setState(() => _showRegister = false),
      );
    }

    return LoginScreen(
      onLogin: () => setState(() => _isLoggedIn = true),
      onRegister: () => setState(() => _showRegister = true),
    );
  }
}
