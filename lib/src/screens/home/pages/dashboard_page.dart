import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/stat_chip.dart';
import 'score_ai_analysis_page.dart';
import 'majors_search_page.dart';
import 'favorite_colleges_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final username = AuthScope.of(context).session.user.username;
    final greetingName = username.isNotEmpty ? username : '同学';

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
                  'Hi，$greetingName',
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
          SectionCard(
            title: '成绩定位',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScoreOverview(),
                const SizedBox(height: 18),
                const _ScoreTags(),
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
          SectionCard(
            title: '成绩趋势',
            subtitle: '最近 5 次考试',
            trailing: const _Badge(label: '实时更新'),
            child: FutureBuilder<List<_TrendPoint>>(
              future: _loadTrendData(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final points = snapshot.data ?? const <_TrendPoint>[];
                if (points.length < 2) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('暂无足够趋势数据，请先录入多次成绩')),
                  );
                }
                final latest = points.reversed.take(3).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TrendChartView(points: points),
                    const SizedBox(height: 16),
                    for (var i = 0; i < latest.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _TrendRow(
                        label: latest[i].label,
                        value: _formatTrendValue(
                          latest[i],
                          i + 1 < latest.length ? latest[i + 1] : null,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '单科分析',
            subtitle: '个人能力评估',
            trailing: const _Badge(label: '雷达对比'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SubjectRadarChart(),
                const SizedBox(height: 18),
                const _CoreSubjectProgressList(),
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
              MaterialPageRoute(builder: (_) => const ScoreAiAnalysisPage()),
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
    final raw = prefs.getString('scores_${scope.session.user.userId}');
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

Future<List<_TrendPoint>> _loadTrendData(BuildContext context) async {
  final scope = AuthScope.of(context);
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('scores_${scope.session.user.userId}');
  if (raw == null || raw.isEmpty) {
    return [
      _TrendPoint(label: '示例一', score: 620, createdAt: DateTime(2024, 3, 10)),
      _TrendPoint(label: '示例二', score: 632, createdAt: DateTime(2024, 5, 12)),
      _TrendPoint(label: '示例三', score: 648, createdAt: DateTime(2024, 6, 18)),
    ];
  }
  final decoded = (jsonDecode(raw) as List).cast<dynamic>();
  final points = <_TrendPoint>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final map = item.map((k, v) => MapEntry(k.toString(), v));
    final score = _extractDouble(map, [
      'TOTAL_SCORE',
      'totalScore',
      'SCORE',
      'score',
      'SUM_SCORE',
      'sumScore',
    ]);
    if (score == null || score <= 0) continue;
    final label = (map['MOCK_EXAM_NAME'] ??
            map['mockExamName'] ??
            (map['EXAM_YEAR'] ?? map['examYear']))
        ?.toString()
        .trim();
    final createdRaw =
        map['CREATED_AT'] ?? map['createdAt'] ?? map['EXAM_YEAR'] ?? map['examYear'];
    DateTime createdAt = DateTime.now();
    if (createdRaw != null) {
      createdAt = DateTime.tryParse(createdRaw.toString()) ??
          DateTime(createdRaw is int ? createdRaw : DateTime.now().year);
    }
    points.add(_TrendPoint(
      label: (label != null && label.isNotEmpty) ? label : createdAt.year.toString(),
      score: score,
      createdAt: createdAt,
    ));
  }
  if (points.isEmpty) {
    return [
      _TrendPoint(label: '示例一', score: 620, createdAt: DateTime(2024, 3, 10)),
      _TrendPoint(label: '示例二', score: 632, createdAt: DateTime(2024, 5, 12)),
      _TrendPoint(label: '示例三', score: 648, createdAt: DateTime(2024, 6, 18)),
    ];
  }
  points.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return points.take(5).toList().reversed.toList();
}

double? _extractDouble(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

class _TrendChartView extends StatelessWidget {
  const _TrendChartView({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: _TrendChart(points: points),
    );
  }
}

String _formatTrendValue(_TrendPoint current, _TrendPoint? previous) {
  final scoreText = '${current.score.round()} 分';
  if (previous == null) return scoreText;
  final diff = current.score - previous.score;
  if (diff > 0.1) return '$scoreText ▲ +${diff.round().abs()}';
  if (diff < -0.1) return '$scoreText ▼ ${diff.round().abs()}';
  return '$scoreText ▬ 0';
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, 200),
        painter: _TrendChartPainter(points),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter(this.points);

  final List<_TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const double left = 48;
    const double right = 16;
    const double top = 16;
    const double bottom = 36;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    double minValue = points.map((e) => e.score).reduce(math.min);
    double maxValue = points.map((e) => e.score).reduce(math.max);
    if ((maxValue - minValue).abs() < 40) {
      maxValue += 20;
      minValue = (minValue - 20).clamp(0, 750);
    }
    minValue = math.max(0, minValue.floorToDouble());

    final axisPaint = Paint()
      ..color = const Color(0xFFE3E8EF)
      ..strokeWidth = 1;

    final pathPaint = Paint()
      ..color = const Color(0xFF2C5BF0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF2C5BF0).withOpacity(0.25),
          const Color(0xFF2C5BF0).withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));

    const int gridLines = 4;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
    for (int i = 0; i <= gridLines; i++) {
      final dy = top + chartHeight / gridLines * i;
      canvas.drawLine(Offset(left, dy), Offset(left + chartWidth, dy), axisPaint);

      final value = maxValue - (maxValue - minValue) / gridLines * i;
      textPainter.text = TextSpan(
        text: value.round().toString(),
        style: const TextStyle(fontSize: 10, color: Color(0xFF7C8698)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(left - textPainter.width - 6, dy - textPainter.height / 2));
    }

    final dx = chartWidth / (points.length - 1);
    final Path linePath = Path();
    final Path fillPath = Path();
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final x = left + dx * i;
      final normalized = (point.score - minValue) / (maxValue - minValue);
      final y = top + chartHeight * (1 - normalized);

      final offset = Offset(x, y);
      if (i == 0) {
        linePath.moveTo(offset.dx, offset.dy);
        fillPath.moveTo(offset.dx, offset.dy);
      } else {
        linePath.lineTo(offset.dx, offset.dy);
        fillPath.lineTo(offset.dx, offset.dy);
      }
    }
    fillPath.lineTo(left + chartWidth, top + chartHeight);
    fillPath.lineTo(left, top + chartHeight);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, pathPaint);

    final pointPaint = Paint()
      ..color = const Color(0xFF2C5BF0)
      ..style = PaintingStyle.fill;
    final haloPaint = Paint()
      ..color = const Color(0xFF2C5BF0).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final x = left + dx * i;
      final normalized = (point.score - minValue) / (maxValue - minValue);
      final y = top + chartHeight * (1 - normalized);
      canvas.drawCircle(Offset(x, y), 6, haloPaint);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);

      final scorePainter = TextPainter(
        text: TextSpan(
          text: point.score.round().toString(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A1F2E)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      scorePainter.paint(canvas, Offset(x - scorePainter.width / 2, y - 24));

      final labelPainter = TextPainter(
        text: TextSpan(
          text: point.label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF7C8698)),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: dx + 24);
      labelPainter.paint(canvas, Offset(x - labelPainter.width / 2, top + chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) => oldDelegate.points != points;
}

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.score,
    required this.createdAt,
  });

  final String label;
  final double score;
  final DateTime createdAt;
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
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF7C8698)),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2430),
          ),
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
            Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            Text(
              valueLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
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

class _SubjectRadarChart extends StatelessWidget {
  const _SubjectRadarChart();

  Future<List<_RadarEntry>> _loadRadarData(BuildContext context) async {
    final scope = AuthScope.of(context);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('scores_${scope.session.user.userId}');
    if (raw == null || raw.isEmpty) return const [];
    final decoded = (jsonDecode(raw) as List).cast<dynamic>();
    _RadarEntry? entryFactory(String key, double value) {
      final max = _subjectMaxScore[key] ?? 150;
      if (max <= 0 || value <= 0) return null;
      final ratio = (value / max).clamp(0.0, 1.0);
      return _RadarEntry(label: key, value: value, maxValue: max.toDouble(), ratio: ratio);
    }

    decoded.sort((a, b) {
      final mapA = (a as Map).map((k, v) => MapEntry(k.toString(), v));
      final mapB = (b as Map).map((k, v) => MapEntry(k.toString(), v));
      final timeA = DateTime.tryParse((mapA['CREATED_AT'] ?? mapA['createdAt'] ?? '').toString()) ??
          DateTime(mapA['EXAM_YEAR'] is int ? mapA['EXAM_YEAR'] as int : DateTime.now().year);
      final timeB = DateTime.tryParse((mapB['CREATED_AT'] ?? mapB['createdAt'] ?? '').toString()) ??
          DateTime(mapB['EXAM_YEAR'] is int ? mapB['EXAM_YEAR'] as int : DateTime.now().year);
      return timeB.compareTo(timeA);
    });

    for (final item in decoded) {
      if (item is! Map) continue;
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      final detailRaw = map['SCORE_DETAILS'] ?? map['scoreDetails'];
      if (detailRaw is! Map) continue;
      final details = detailRaw.map((key, value) => MapEntry(key.toString(), value));
      final entries = <_RadarEntry>[];
      for (final entry in details.entries) {
        final value = double.tryParse(entry.value?.toString() ?? '');
        if (value == null) continue;
        final normalizedKey = entry.key.replaceAll('（', '(').replaceAll('）', ')');
        final radarEntry = entryFactory(normalizedKey, value);
        if (radarEntry != null) entries.add(radarEntry);
      }
      if (entries.length >= 3) {
        return entries.take(6).toList();
      }
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_RadarEntry>>(
      future: _loadRadarData(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final entries = snapshot.data!;
        if (entries.length < 3) {
          return Container(
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('暂无单科明细，请先录入包含科目成绩的记录'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _RadarPainter(entries),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: entries.map((e) {
                final percent = (e.ratio * 100).round();
                return TagChip(label: '${e.label} $percent%');
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.entries);

  final List<_RadarEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final int count = entries.length;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 24;
    final double angleStep = 2 * math.pi / count;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFE3E8EF)
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF2C5BF0).withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = const Color(0xFF2C5BF0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const int layers = 4;
    for (int level = layers; level >= 1; level--) {
      final double layerRadius = radius * level / layers;
      final Path layerPath = Path();
      for (int i = 0; i < count; i++) {
        final double angle = -math.pi / 2 + angleStep * i;
        final Offset point = center + Offset(math.cos(angle), math.sin(angle)) * layerRadius;
        if (i == 0) {
          layerPath.moveTo(point.dx, point.dy);
        } else {
          layerPath.lineTo(point.dx, point.dy);
        }
      }
      layerPath.close();
      canvas.drawPath(layerPath, gridPaint..color = gridPaint.color.withOpacity(level == layers ? 1 : 0.3));
    }

    final Path radarPath = Path();
    for (int i = 0; i < count; i++) {
      final double angle = -math.pi / 2 + angleStep * i;
      final double entryRadius = radius * entries[i].ratio;
      final Offset point = center + Offset(math.cos(angle), math.sin(angle)) * entryRadius;
      if (i == 0) {
        radarPath.moveTo(point.dx, point.dy);
      } else {
        radarPath.lineTo(point.dx, point.dy);
      }
      canvas.drawLine(center, center + Offset(math.cos(angle), math.sin(angle)) * radius,
          gridPaint..color = const Color(0xFFE3E8EF));
    }
    radarPath.close();
    canvas.drawPath(radarPath, fillPaint);
    canvas.drawPath(radarPath, borderPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < count; i++) {
      final double angle = -math.pi / 2 + angleStep * i;
      final Offset labelPoint = center + Offset(math.cos(angle), math.sin(angle)) * (radius + 14);
      final entry = entries[i];
      textPainter.text = TextSpan(
        text: entry.label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF424A59), fontWeight: FontWeight.w600),
      );
      textPainter.layout(maxWidth: 80);
      final offset = Offset(
        labelPoint.dx - textPainter.width / 2,
        labelPoint.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.entries != entries;
}

class _RadarEntry {
  const _RadarEntry({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.ratio,
  });

  final String label;
  final double value;
  final double maxValue;
  final double ratio;
}

const Map<String, int> _subjectMaxScore = {
  '语文': 150,
  '数学': 150,
  '英语': 150,
  '物理': 100,
  '化学': 100,
  '生物': 100,
  '政治': 100,
  '历史': 100,
  '地理': 100,
  '理综': 300,
  '文综': 300,
};

class _CoreSubjectProgressList extends StatelessWidget {
  const _CoreSubjectProgressList();

  Future<List<_SubjectScore>> _load(BuildContext context) => _loadCoreSubjectScores(context);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_SubjectScore>>(
      future: _load(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Text(
            '单科数据加载失败，请稍后重试。',
            style: TextStyle(color: Color(0xFFF04F52)),
          );
        }
        final subjects = snapshot.data ?? <_SubjectScore>[];
        if (subjects.isEmpty) {
          return const Text(
            '暂无单科成绩数据，请先录入包含语文、数学、英语的成绩记录。',
            style: TextStyle(color: Color(0xFF7C8698)),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < subjects.length; i++) ...[
              _SubjectProgress(
                label: subjects[i].label,
                valueLabel: '${(subjects[i].ratio * 100).round()}%',
                progress: subjects[i].ratio,
                color: _subjectColor(subjects[i].ratio),
                description: _subjectDescription(subjects[i].label, subjects[i].ratio),
              ),
              if (i < subjects.length - 1) const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _SubjectScore {
  _SubjectScore({
    required this.label,
    required this.score,
    required this.maxScore,
  }) : ratio = (score / maxScore).clamp(0.0, 1.0);

  final String label;
  final double score;
  final double maxScore;
  final double ratio;
}

Color _subjectColor(double ratio) {
  if (ratio >= 0.9) return const Color(0xFF21B573);
  if (ratio >= 0.8) return const Color(0xFFFF9F43);
  return const Color(0xFFF04F52);
}

String _subjectDescription(String subject, double ratio) {
  if (ratio >= 0.9) return '强项，继续保持';
  if (ratio >= 0.8) return '表现稳定，可继续巩固';
  return '建议提升，关注$subject复习';
}

Future<List<_SubjectScore>> _loadCoreSubjectScores(BuildContext context) async {
  final scope = AuthScope.of(context);
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('scores_${scope.session.user.userId}');
  if (raw == null || raw.isEmpty) return <_SubjectScore>[];
  final decoded = (jsonDecode(raw) as List).cast<dynamic>();
  Map<String, dynamic>? chosen;
  DateTime? chosenTime;
  for (final item in decoded) {
    if (item is! Map) continue;
    final map = item.map((k, v) => MapEntry(k.toString(), v));
    final detailsRaw = map['SCORE_DETAILS'] ?? map['scoreDetails'];
    if (detailsRaw is! Map || detailsRaw.isEmpty) continue;
    final currentTime = _parseScoreTimestamp(map) ?? DateTime.now();
    if (chosen == null || currentTime.isAfter(chosenTime ?? DateTime.fromMillisecondsSinceEpoch(0))) {
      chosen = map;
      chosenTime = currentTime;
    }
  }
  if (chosen == null) return <_SubjectScore>[];
  final detailsRaw = chosen['SCORE_DETAILS'] ?? chosen['scoreDetails'];
  if (detailsRaw is! Map) return <_SubjectScore>[];
  final details = detailsRaw.map((k, v) => MapEntry(k.toString(), v));
  final result = <_SubjectScore>[];
  for (final label in const ['语文', '数学', '英语']) {
    final score = _extractSubjectScore(label, details);
    final max = _subjectMaxScore[label]?.toDouble() ?? 150.0;
    if (score != null && max > 0) {
      result.add(_SubjectScore(label: label, score: score, maxScore: max));
    }
  }
  return result;
}

DateTime? _parseScoreTimestamp(Map<String, dynamic> map) {
  for (final key in const ['CREATED_AT', 'createdAt', 'UPDATED_AT', 'updatedAt']) {
    final raw = map[key];
    if (raw == null) continue;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed != null) return parsed;
  }
  final year = int.tryParse((map['EXAM_YEAR'] ?? map['examYear'])?.toString() ?? '');
  return year != null && year > 0 ? DateTime(year) : null;
}

double? _extractSubjectScore(String subject, Map<String, dynamic> details) {
  double? parse(Object? value) => double.tryParse(value?.toString() ?? '');
  final direct = parse(details[subject]);
  if (direct != null) return direct;
  for (final entry in details.entries) {
    if (entry.key.contains(subject)) {
      final value = parse(entry.value);
      if (value != null) return value;
    }
  }
  return null;
}
