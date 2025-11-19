import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/stat_chip.dart';
import 'analysis_page.dart';
import 'majors_search_page.dart';
import 'favorite_colleges_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';

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
                  'Hi，同学',
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
          const SizedBox(height: 20),
          const _StatSummary(),
          const SizedBox(height: 20),
          _QuickActions(
            onGoInfo: onGoInfo,
            onGoRecommend: onGoRecommend,
            onGoProfile: onGoProfile,
          ),
          const SizedBox(height: 20),
          const SectionCard(
            title: '成绩定位',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScoreOverview(),
                SizedBox(height: 18),
                _ScoreTags(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '目标追踪',
            trailing: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoriteCollegesPage()),
                );
              },
              child: const Text('查看全部 →'),
            ),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: (() async {
                final scope = AuthScope.of(context);
                final userId = scope.session.user.userId;
                final prefs = await SharedPreferences.getInstance();
                final raw = prefs.getString('favorites_$userId');
                if (raw == null || raw.isEmpty) return const <Map<String, dynamic>>[];
                try {
                  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
                  return list;
                } catch (_) {
                  return const <Map<String, dynamic>>[];
                }
              })(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <Map<String, dynamic>>[];
                _StatusTagVariant variantFor(Map<String, dynamic> c) {
                  final cat = (c['category']?.toString() ?? '').trim();
                  final p = (c['probability'] as num?)?.toDouble() ?? 0.0;
                  if (cat == '保' || cat == '保底') return _StatusTagVariant.safe;
                  if (cat == '稳' || cat == '稳妥') return _StatusTagVariant.steady;
                  if (cat == '冲' || cat == '冲刺') return _StatusTagVariant.risk;
                  if (cat == '参考') return _StatusTagVariant.reference;
                  if (p >= 0.75) return _StatusTagVariant.safe;
                  if (p >= 0.4) return _StatusTagVariant.steady;
                  if (p >= 0.2) return _StatusTagVariant.risk;
                  return _StatusTagVariant.reference;
                }
                if (items.isEmpty) {
                  return const Text('暂无目标院校');
                }
                final Map<_StatusTagVariant, Map<String, dynamic>> selected = {};
                for (final c in items) {
                  final v = variantFor(c);
                  selected.putIfAbsent(v, () => c);
                }
                const order = [
                  _StatusTagVariant.reference,
                  _StatusTagVariant.risk,
                  _StatusTagVariant.steady,
                  _StatusTagVariant.safe,
                ];
                final rows = order
                    .where((v) => selected.containsKey(v))
                    .map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GoalRow(
                            title: selected[v]!['name']?.toString() ?? '-',
                            variant: v,
                          ),
                        ))
                    .toList();
                return Column(children: rows);
              },
            ),
          ),
          const SizedBox(height: 20),
          const SectionCard(
            title: '成绩趋势',
            subtitle: '最近 3 次模考',
            trailing: _Badge(label: '实时更新'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          const SectionCard(
            title: '单科分析',
            subtitle: '个人能力评估',
            trailing: _Badge(label: '雷达对比'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

class _StatSummary extends StatefulWidget {
  const _StatSummary();

  @override
  State<_StatSummary> createState() => _StatSummaryState();
}

class _StatSummaryState extends State<_StatSummary> {
  Future<Map<String, dynamic>> _getCounts(BuildContext context) async {
    final scope = AuthScope.of(context);
    final userId = scope.session.user.userId;
    final prefs = await SharedPreferences.getInstance();
    int rec = 0, fav = 0;
    final recRaw = prefs.getString('recommend_plan_$userId');
    if (recRaw != null && recRaw.isNotEmpty) {
      try {
        final m = jsonDecode(recRaw) as Map<String, dynamic>;
        rec = (m['count'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }
    final favRaw = prefs.getString('favorites_$userId');
    if (favRaw != null && favRaw.isNotEmpty) {
      try {
        final list = (jsonDecode(favRaw) as List);
        fav = list.length;
      } catch (_) {}
    }
    double? score;
    int? rank;
    final scoresRaw = prefs.getString('scores_$userId');
    if (scoresRaw != null && scoresRaw.isNotEmpty) {
      try {
        final list = (jsonDecode(scoresRaw) as List).cast<dynamic>();
        for (final e in list) {
          final m = e is Map<String, dynamic> ? e : null;
          if (m == null) continue;
          final mockName = m['MOCK_EXAM_NAME']?.toString() ?? '';
          if (mockName.isNotEmpty) continue;
          for (final c in [m['TOTAL_SCORE'], m['totalScore'], m['SCORE'], m['score'], m['SUM_SCORE'], m['sumScore']]) {
            final s = double.tryParse(c?.toString() ?? '');
            if (s != null && s > 0 && s <= 750) { score = s; break; }
          }
          for (final c in [m['RANK_IN_PROVINCE'], m['rankInProvince'], m['rank'], m['minRank'], m['provinceRank']]) {
            final r = int.tryParse(c?.toString() ?? '');
            if (r != null && r > 0) { rank = r; break; }
          }
          if (score != null || rank != null) break;
        }
      } catch (_) {}
    }
    return {'recommend': rec, 'favorites': fav, 'score': score, 'rank': rank};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCounts(context),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? const {'recommend': 0, 'favorites': 0};
        final recommendCount = (counts['recommend'] as num?)?.toInt() ?? 0;
        final favoritesCount = (counts['favorites'] as num?)?.toInt() ?? 0;
        final scoreVal = (counts['score'] as num?)?.toDouble();
        final rankVal = counts['rank'] as int?;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatChip(
                    label: '综合分数',
                    value: scoreVal != null ? '${scoreVal.round()}' : '-',
                    meta: '位次 ${rankVal != null ? '$rankVal' : '-'}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatChip(
                    label: '匹配院校',
                    value: '$recommendCount 所',
                    meta: recommendCount > 0 ? '已保存推荐方案' : '偏好匹配完成',
                    variant: StatChipVariant.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatChip(
                    label: '目标院校',
                    value: '$favoritesCount 所',
                    meta: favoritesCount > 0 ? '已添加追踪' : '尚未添加',
                    variant: StatChipVariant.warning,
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
          subtitle: '录入成绩、选科',
          tone: _QuickActionTone.primary,
          onTap: onGoInfo,
        ),
        const SizedBox(height: 12),
        _QuickActionButton(
          icon: Icons.search_rounded,
          label: '了解专业信息',
          subtitle: '查询专业与简介',
          tone: _QuickActionTone.outline,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MajorsSearchPage()),
            );
          },
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

    return SizedBox(
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

class _ScoreOverview extends StatefulWidget {
  const _ScoreOverview();

  @override
  State<_ScoreOverview> createState() => _ScoreOverviewState();
}

class _ScoreOverviewState extends State<_ScoreOverview> {
  Future<Map<String, dynamic>> _getScore(BuildContext context) async {
    final scope = AuthScope.of(context);
    final userId = scope.session.user.userId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('scores_$userId');
    double? score;
    int? rank;
    double? topPercent;
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<dynamic>();
        for (final e in list) {
          final m = e is Map<String, dynamic> ? e : null;
          if (m == null) continue;
          final mockName = m['MOCK_EXAM_NAME']?.toString() ?? '';
          if (mockName.isNotEmpty) continue;
          final scCandidates = [m['TOTAL_SCORE'], m['totalScore'], m['SCORE'], m['score'], m['SUM_SCORE'], m['sumScore']];
          for (final c in scCandidates) {
            final s = double.tryParse(c?.toString() ?? '');
            if (s != null && s > 0 && s <= 750) { score = s; break; }
          }
          final rkCandidates = [m['RANK_IN_PROVINCE'], m['rankInProvince'], m['rank'], m['minRank'], m['provinceRank']];
          for (final c in rkCandidates) {
            final r = int.tryParse(c?.toString() ?? '');
            if (r != null && r > 0) { rank = r; break; }
          }
          final tpCandidates = [m['TOP_PERCENT'], m['topPercent'], m['percentile']];
          for (final c in tpCandidates) {
            final t = double.tryParse(c?.toString() ?? '');
            if (t != null && t > 0 && t <= 100) { topPercent = t; break; }
          }
          if (score != null || rank != null) break;
        }
      } catch (_) {}
    }
    final progress = score != null ? (score / 750.0).clamp(0.0, 1.0) : 0.0;
    return {'score': score, 'rank': rank, 'topPercent': topPercent, 'progress': progress};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _getScore(context),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};
        final s = (data['score'] as num?)?.toDouble();
        final r = data['rank'] as int?;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s != null ? s.round().toString() : '-',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C5BF0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '位次：${r != null ? r.toString() : '-'}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF7C8698)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}


class _ScoreTags extends StatelessWidget {
  const _ScoreTags();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
    );
  }
}

enum _StatusTagVariant { steady, risk, safe, reference }

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.title,
    required this.variant,
  });

  final String title;
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
        background = const Color(0x142C5BF0);
        foreground = const Color(0xFF2C5BF0);
        label = '保底';
        break;
      case _StatusTagVariant.reference:
        background = const Color(0x147C8698);
        foreground = const Color(0xFF7C8698);
        label = '参考';
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartPlaceholder(
          label: '单科雷达图',
          icon: Icons.radar_rounded,
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
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
