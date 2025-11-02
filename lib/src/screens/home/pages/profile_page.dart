import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: '账户信息',
            subtitle: '高考志愿填报系统账号',
            trailing: FilledButton.tonal(onPressed: () {}, child: const Text('修改信息')),
            child: Column(
              children: [
                _ProfileRow(label: '姓名', value: '李晓同'),
                const SizedBox(height: 12),
                _ProfileRow(label: '账号', value: 'lixiaotong2026'),
                const SizedBox(height: 12),
                _ProfileRow(label: '所在省份', value: '浙江省'),
                const SizedBox(height: 12),
                _ProfileRow(label: '毕业高中', value: '杭州市第二中学'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '偏好权重',
            subtitle: '驱动推荐策略的权重配置',
            trailing: FilledButton.tonal(onPressed: () {}, child: const Text('调整权重')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WeightRow(label: '目标地区', percent: 40, description: '长三角（上海 / 杭州）'),
                const SizedBox(height: 12),
                _WeightRow(label: '院校层次', percent: 35, description: '985 优先，兼顾双一流'),
                const SizedBox(height: 12),
                _WeightRow(label: '专业方向', percent: 25, description: '教育学 / 人文社科'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '共享设置',
            subtitle: '与家长、老师协同备考',
            trailing: FilledButton.tonal(onPressed: () {}, child: const Text('管理权限')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('已共享给：', style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    TagChip(label: '家长 · 李女士'),
                    TagChip(label: '老师 · 张老师'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x1400B8D4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('共享链接', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SelectableText('https://share.zhiyuan.com/abc123', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('有效期：7 天', style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4B5769))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '通知提醒',
            subtitle: '保持信息同步',
            child: Column(
              children: const [
                _ToggleRow(label: '热度预警通知', value: true),
                _ToggleRow(label: '成绩更新提醒', value: true),
                _ToggleRow(label: '推荐院校变化通知', value: true),
                _ToggleRow(label: '协作者评论通知', value: false),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('退出登录'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF04F52),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({required this.label, required this.percent, required this.description});

  final String label;
  final int percent;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(description, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4B5769))),
            ],
          ),
        ),
        Text('${percent}%', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: (_) {},
    );
  }
}
