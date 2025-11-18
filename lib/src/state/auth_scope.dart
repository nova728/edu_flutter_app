import 'package:flutter/widgets.dart';

import '../models/auth_models.dart';

class AuthScope extends InheritedWidget {
  const AuthScope({
    super.key,
    required this.session,
    required this.onSignOut,
    required this.onUpdateUser,
    required super.child,
  });

  final AuthSession session;
  final VoidCallback onSignOut;
  final ValueChanged<AuthUser> onUpdateUser;

  static AuthScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope.of() called with a context that does not contain AuthScope.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) =>
      oldWidget.session.token != session.token || oldWidget.session.user != session.user;
}
