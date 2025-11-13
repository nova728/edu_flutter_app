import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';

class ProfileWeightPage extends StatefulWidget {
  const ProfileWeightPage({super.key});

  @override
  State<ProfileWeightPage> createState() => _ProfileWeightPageState();
}

class _ProfileWeightPageState extends State<ProfileWeightPage> {
  double _regionWeight = 0.4;
  double _tierWeight = 0.35;
  double _majorWeight = 0.25;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('偏好权重'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _regionWeight = 0.4;
                _tierWeight = 0.35;
                _majorWeight = 0.25;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已重置为默认权重')),
              );
            },
            child: const Text('重置'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0x1400B8D4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF00B8D4)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '权重配置影响推荐算法的计算结果，数值越大表示该因素越重要。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF234052),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: '权重配置',
              subtitle: '调整推荐因子权重',
              child: Column(
                children: [
                  _WeightSlider(
                    icon: Icons.place_rounded,
                    label: '目标地区',
                    description: '长三角（上海 / 杭州）',
                    value: _regionWeight,
                    color: const Color(0xFF2C5BF0),
                    onChanged: (value) => setState(() => _regionWeight = value),
                  ),
                  const SizedBox(height: 24),
                  _WeightSlider(
                    icon: Icons.school_rounded,
                    label: '院校层次',
                    description: '985 优先，兼顾双一流',
                    value: _tierWeight,
                    color: const Color(0xFFFF9500),
                    onChanged: (value) => setState(() => _tierWeight = value),
                  ),
                  const SizedBox(height: 24),
                  _WeightSlider(
                    icon: Icons.library_books_rounded,
                    label: '专业方向',
                    description: '教育学 / 人文社科',
                    value: _majorWeight,
                    color: const Color(0xFF21B573),
                    onChanged: (value) => setState(() => _majorWeight = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('权重保存成功')),
                  );
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('保存配置'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String description;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7C8698),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0.1,
            max: 0.7,
          ),
        ),
      ],
    );
  }
}
