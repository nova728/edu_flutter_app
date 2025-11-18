import 'package:flutter/material.dart';

import 'models/auth_models.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_shell.dart';
import 'services/api_exception.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'state/auth_scope.dart';

class ZygcApp extends StatefulWidget {
  const ZygcApp({super.key});

  @override
  State<ZygcApp> createState() => _ZygcAppState();
}

class _ZygcAppState extends State<ZygcApp> {
  final AuthService _authService = AuthService();

  AuthSession? _session;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isAuthenticated => _session != null;

  Future<void> _handleLogin(AuthCredentials credentials) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final session = await _authService.login(credentials);
      setState(() {
        _session = session;
      });
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = '登录失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegister(RegistrationPayload payload) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.register(payload);
      // 注册成功后尝试自动登录，使用生成的ID而不是username
      await _handleLogin(AuthCredentials(username: payload.username, password: payload.password));
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = '注册失败，请稍后重试');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _signOut() {
    setState(() {
      _session = null;
      _errorMessage = null;
    });
  }

  void _updateUser(AuthUser user) {
    if (_session == null) return;
    setState(() {
      _session = AuthSession(token: _session!.token, user: user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => _isAuthenticated
          ? AuthScope(
              session: _session!,
              onSignOut: _signOut,
              onUpdateUser: _updateUser,
              child: child!,
            )
          : child!,
      home: _isAuthenticated
          ? HomeShell(
              session: _session!,
              onSignOut: _signOut,
              onUpdateUser: _updateUser,
            )
          : AuthScreen(
              onLogin: _handleLogin,
              onRegister: _handleRegister,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
            ),
    );
  }
}
