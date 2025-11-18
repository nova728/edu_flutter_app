import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';
import 'package:zygc_flutter_prototype/src/widgets/timeline_item.dart';

class HeatPage extends StatelessWidget {
  const HeatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _HeatStatBlock(
                  title: '热度上涨院校',
                  value: '12',
                  meta: '较去年同期',
                  color: Color(0xFFF04F52),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _HeatStatBlock(
                  title: '热度持平院校',
                  value: '45',
                  meta: '波动 ±5%',
                  color: Color(0xFF2C5BF0),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _HeatStatBlock(
                  title: '热度下降院校',
                  value: '8',
                  meta: '潜在机会',
                  color: Color(0xFF21B573),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionCard(
            title: '热度预警列表',
            subtitle: '关注扎堆风险与潜在机会',
            child: Column(
              children: [
                _HeatRow(
                  school: '复旦大学',
                  major: '教育学',
                  change: '+18%',
                  variant: HeatVariant.danger,
                  suggestion: '热度异常上涨，建议增加稳妥院校。',
                ),
                SizedBox(height: 12),
                _HeatRow(
                  school: '同济大学',
                  major: '人文社科',
                  change: '+12%',
                  variant: HeatVariant.warning,
                  suggestion: '关注招生计划变化，适当调整定位。',
                ),
                SizedBox(height: 12),
                _HeatRow(
                  school: '上海交通大学',
                  major: '综合',
                  change: '+9%',
                  variant: HeatVariant.warning,
                  suggestion: '持续观察并注意退档风险。',
                ),
                SizedBox(height: 12),
                _HeatRow(
                  school: '南京师范大学',
                  major: '教育学',
                  change: '-5%',
                  variant: HeatVariant.positive,
                  suggestion: '竞争压力下降，可列为备选。',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '热度趋势图',
            subtitle: '近 30 天走势',
            trailing: const TagChip(label: '自动刷新'),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x0F2C5BF0), Color(0x082C5BF0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(child: Text('📊 报考热度折线图占位')),
            ),
          ),
          const SizedBox(height: 20),
          const SectionCard(
            title: '提醒记录',
            subtitle: '与老师共享同步',
            child: Column(
              children: [
                TimelineItem(
                  timestamp: '10:24',
                  content: '复旦大学热度上涨提醒已推送。',
                  variant: TimelineVariant.danger,
                ),
                TimelineItem(
                  timestamp: '昨日 16:05',
                  content: '上海交大热度提醒同步给张老师。',
                ),
                TimelineItem(
                  timestamp: '昨日 09:12',
                  content: '新增南京师范大学热度下降机会提示。',
                  variant: TimelineVariant.positive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatStatBlock extends StatelessWidget {
  const _HeatStatBlock({
    required this.title,
    required this.value,
    required this.meta,
    required this.color,
  });

  final String title;
  final String value;
  final String meta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8))),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(meta, style: theme.textTheme.bodySmall?.copyWith(color: color.withOpacity(0.7))),
        ],
      ),
    );
  }
}

enum HeatVariant { danger, warning, positive }

class _HeatRow extends StatelessWidget {
  const _HeatRow({
    required this.school,
    required this.major,
    required this.change,
    required this.variant,
    required this.suggestion,
  });

  final String school;
  final String major;
  final String change;
  final HeatVariant variant;
  final String suggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _paletteForVariant(variant);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(school, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(major, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7C8698))),
                ],
              ),
              Text(
                change,
                style: theme.textTheme.titleMedium?.copyWith(color: palette.accent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(suggestion, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _HeatPalette {
  const _HeatPalette({
    required this.background,
    required this.border,
    required this.accent,
  });

  final Color background;
  final Color border;
  final Color accent;
}

_HeatPalette _paletteForVariant(HeatVariant variant) {
  switch (variant) {
    case HeatVariant.danger:
      return const _HeatPalette(
        background: Color(0x14F04F52),
        border: Color(0x1AF04F52),
        accent: Color(0xFFF04F52),
      );
    case HeatVariant.warning:
      return const _HeatPalette(
        background: Color(0x14FF9F43),
        border: Color(0x1AFF9F43),
        accent: Color(0xFFED8C2F),
      );
    case HeatVariant.positive:
      return const _HeatPalette(
        background: Color(0x1421B573),
        border: Color(0x1A21B573),
        accent: Color(0xFF21B573),
      );
  }
}