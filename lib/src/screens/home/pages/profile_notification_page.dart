import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';

class ProfileNotificationPage extends StatefulWidget {
  const ProfileNotificationPage({super.key});

  @override
  State<ProfileNotificationPage> createState() => _ProfileNotificationPageState();
}

class _ProfileNotificationPageState extends State<ProfileNotificationPage> {
  bool _heatAlert = true;
  bool _scoreUpdate = true;
  bool _recommendChange = true;
  bool _collaboratorComment = false;
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
                    icon: Icons.grade_rounded,
                    title: '成绩更新提醒',
                    subtitle: '新成绩录入后推送通知',
                    value: _scoreUpdate,
                    color: const Color(0xFF2C5BF0),
                    onChanged: (value) => setState(() => _scoreUpdate = value),
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
                    icon: Icons.chat_bubble_outline_rounded,
                    title: '协作者评论通知',
                    subtitle: '家长或老师添加备注时提醒',
                    value: _collaboratorComment,
                    color: const Color(0xFF21B573),
                    onChanged: (value) => setState(() => _collaboratorComment = value),
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
            const SizedBox(height: 20),
            SectionCard(
              title: '通知时段',
              subtitle: '设置接收通知的时间',
              child: Column(
                children: [
                  _TimePeriodSelector(
                    label: '免打扰时段',
                    startTime: '22:00',
                    endTime: '07:00',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('时间选择功能开发中')),
                      );
                    },
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

class _TimePeriodSelector extends StatelessWidget {
  const _TimePeriodSelector({
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.onTap,
  });

  final String label;
  final String startTime;
  final String endTime;
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
            const Icon(Icons.access_time_rounded, color: Color(0xFF2C5BF0)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startTime - $endTime',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2C5BF0),
                      fontWeight: FontWeight.w600,
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
