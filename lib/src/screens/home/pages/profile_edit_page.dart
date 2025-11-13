import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/models/auth_models.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({required this.user, super.key});

  final AuthUser user;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _provinceController;
  late final TextEditingController _schoolController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _provinceController = TextEditingController(text: widget.user.province);
    _schoolController = TextEditingController(text: widget.user.schoolName);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _provinceController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('密码修改功能开发中')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _SecurityItem(
                    icon: Icons.phone_android_rounded,
                    title: '绑定手机',
                    subtitle: '用于接收验证码',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('手机绑定功能开发中')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('信息保存成功')),
                  );
                  Navigator.of(context).pop();
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
