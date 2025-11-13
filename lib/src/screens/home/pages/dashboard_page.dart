import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/stat_chip.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';
import 'analysis_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onGoInfo,
    required this.onGoRecommend,
    required this.onGoProfile,
    required this.onGoCollege,
    required this.onGoAnalysis,
  });

  final VoidCallback onGoInfo;
  final VoidCallback onGoRecommend;
  final VoidCallback onGoProfile;
  final VoidCallback onGoCollege;
  final VoidCallback onGoAnalysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Hi，李同学',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2430),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.waving_hand_rounded, color: Color(0xFFFFA726)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '高考倒计时 48 天，系统已为你整合成绩、目标及风险提醒',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7C8698),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          const _StatSummary(),
          const SizedBox(height: 20),
          _QuickActions(
            onGoInfo: onGoInfo,
            onGoRecommend: onGoRecommend,
            onGoProfile: onGoProfile,
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '成绩定位',
            subtitle: '高考成绩 · 2025 届',
            trailing: const _Badge(label: '完成度 82%'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ScoreOverview(),
                SizedBox(height: 18),
                _ScoreTags(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onGoAnalysis, child: const Text('查看分析 →')),
          ),
          const SizedBox(height: 16),
          const _MessageBanner(),
          const SizedBox(height: 20),
          SectionCard(
            title: '目标追踪',
            trailing: TextButton(onPressed: onGoCollege, child: const Text('查看全部 →')),
            child: Column(
              children: const [
                _GoalRow(
                  title: '华东师范大学',
                  subtitle: '稳妥 · 位次差距缩小 320 名',
                  variant: _StatusTagVariant.steady,
                ),
                SizedBox(height: 12),
                _GoalRow(
                  title: '浙江大学',
                  subtitle: '冲刺 · 建议强化数学与语文',
                  variant: _StatusTagVariant.risk,
                ),
                SizedBox(height: 12),
                _GoalRow(
                  title: '北京理工大学',
                  subtitle: '稳妥 · 工科特色契合选科',
                  variant: _StatusTagVariant.steady,
                ),
                SizedBox(height: 12),
                _GoalRow(
                  title: '东北师范大学',
                  subtitle: '保底 · 历年本校成功率 92%',
                  variant: _StatusTagVariant.safe,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '成绩趋势',
            subtitle: '最近 3 次模考',
            trailing: const _Badge(label: '实时更新'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ChartPlaceholder(
                  label: '成绩趋势图表',
                  icon: Icons.show_chart_rounded,
                ),
                SizedBox(height: 16),
                _TrendRow(label: '市二模（最新）', value: '621 分 ▲ +6'),
                SizedBox(height: 10),
                _TrendRow(label: '区一模', value: '634 分 ▲ +19'),
                SizedBox(height: 10),
                _TrendRow(label: '校段考', value: '615 分'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '单科分析',
            subtitle: '个人能力评估',
            trailing: const _Badge(label: '雷达对比'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _RadarSection(),
                SizedBox(height: 18),
                _SubjectProgress(
                  label: '数学',
                  valueLabel: '92%',
                  progress: 0.92,
                  color: Color(0xFF21B573),
                  description: '强项，继续保持',
                ),
                SizedBox(height: 16),
                _SubjectProgress(
                  label: '语文',
                  valueLabel: '81%',
                  progress: 0.81,
                  color: Color(0xFFFF9F43),
                  description: '需要加强作文和阅读',
                ),
                SizedBox(height: 16),
                _SubjectProgress(
                  label: '英语',
                  valueLabel: '91%',
                  progress: 0.91,
                  color: Color(0xFF21B573),
                  description: '保持优势',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatSummary extends StatelessWidget {
  const _StatSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: StatChip(
                label: '综合分数',
                value: '628',
                meta: '位次 12,430',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatChip(
                label: '匹配院校',
                value: '28 所',
                meta: '偏好匹配完成',
                variant: StatChipVariant.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: StatChip(
                label: '目标院校',
                value: '5 所',
                meta: '已添加追踪',
                variant: StatChipVariant.warning,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatChip(
                label: '差距分析',
                value: '6 分',
                meta: '距目标院校',
                variant: StatChipVariant.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onGoInfo,
    required this.onGoRecommend,
    required this.onGoProfile,
  });

  final VoidCallback onGoInfo;
  final VoidCallback onGoRecommend;
  final VoidCallback onGoProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickActionButton(
          icon: Icons.edit_note_rounded,
          label: '完善高考信息',
          subtitle: '录入成绩、选科和偏好',
          tone: _QuickActionTone.primary,
          onTap: onGoInfo,
        ),
        const SizedBox(height: 12),
        _QuickActionButton(
          icon: Icons.track_changes_rounded,
          label: '生成志愿推荐',
          subtitle: '基于您的信息智能匹配院校',
          tone: _QuickActionTone.neutral,
          onTap: onGoRecommend,
        ),
        const SizedBox(height: 12),
        _QuickActionButton(
          icon: Icons.analytics_rounded,
          label: '查看成绩分析',
          subtitle: '了解单科强弱和提升路线',
          tone: _QuickActionTone.outline,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnalysisPage()),
            );
          },
        ),
      ],
    );
  }
}

enum _QuickActionTone { primary, neutral, outline }

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final _QuickActionTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    switch (tone) {
      case _QuickActionTone.primary:
        background = const Color(0xFFFF9500); // 橙色背景
        foreground = Colors.white;
        break;
      case _QuickActionTone.neutral:
        background = const Color(0xFF007AFF); // 蓝色背景
        foreground = Colors.white;
        break;
      case _QuickActionTone.outline:
        background = const Color(0xFFF2F2F7); // 浅灰色背景
        foreground = const Color(0xFF007AFF); // 蓝色文字
        break;
    }

    return Container(
      width: double.infinity,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 24, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: foreground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: foreground.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x142C5BF0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C5BF0),
            ),
      ),
    );
  }
}

