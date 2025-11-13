import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';

class ProfileSharePage extends StatelessWidget {
  const ProfileSharePage({super.key});

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
        title: const Text('共享设置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: '已共享对象',
              subtitle: '管理协同查看权限',
              trailing: FilledButton.tonalIcon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('添加共享对象功能开发中')),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('添加'),
              ),
              child: Column(
                children: [
                  _ShareUserItem(
                    name: '李女士',
                    role: '家长',
                    avatar: 'L',
                    onRemove: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已移除共享')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ShareUserItem(
                    name: '张老师',
                    role: '老师',
                    avatar: '张',
                    onRemove: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已移除共享')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: '共享链接',
              subtitle: '通过链接邀请查看',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x1400B8D4),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                'https://share.zhiyuan.com/abc123',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                  color: const Color(0xFF00B8D4),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('链接已复制')),
                                );
                              },
                              color: const Color(0xFF00B8D4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '有效期：7 天',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF234052),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('链接已刷新')),
                            );
                          },
                          child: const Text('刷新链接'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('分享功能开发中')),
                            );
                          },
                          child: const Text('分享链接'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: '权限说明',
              subtitle: '共享对象可查看内容',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PermissionItem(
                    icon: Icons.check_circle_rounded,
                    text: '查看成绩和分析报告',
                    granted: true,
                  ),
                  const SizedBox(height: 10),
                  _PermissionItem(
                    icon: Icons.check_circle_rounded,
                    text: '查看推荐院校列表',
                    granted: true,
                  ),
                  const SizedBox(height: 10),
                  _PermissionItem(
                    icon: Icons.check_circle_rounded,
                    text: '添加备注和评论',
                    granted: true,
                  ),
                  const SizedBox(height: 10),
                  _PermissionItem(
                    icon: Icons.cancel_rounded,
                    text: '修改个人信息和偏好',
                    granted: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareUserItem extends StatelessWidget {
  const _ShareUserItem({
    required this.name,
    required this.role,
    required this.avatar,
    required this.onRemove,
  });

  final String name;
  final String role;
  final String avatar;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2C5BF0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                avatar,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                TagChip(label: role),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFFF04F52),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({
    required this.icon,
    required this.text,
    required this.granted,
  });

  final IconData icon;
  final String text;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = granted ? const Color(0xFF21B573) : const Color(0xFF7C8698);

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
