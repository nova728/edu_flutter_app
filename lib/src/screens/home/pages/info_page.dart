import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: '基本信息',
            subtitle: '完善身份信息以匹配正确批次',
            trailing: FilledButton.tonal(onPressed: () {}, child: const Text('确认信息')),
            child: const _InfoGrid(
              items: [
                _InfoItem(label: '所在省份', value: '浙江省'),
                _InfoItem(label: '毕业高中', value: '杭州市第二中学'),
                _InfoItem(label: '年级', value: '高三（2026届）'),
                _InfoItem(label: '身份', value: '学生'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '成绩信息',
            subtitle: '同步最新模考成绩',
            trailing: FilledButton.tonal(onPressed: () {}, child: const Text('确认成绩')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _InfoGrid(
                  items: [
                    _InfoItem(label: '总分 / 综合分', value: '628'),
                    _InfoItem(label: '全省位次', value: '12,430'),
                    _InfoItem(label: '语文', value: '122'),
                    _InfoItem(label: '数学', value: '138'),
                    _InfoItem(label: '英语', value: '136'),
                    _InfoItem(label: '选考总分', value: '260'),
                  ],
                ),
                SizedBox(height: 16),
                Text('当前考试：二模 · 考生成绩已同步到平台。'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '选科信息',
            subtitle: '匹配不同省级招生政策',
            trailing: FilledButton.tonal(onPressed: () {}, child: const Text('确认选科')),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                TagChip(label: '物理'),
                TagChip(label: '化学'),
                TagChip(label: '政治'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '志愿偏好',
            subtitle: '指导冲稳保比例与偏好匹配',
            trailing: FilledButton.tonal(onPressed: () {}, child: const Text('确认偏好')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    TagChip(label: '地区：长三角'),
                    TagChip(label: '层次：985 优先'),
                    TagChip(label: '专业：教育学'),
                    TagChip(label: '冲/稳/保：2 · 5 · 3'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '喜欢充满人文氛围的城市，宿舍条件较为重要。',
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

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: items.map((item) {
        return Container(
          width: double.infinity, // 占据全宽
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label, 
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.value, 
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;
}
