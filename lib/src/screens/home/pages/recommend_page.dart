import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  double _regionWeight = 0.4;
  double _tierWeight = 0.35;
  double _majorWeight = 0.25;
  final Set<String> _filters = <String>{'全部'};

  void _toggleFilter(String filter) {
    setState(() {
      if (filter == '全部') {
        _filters
          ..clear()
          ..add(filter);
        return;
      }

      if (_filters.contains(filter)) {
        _filters.remove(filter);
      } else {
        _filters
          ..remove('全部')
          ..add(filter);
      }

      if (_filters.isEmpty) {
        _filters.add('全部');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: '智能推荐方案',
            subtitle: '结合客观数据与偏好权重生成院校列表',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x1400B8D4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF234052)),
                      children: const [
                        TextSpan(text: '客观数据：'),
                        TextSpan(text: '历年录取线 40% · 生源因素 25% · 报考历史 15%\n'),
                        TextSpan(text: '主观偏好：'),
                        TextSpan(text: '目标地区 40% · 院校层次 35% · 专业方向 25%'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _PreferenceSlider(
                  label: '目标地区',
                  value: _regionWeight,
                  onChanged: (value) => setState(() => _regionWeight = value),
                ),
                const SizedBox(height: 12),
                _PreferenceSlider(
                  label: '院校层次',
                  value: _tierWeight,
                  onChanged: (value) => setState(() => _tierWeight = value),
                ),
                const SizedBox(height: 12),
                _PreferenceSlider(
                  label: '专业方向',
                  value: _majorWeight,
                  onChanged: (value) => setState(() => _majorWeight = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final filter in const ['全部', '冲刺', '稳妥', '保底', '985院校', '211院校', '长三角'])
                FilterChip(
                  label: Text(filter),
                  selected: _filters.contains(filter),
                  onSelected: (_) => _toggleFilter(filter),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const _CollegeCard(
            name: '华东师范大学',
            location: '上海 · 师范类 · 985/211',
            matchScore: 92,
            probability: 0.68,
            description: '成绩匹配度高（高出 16 分）+ 偏好吻合（教育学 + 长三角）+ 高中历史录取率 86%。',
            tags: [
              TagChip(label: '稳妥', color: Color(0xFF21B573)),
              TagChip(label: '偏好吻合'),
              TagChip(label: '高中录取率 86%', color: Color(0xFF2C5BF0)),
            ],
            highlights: ['2024：最低分 612 | 位次 10,800', '2023：最低分 608 | 位次 11,200', '2022：最低分 606 | 位次 11,650'],
          ),
          const SizedBox(height: 20),
          const _CollegeCard(
            name: '南京大学',
            location: '江苏 · 综合类 · 985/211',
            matchScore: 88,
            probability: 0.54,
            description: '与目标线差距 4 分，偏好匹配度高，建议关注位次提升与复习节奏。',
            tags: [
              TagChip(label: '冲刺', color: Color(0xFFF04F52)),
              TagChip(label: '偏好吻合'),
              TagChip(label: '提升空间'),
            ],
            highlights: ['2024：最低分 632 | 位次 9,200', '2023：最低分 628 | 位次 9,800', '2022：最低分 627 | 位次 10,100'],
          ),
          const SizedBox(height: 20),
          const _CollegeCard(
            name: '北京理工大学',
            location: '北京 · 工科 · 985/211',
            matchScore: 90,
            probability: 0.62,
            description: '当前分数高于近三年录取线 8 分，适合作为稳妥备选。',
            tags: [
              TagChip(label: '稳妥', color: Color(0xFF2C5BF0)),
              TagChip(label: '课程调研'),
            ],
            highlights: ['2024：最低分 620 | 位次 11,600', '2023：最低分 618 | 位次 11,900', '2022：最低分 615 | 位次 12,300'],
          ),
          const SizedBox(height: 20),
          const _CollegeCard(
            name: '东北师范大学',
            location: '吉林 · 师范类 · 211',
            matchScore: 80,
            probability: 0.92,
            description: '成绩优势明显，高于近三年录取线 28 分，是可靠保底选择。',
            tags: [
              TagChip(label: '保底', color: Color(0xFF21B573)),
              TagChip(label: '安全选择'),
              TagChip(label: '高中录取率 92%', color: Color(0xFF21B573)),
            ],
            highlights: ['2024：最低分 598 | 位次 18,500', '2023：最低分 595 | 位次 19,200', '2022：最低分 593 | 位次 19,800'],
          ),
        ],
      ),
    );
  }
}

class _PreferenceSlider extends StatelessWidget {
  const _PreferenceSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

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
            Text('${(value * 100).round()}%', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0.1,
          max: 0.7,
        ),
      ],
    );
  }
}

class _CollegeCard extends StatelessWidget {
  const _CollegeCard({
    required this.name,
    required this.location,
    required this.matchScore,
    required this.probability,
    required this.description,
    required this.tags,
    required this.highlights,
  });

  final String name;
  final String location;
  final int matchScore;
  final double probability;
  final String description;
  final List<Widget> tags;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: name,
      subtitle: location,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            matchScore.toString(),
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Text('匹配指数', style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF7C8698))),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: tags,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: probability,
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${(probability * 100).round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Text(description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('历年录取数据', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                for (final item in highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(item, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4B5769))),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('收藏'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('加入草案'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('查看详情'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
