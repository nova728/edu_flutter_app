class AuthUser {
  const AuthUser({
    required this.userId,
    required this.username,
    this.province,
    this.schoolName,
  });

  final String userId;
  final String username;
  final String? province;
  final String? schoolName;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final userId = (json['userId'] ?? json['USER_ID'])?.toString() ?? '';
    final username = (json['username'] ?? json['USERNAME'])?.toString() ?? '';
    final province = (json['province'] ?? json['PROVINCE'])?.toString();
    final schoolName = (json['schoolName'] ?? json['SCHOOL_NAME'])?.toString();
    return AuthUser(
      userId: userId,
      username: username,
      province: province,
      schoolName: schoolName,
    );
  }
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class AuthCredentials {
  const AuthCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

class RegistrationPayload {
  const RegistrationPayload({
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.province,
    required this.schoolName,
  });

  final String username;
  final String password;
  final String confirmPassword;
  final String province;
  final String schoolName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'password': password,
      'confirmPassword': confirmPassword,
      'province': province,
      'schoolName': schoolName,
    };
  }
}
