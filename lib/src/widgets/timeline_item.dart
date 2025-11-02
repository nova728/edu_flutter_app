import 'package:flutter/material.dart';

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    required this.timestamp,
    required this.content,
    this.variant = TimelineVariant.neutral,
    super.key,
  });

  final String timestamp;
  final String content;
  final TimelineVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _variantPalette(variant);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4, right: 12),
          decoration: BoxDecoration(
            color: palette.dotColor,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timestamp,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.timestampColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(color: palette.textColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelinePalette {
  const _TimelinePalette({
    required this.background,
    required this.dotColor,
    required this.timestampColor,
    required this.textColor,
  });

  final Color background;
  final Color dotColor;
  final Color timestampColor;
  final Color textColor;
}

_TimelinePalette _variantPalette(TimelineVariant variant) {
  switch (variant) {
    case TimelineVariant.positive:
      return const _TimelinePalette(
        background: Color(0x1421B573),
        dotColor: Color(0xFF21B573),
        timestampColor: Color(0xFF19935A),
        textColor: Color(0xFF234333),
      );
    case TimelineVariant.warning:
      return const _TimelinePalette(
        background: Color(0x14FF9F43),
        dotColor: Color(0xFFFF9F43),
        timestampColor: Color(0xFFD27825),
        textColor: Color(0xFF473224),
      );
    case TimelineVariant.danger:
      return const _TimelinePalette(
        background: Color(0x14F04F52),
        dotColor: Color(0xFFF04F52),
        timestampColor: Color(0xFFBA3337),
        textColor: Color(0xFF462424),
      );
    case TimelineVariant.neutral:
      return const _TimelinePalette(
        background: Color(0x142C5BF0),
        dotColor: Color(0xFF2C5BF0),
        timestampColor: Color(0xFF2147B8),
        textColor: Color(0xFF233252),
      );
  }
}

enum TimelineVariant { neutral, positive, warning, danger }
