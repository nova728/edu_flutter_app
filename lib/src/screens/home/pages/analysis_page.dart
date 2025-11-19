import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/stat_chip.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

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
        title: const Text('成绩分析'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StatChip(label: '当前总分', value: '628', meta: '较上次 +6'),
                StatChip(label: '目标院校差距', value: '-6', meta: '距浙江大学', variant: StatChipVariant.warning),
                StatChip(label: '全省位次', value: '12,430', meta: 'Top 3.1%', variant: StatChipVariant.primary),
              ],
            ),
            const SizedBox(height: 20),
            const SectionCard(
              title: '单科强弱分析',
              subtitle: '个人得分率分析',
              child: Column(
                children: [
                  _SubjectRow(label: '数学', mine: 138, avg: 150),
                  SizedBox(height: 12),
                  _SubjectRow(label: '语文', mine: 122, avg: 150),
                  SizedBox(height: 12),
                  _SubjectRow(label: '英语', mine: 136, avg: 150),
                  SizedBox(height: 12),
                  _SubjectRow(label: '物理', mine: 86, avg: 100),
                  SizedBox(height: 12),
                  _SubjectRow(label: '化学', mine: 90, avg: 100),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: '成绩趋势图',
              subtitle: '最近 5 次考试',
              trailing: const TagChip(label: '趋势向好'),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0x142C5BF0), Color(0x082C5BF0)]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(child: Text('📈 成绩折线图占位')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.label, required this.mine, required this.avg});

  final String label;
  final int mine;
  final int avg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = ((mine / avg) * 100).round();
    final percentageColor = percentage >= 85 ? const Color(0xFF21B573) : percentage >= 75 ? const Color(0xFFFF9F43) : const Color(0xFFF04F52);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('得分 $mine 分 · 满分 $avg 分',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4B5769))),
              ],
            ),
          ),
          Text(
            '$percentage%',
            style: theme.textTheme.titleMedium?.copyWith(color: percentageColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}