class _ScoreOverview extends StatelessWidget {
  const _ScoreOverview();

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
              Text(
                '628',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C5BF0),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '位次：12,430\nTop 3.1%',
                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF7C8698)),
              ),
            ],
          ),
        ),
        const _ProgressRing(percentage: 0.68),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.percentage});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x3321B573), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: 8,
              backgroundColor: const Color(0x1A21B573),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF21B573)),
            ),
          ),
          Text(
            '${(percentage * 100).round()}%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2430),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTags extends StatelessWidget {
  const _ScoreTags();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        TagChip(label: '目标地：长三角'),
        TagChip(label: '专业：教育学'),
        TagChip(label: '院校层次：985'),
      ],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x1400B8D4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, size: 24, color: Color(0xFF00B8D4)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '系统提示',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '已为您匹配 28 所院校，建议合理分配"冲刺"、"稳妥"、"保底"院校比例，确保志愿填报安全。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _StatusTagVariant { steady, risk, safe }

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.title,
    required this.subtitle,
    required this.variant,
  });

  final String title;
  final String subtitle;
  final _StatusTagVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7C8698)),
              ),
            ],
          ),
        ),
        _StatusTag(variant: variant),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.variant});

  final _StatusTagVariant variant;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;
    String label;

    switch (variant) {
      case _StatusTagVariant.steady:
        background = const Color(0x1421B573);
        foreground = const Color(0xFF21B573);
        label = '稳妥';
        break;
      case _StatusTagVariant.risk:
        background = const Color(0x14F04F52);
        foreground = const Color(0xFFF04F52);
        label = '冲刺';
        break;
      case _StatusTagVariant.safe:
        background = const Color(0x1421B573);
        foreground = const Color(0xFF21B573);
        label = '安全';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x142C5BF0), Color(0x082C5BF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1A2C5BF0)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF2C5BF0)),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF2C5BF0)),
          ),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF7C8698))),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF1F2430)),
        ),
      ],
    );
  }
}

class _RadarSection extends StatelessWidget {
  const _RadarSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ChartPlaceholder(
          label: '单科雷达图',
          icon: Icons.radar_rounded,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: const [
            _LegendDot(label: '个人表现', color: Color(0xFF2C5BF0)),
            _LegendDot(label: '满分参考', color: Color(0xFF7C8698), faded: true),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color, this.faded = false});

  final String label;
  final Color color;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: faded ? color.withOpacity(0.45) : color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.2), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF7C8698)),
        ),
      ],
    );
  }
}

class _SubjectProgress extends StatelessWidget {
  const _SubjectProgress({
    required this.label,
    required this.valueLabel,
    required this.progress,
    required this.color,
    required this.description,
  });

  final String label;
  final String valueLabel;
  final double progress;
  final Color color;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              valueLabel,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE8ECF4),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF7C8698)),
        ),
      ],
    );
  }
}
