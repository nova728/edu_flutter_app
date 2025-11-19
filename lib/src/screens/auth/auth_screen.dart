import 'package:flutter/material.dart';

import '../../models/auth_models.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.onLogin,
    required this.onRegister,
    required this.isLoading,
    this.errorMessage,
    super.key,
  });

  final Future<void> Function(AuthCredentials) onLogin;
  final Future<void> Function(RegistrationPayload) onRegister;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();
  bool _isLoginSelected = true;

  late final TextEditingController _loginIdController = TextEditingController();
  late final TextEditingController _loginPasswordController = TextEditingController();

  late final TextEditingController _registerIdController = TextEditingController();
  late final TextEditingController _registerPasswordController = TextEditingController();
  late final TextEditingController _registerConfirmController = TextEditingController();
  late final TextEditingController _registerSchoolController = TextEditingController();
  static const List<String> _provinces = [
    '北京市',
    '天津市',
    '河北省',
    '山西省',
    '内蒙古自治区',
    '辽宁省',
    '吉林省',
    '黑龙江省',
    '上海市',
    '江苏省',
    '浙江省',
    '安徽省',
    '福建省',
    '江西省',
    '山东省',
    '河南省',
    '湖北省',
    '湖南省',
    '广东省',
    '广西壮族自治区',
    '海南省',
    '重庆市',
    '四川省',
    '贵州省',
    '云南省',
    '西藏自治区',
    '陕西省',
    '甘肃省',
    '青海省',
    '宁夏回族自治区',
    '新疆维吾尔自治区',
  ];
  String? _selectedProvince;

  @override
  void initState() {
    super.initState();
    _selectedProvince = _provinces.first;
  }

  void _toggleTab(bool isLogin) {
    if (_isLoginSelected == isLogin) {
      return;
    }
    setState(() => _isLoginSelected = isLogin);
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请填写此字段';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请再次输入密码';
    }
    if (value != _registerPasswordController.text) {
      return '两次输入的密码不一致';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (widget.isLoading) {
      return;
    }
    final key = _isLoginSelected ? _loginKey : _registerKey;
    if (key.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      if (_isLoginSelected) {
        await widget.onLogin(
          AuthCredentials(
            username: _loginIdController.text.trim(),
            password: _loginPasswordController.text,
          ),
        );
      } else {
        await widget.onRegister(
          RegistrationPayload(
            username: _registerIdController.text.trim(),
            password: _registerPasswordController.text,
            confirmPassword: _registerConfirmController.text,
            province: _selectedProvince!,
            schoolName: _registerSchoolController.text.trim(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _loginPasswordController.dispose();
    _registerIdController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    _registerSchoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33090F26),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 16),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text('🎓', style: theme.textTheme.headlineMedium),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '高考志愿填报系统',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '科学填报 · 智慧择校',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _AuthTabBar(
                        isLoginSelected: _isLoginSelected,
                        onTabSelected: _toggleTab,
                      ),
                      const SizedBox(height: 24),
                      if (widget.errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 100),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              widget.errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isLoginSelected
                            ? _LoginForm(
                                formKey: _loginKey,
                                userIdController: _loginIdController,
                                passwordController: _loginPasswordController,
                                validator: _requiredValidator,
                              )
                            : _RegisterForm(
                                formKey: _registerKey,
                                userIdController: _registerIdController,
                                passwordController: _registerPasswordController,
                                confirmController: _registerConfirmController,
                                schoolController: _registerSchoolController,
                                provinces: _provinces,
                                selectedProvince: _selectedProvince,
                                onProvinceChanged: (value) => setState(() => _selectedProvince = value),
                                requiredValidator: _requiredValidator,
                                confirmValidator: _confirmPasswordValidator,
                              ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2C5BF0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: widget.isLoading ? null : () => _onSubmit(),
                          child: widget.isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2.2),
                                    ),
                                    SizedBox(width: 12),
                                    Text('请稍候...'),
                                  ],
                                )
                              : Text(_isLoginSelected ? '立即登录' : '注册账号'),
                        ),
                      ),
                    ],
                  ),
                ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTabBar extends StatelessWidget {
  const _AuthTabBar({
    required this.isLoginSelected,
    required this.onTabSelected,
  });

  final bool isLoginSelected;
  final ValueChanged<bool> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _AuthTabButton(
              label: '登录',
              isSelected: isLoginSelected,
              onTap: () => onTabSelected(true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AuthTabButton(
              label: '注册',
              isSelected: !isLoginSelected,
              onTap: () => onTabSelected(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? const Color(0xFF2C5BF0) : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.userIdController,
    required this.passwordController,
    required this.validator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        key: const ValueKey('login-form'),
        children: [
          _AuthField(
            label: '用户名',
            hintText: '请输入用户名',
            controller: userIdController,
            validator: validator,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          _AuthField(
            label: '密码',
            hintText: '请输入密码',
            obscureText: true,
            controller: passwordController,
            validator: validator,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.formKey,
    required this.userIdController,
    required this.passwordController,
    required this.confirmController,
    required this.schoolController,
    required this.provinces,
    required this.selectedProvince,
    required this.onProvinceChanged,
    required this.requiredValidator,
    required this.confirmValidator,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final TextEditingController schoolController;
  final List<String> provinces;
  final String? selectedProvince;
  final ValueChanged<String?> onProvinceChanged;
  final String? Function(String?) requiredValidator;
  final String? Function(String?) confirmValidator;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        key: const ValueKey('register-form'),
        children: [
          _AuthField(
            label: '用户名',
            hintText: '请输入用户名（5-20个字符）',
            controller: userIdController,
            validator: requiredValidator,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '所在省份',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedProvince,
            isExpanded: true,
            validator: (value) => value == null || value.isEmpty ? '请选择所在省份' : null,
            onChanged: onProvinceChanged,
            hint: const Text('请选择所在省份', style: TextStyle(color: Colors.white70)),
            items: provinces
                .map(
                  (p) => DropdownMenuItem<String>(
                    value: p,
                    child: Text(p, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Colors.white),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            ),
            dropdownColor: const Color(0xFF2C5BF0),
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: Colors.white70,
          ),
          const SizedBox(height: 18),
          _AuthField(
            label: '学校名称',
            hintText: '请输入所在学校',
            controller: schoolController,
            validator: requiredValidator,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          _AuthField(
            label: '密码',
            hintText: '请输入密码',
            obscureText: true,
            controller: passwordController,
            validator: requiredValidator,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          _AuthField(
            label: '确认密码',
            hintText: '再次输入密码',
            obscureText: true,
            controller: confirmController,
            validator: confirmValidator,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.validator,
    this.controller,
    this.textInputAction,
  });

  final String label;
  final String hintText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: obscureText,
          validator: validator,
          controller: controller,
          textInputAction: textInputAction,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.white),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ],
    );
  }
}

