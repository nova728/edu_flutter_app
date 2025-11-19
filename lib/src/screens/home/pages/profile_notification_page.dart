import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';

class ProfileNotificationPage extends StatefulWidget {
  const ProfileNotificationPage({super.key});

  @override
  State<ProfileNotificationPage> createState() => _ProfileNotificationPageState();
}

class _ProfileNotificationPageState extends State<ProfileNotificationPage> {
  bool _heatAlert = true;

  bool _recommendChange = true;
  bool _systemMessage = true;

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
        title: const Text('通知提醒'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SectionCard(
              title: '推送通知',
              subtitle: '管理各类消息提醒',
              child: Column(
                children: [
                  _NotificationToggle(
                    icon: Icons.warning_amber_rounded,
                    title: '热度预警通知',
                    subtitle: '院校报考热度异常时提醒',
                    value: _heatAlert,
                    color: const Color(0xFFF04F52),
                    onChanged: (value) => setState(() => _heatAlert = value),
                  ),
                  const Divider(height: 24),

                  _NotificationToggle(
                    icon: Icons.auto_awesome_rounded,
                    title: '推荐院校变化通知',
                    subtitle: '推荐列表更新时提醒',
                    value: _recommendChange,
                    color: const Color(0xFFFF9500),
                    onChanged: (value) => setState(() => _recommendChange = value),
                  ),
                  const Divider(height: 24),
                  _NotificationToggle(
                    icon: Icons.notifications_active_rounded,
                    title: '系统消息',
                    subtitle: '重要功能更新和维护通知',
                    value: _systemMessage,
                    color: const Color(0xFF00B8D4),
                    onChanged: (value) => setState(() => _systemMessage = value),
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

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
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
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
