import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/models/auth_models.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'profile_edit_page.dart';
import 'profile_weight_page.dart';
import 'profile_share_page.dart';
import 'profile_notification_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.user,
    required this.onSignOut,
    required this.onEditProfile,
    required this.onAdjustWeights,
    required this.onManageShare,
    super.key,
  });

  final AuthUser user;
  final VoidCallback onSignOut;
  final VoidCallback onEditProfile;
  final VoidCallback onAdjustWeights;
  final VoidCallback onManageShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 个人名片区域
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C5BF0), Color(0xFF5B7FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x402C5BF0),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // 头像
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.username.isNotEmpty 
                            ? user.username[0].toUpperCase() 
                            : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C5BF0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 用户信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username.isNotEmpty ? user.username : '未设置',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'ID: ${user.userId}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 快速信息展示
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickInfoItem(
                          icon: Icons.place_rounded,
                          label: user.province ?? '未填写',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _QuickInfoItem(
                          icon: Icons.school_rounded,
                          label: user.schoolName ?? '未填写',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 功能入口列表
          Text(
            '功能中心',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2430),
            ),
          ),
          const SizedBox(height: 12),
          
          _FunctionTile(
            icon: Icons.person_outline_rounded,
            title: '账户信息',
            subtitle: '查看和修改个人资料',
            color: const Color(0xFF2C5BF0),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileEditPage(user: user),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          
          _FunctionTile(
            icon: Icons.tune_rounded,
            title: '偏好权重',
            subtitle: '调整推荐算法权重配置',
            color: const Color(0xFFFF9500),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileWeightPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          
          _FunctionTile(
            icon: Icons.share_rounded,
            title: '共享设置',
            subtitle: '管理与家长、老师的协同',
            color: const Color(0xFF21B573),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileSharePage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          
          _FunctionTile(
            icon: Icons.notifications_outlined,
            title: '通知提醒',
            subtitle: '管理各类消息推送',
            color: const Color(0xFF00B8D4),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileNotificationPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // 退出登录按钮
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('确认退出'),
                    content: const Text('确定要退出登录吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onSignOut();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF04F52),
                        ),
                        child: const Text('退出'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('退出登录'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF04F52),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoItem extends StatelessWidget {
  const _QuickInfoItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FunctionTile extends StatelessWidget {
  const _FunctionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8ECF4)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
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
      ),
    );
  }
}
