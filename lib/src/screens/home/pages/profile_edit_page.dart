import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/models/auth_models.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'package:zygc_flutter_prototype/src/services/api_client.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({required this.user, super.key});

  final AuthUser user;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final ApiClient _client = ApiClient();
  late final TextEditingController _usernameController;
  late final TextEditingController _provinceController;
  late final TextEditingController _schoolController;
  late final TextEditingController _oldPasswordController;
  late final TextEditingController _newPasswordController;
  bool _showPasswordForm = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _provinceController = TextEditingController(text: widget.user.province);
    _schoolController = TextEditingController(text: widget.user.schoolName);
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _provinceController.dispose();
    _schoolController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('账户信息'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: '基本资料',
              subtitle: '完善个人信息',
              child: Column(
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '姓名',
                      hintText: '请输入姓名',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: widget.user.userId),
                    decoration: const InputDecoration(
                      labelText: '账号 ID',
                      prefixIcon: Icon(Icons.fingerprint_rounded),
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _provinceController,
                    decoration: const InputDecoration(
                      labelText: '所在省份',
                      hintText: '请输入省份',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _schoolController,
                    decoration: const InputDecoration(
                      labelText: '毕业高中',
                      hintText: '请输入学校名称',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: '账户安全',
              subtitle: '保护账户安全',
              child: Column(
                children: [
                  _SecurityItem(
                    icon: Icons.lock_outline_rounded,
                    title: '修改密码',
                    subtitle: '定期更换密码保障安全',
                    onTap: () {
                      setState(() {
                        _showPasswordForm = !_showPasswordForm;
                      });
                    },
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      children: [
                        const SizedBox(height: 12),
                        TextField(
                          controller: _oldPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '旧密码',
                            hintText: '请输入旧密码',
                            prefixIcon: Icon(Icons.lock_open_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '新密码',
                            hintText: '请输入新密码',
                            prefixIcon: Icon(Icons.lock_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async {
                              final oldPwd = _oldPasswordController.text.trim();
                              final newPwd = _newPasswordController.text.trim();
                              if (oldPwd.isEmpty || newPwd.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('请输入旧密码和新密码')),
                                );
                                return;
                              }
                              try {
                                final scope = AuthScope.of(context);
                                final token = scope.session.token;
                                await _client.post(
                                  '/users/change-password',
                                  headers: {'Authorization': 'Bearer $token'},
                                  body: {
                                    'oldPassword': oldPwd,
                                    'newPassword': newPwd,
                                  },
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('密码修改成功')),
                                );
                                setState(() {
                                  _showPasswordForm = false;
                                });
                                _oldPasswordController.clear();
                                _newPasswordController.clear();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('修改失败：$e')),
                                );
                              }
                            },
                            child: const Text('确认修改'),
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: _showPasswordForm
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final username = _usernameController.text.trim();
                  final schoolName = _schoolController.text.trim();
                  final body = <String, dynamic>{};
                  if (username.isNotEmpty && username != (widget.user.username)) {
                    body['username'] = username;
                  }
                  body['schoolName'] = schoolName;
                  if (body.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('没有可更新的字段')),
                    );
                    return;
                  }
                  try {
                    final scope = AuthScope.of(context);
                    final token = scope.session.token;
                    final res = await _client.patch(
                      '/users/me',
                      headers: {'Authorization': 'Bearer $token'},
                      body: body,
                    );
                    final updated = res['user'];
                    if (updated is Map<String, dynamic>) {
                      final newUser = AuthUser.fromJson(updated);
                      scope.onUpdateUser(newUser);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('信息保存成功')),
                    );
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('保存失败：$e')),
                    );
                    debugPrint('保存失败：$e');
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('保存修改'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityItem extends StatelessWidget {
  const _SecurityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2C5BF0)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7C8698),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF7C8698),
            ),
          ],
        ),
      ),
    );
  }
}