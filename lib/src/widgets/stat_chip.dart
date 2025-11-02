import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  const StatChip({
    required this.label,
    required this.value,
    this.meta,
    this.variant = StatChipVariant.primary,
    super.key,
  });

  final String label;
  final String value;
  final String? meta;
  final StatChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _variantColors(variant);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.muted,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          if (meta != null) ...[
            const SizedBox(height: 4),
            Text(
              meta!,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipPalette {
  const _ChipPalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.muted,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final Color muted;
}

_ChipPalette _variantColors(StatChipVariant variant) {
  switch (variant) {
    case StatChipVariant.primary:
      return const _ChipPalette(
        background: Color(0x142C5BF0),
        border: Color(0x1A2C5BF0),
        foreground: Color(0xFF2C5BF0),
        muted: Color(0xFF7C8698),
      );
    case StatChipVariant.success:
      return const _ChipPalette(
        background: Color(0x1421B573),
        border: Color(0x1A21B573),
        foreground: Color(0xFF1F8A5C),
        muted: Color(0xFF5BA882),
      );
    case StatChipVariant.warning:
      return const _ChipPalette(
        background: Color(0x14FF9F43),
        border: Color(0x1AFF9F43),
        foreground: Color(0xFFD67622),
        muted: Color(0xFFBA8551),
      );
    case StatChipVariant.danger:
      return const _ChipPalette(
        background: Color(0x14F04F52),
        border: Color(0x1AF04F52),
        foreground: Color(0xFFCB3C40),
        muted: Color(0xFFB06D6F),
      );
  }
}

enum StatChipVariant { primary, success, warning, danger }
