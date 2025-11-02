import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';

class CollegePage extends StatelessWidget {
  const CollegePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: '院校筛选',
            subtitle: '快速定位目标院校',
            child: Column(
              children: [
                Row(
                  children: const [
                    Expanded(child: _DropdownField(label: '省份', value: '浙江省')),
                    SizedBox(width: 12),
                    Expanded(child: _DropdownField(label: '院校类型', value: '师范类')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: _DropdownField(label: '院校层次', value: '985 优先')),
                    SizedBox(width: 12),
                    Expanded(child: _TextField(label: '关键字搜索', hint: '输入院校名称')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {},
                        child: const Text('立即筛选'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('重置条件'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '院校列表',
            subtitle: '共 2,146 所院校',
            child: Column(
              children: [
                for (final school in _schools)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        title: Text(school.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text('${school.province} · ${school.category}'),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TagChip(label: school.tierLabel),
                            const SizedBox(height: 8),
                            Text('计划 ${school.quota} 人', style: theme.textTheme.labelSmall),
                          ],
                        ),
                        onTap: () {},
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '我的对比列表',
            subtitle: '2 组对比草案',
            child: Row(
              children: [
                Expanded(
                  child: _CompareCard(
                    title: '师范类院校',
                    subtitle: '华东师范大学 vs. 南京师范大学',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CompareCard(
                    title: '综合类院校',
                    subtitle: '浙江大学 vs. 上海交通大学',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E7FF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.label, required this.hint});

  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4B5769))),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton.tonal(onPressed: onTap, child: const Text('查看详情')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolItem {
  const _SchoolItem({
    required this.name,
    required this.province,
    required this.category,
    required this.tierLabel,
    required this.quota,
  });

  final String name;
  final String province;
  final String category;
  final String tierLabel;
  final int quota;
}

const _schools = <_SchoolItem>[
  _SchoolItem(name: '华东师范大学', province: '上海', category: '师范类', tierLabel: '985', quota: 320),
  _SchoolItem(name: '浙江大学', province: '浙江', category: '综合类', tierLabel: '985', quota: 520),
  _SchoolItem(name: '南京大学', province: '江苏', category: '综合类', tierLabel: '985', quota: 480),
  _SchoolItem(name: '北京理工大学', province: '北京', category: '工科', tierLabel: '985', quota: 430),
  _SchoolItem(name: '复旦大学', province: '上海', category: '综合类', tierLabel: '985', quota: 380),
  _SchoolItem(name: '上海交通大学', province: '上海', category: '综合类', tierLabel: '985', quota: 450),
];
