import 'package:flutter/material.dart';

import 'screens/auth/auth_screen.dart';
import 'screens/home/home_shell.dart';
import 'theme/app_theme.dart';

class ZygcApp extends StatefulWidget {
  const ZygcApp({super.key});

  @override
  State<ZygcApp> createState() => _ZygcAppState();
}

class _ZygcAppState extends State<ZygcApp> {
  bool _isAuthenticated = false;

  void _onAuthenticationChanged(bool value) {
    setState(() => _isAuthenticated = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _isAuthenticated
          ? HomeShell(onSignOut: () => _onAuthenticationChanged(false))
          : AuthScreen(onAuthenticated: () => _onAuthenticationChanged(true)),
    );
  }
}
