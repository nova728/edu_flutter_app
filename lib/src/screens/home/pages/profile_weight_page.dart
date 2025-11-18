import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'dart:convert';

class ProfileWeightPage extends StatefulWidget {
  const ProfileWeightPage({super.key});

  @override
  State<ProfileWeightPage> createState() => _ProfileWeightPageState();
}

class _ProfileWeightPageState extends State<ProfileWeightPage> {
  double _regionWeight = 0.4;
  double _tierWeight = 0.35;
  double _majorWeight = 0.25;
  bool _initialized = false;
  late String _userId;
  bool _autoBalance = false;

  double? _candRegion, _candTier, _candMajor;

  double _round01(double x) => (x.clamp(0.1, 0.7) * 100).round() / 100.0;

  void _fixToHundred() {
    final sum = _regionWeight + _tierWeight + _majorWeight;
    final delta = 1.0 - sum;
    if (delta.abs() < 0.0001) return;
    // 调整可用空间最大的项
    final canInc = [
      ('region', 0.7 - _regionWeight),
      ('tier', 0.7 - _tierWeight),
      ('major', 0.7 - _majorWeight),
    ];
    final canDec = [
      ('region', _regionWeight - 0.1),
      ('tier', _tierWeight - 0.1),
      ('major', _majorWeight - 0.1),
    ];
    setState(() {
      if (delta > 0) {
        canInc.sort((a, b) => b.$2.compareTo(a.$2));
        switch (canInc.first.$1) {
          case 'region':
            _regionWeight = _round01(_regionWeight + delta);
            break;
          case 'tier':
            _tierWeight = _round01(_tierWeight + delta);
            break;
          default:
            _majorWeight = _round01(_majorWeight + delta);
        }
      } else {
        canDec.sort((a, b) => b.$2.compareTo(a.$2));
        switch (canDec.first.$1) {
          case 'region':
            _regionWeight = _round01(_regionWeight + delta);
            break;
          case 'tier':
            _tierWeight = _round01(_tierWeight + delta);
            break;
          default:
            _majorWeight = _round01(_majorWeight + delta);
        }
      }
    });
  }

  Map<String, double> _computeCandidate() {
    double a = _regionWeight, b = _tierWeight, c = _majorWeight;
    String changed = (a >= b && a >= c)
        ? 'region'
        : (b >= a && b >= c)
            ? 'tier'
            : 'major';
    double v = changed == 'region'
        ? a
        : changed == 'tier'
            ? b
            : c;
    double o1, o2;
    if (changed == 'region') {
      o1 = b;
      o2 = c;
    } else if (changed == 'tier') {
      o1 = a;
      o2 = c;
    } else {
      o1 = a;
      o2 = b;
    }
    double sum = o1 + o2;
    double r1 = sum > 0 ? o1 / sum : 0.5;
    double r2 = 1 - r1;
    double n1 = (1 - v) * r1;
    double n2 = (1 - v) * r2;
    n1 = n1.clamp(0.1, 0.7);
    n2 = n2.clamp(0.1, 0.7);
    v = (1 - (n1 + n2)).clamp(0.1, 0.7);
    if (changed == 'region') {
      return {'region': v, 'tier': n1, 'major': n2};
    } else if (changed == 'tier') {
      return {'region': n1, 'tier': v, 'major': n2};
    } else {
      return {'region': n1, 'tier': n2, 'major': v};
    }
  }

  void _normalizeWeights(String changed, double value) {
    double v = value.clamp(0.1, 0.7);
    double a = _regionWeight, b = _tierWeight, c = _majorWeight;
    if (changed == 'region') {
      a = v;
      double o1 = b, o2 = c;
      double sum = o1 + o2;
      double r1 = sum > 0 ? o1 / sum : 0.5;
      double r2 = 1 - r1;
      double n1 = (1 - a) * r1;
      double n2 = (1 - a) * r2;
      n1 = n1.clamp(0.1, 0.7);
      n2 = n2.clamp(0.1, 0.7);
      a = (1 - (n1 + n2)).clamp(0.1, 0.7);
      setState(() {
        _regionWeight = a;
        _tierWeight = n1;
        _majorWeight = n2;
      });
    } else if (changed == 'tier') {
      b = v;
      double o1 = a, o2 = c;
      double sum = o1 + o2;
      double r1 = sum > 0 ? o1 / sum : 0.5;
      double r2 = 1 - r1;
      double n1 = (1 - b) * r1;
      double n2 = (1 - b) * r2;
      n1 = n1.clamp(0.1, 0.7);
      n2 = n2.clamp(0.1, 0.7);
      b = (1 - (n1 + n2)).clamp(0.1, 0.7);
      setState(() {
        _regionWeight = n1;
        _tierWeight = b;
        _majorWeight = n2;
      });
    } else {
      c = v;
      double o1 = a, o2 = b;
      double sum = o1 + o2;
      double r1 = sum > 0 ? o1 / sum : 0.5;
      double r2 = 1 - r1;
      double n1 = (1 - c) * r1;
      double n2 = (1 - c) * r2;
      n1 = n1.clamp(0.1, 0.7);
      n2 = n2.clamp(0.1, 0.7);
      c = (1 - (n1 + n2)).clamp(0.1, 0.7);
      setState(() {
        _regionWeight = n1;
        _tierWeight = n2;
        _majorWeight = c;
      });
    }
  }

  Future<void> _loadWeights() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('weights_$_userId');
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _regionWeight = (map['region'] as num?)?.toDouble() ?? _regionWeight;
        _tierWeight = (map['tier'] as num?)?.toDouble() ?? _tierWeight;
        _majorWeight = (map['major'] as num?)?.toDouble() ?? _majorWeight;
      });
    } catch (_) {}
  }

  Future<void> _saveWeights() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'region': _regionWeight,
      'tier': _tierWeight,
      'major': _majorWeight,
    };
    await prefs.setString('weights_$_userId', jsonEncode(payload));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_initialized) {
      final scope = AuthScope.of(context);
      _userId = scope.session.user.userId;
      _initialized = true;
      _loadWeights();
    }

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
            onPressed: () async {
              setState(() {
                _regionWeight = 0.4;
                _tierWeight = 0.35;
                _majorWeight = 0.25;
              });
              await _saveWeights();
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('自动平衡'),
                      Switch(
                        value: _autoBalance,
                        onChanged: (v) {
                          setState(() {
                            _autoBalance = v;
                            if (v) {
                              final cand = _computeCandidate();
                              _candRegion = cand['region'];
                              _candTier = cand['tier'];
                              _candMajor = cand['major'];
                            } else {
                              _candRegion = _candTier = _candMajor = null;
                            }
                          });
                        },
                      ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('总计: ${((_regionWeight + _tierWeight + _majorWeight) * 100).round()}%'),
                      OutlinedButton(onPressed: _fixToHundred, child: const Text('补齐为100%')),
                    ],
                  ),
                    ],
                  ),
                  _WeightSlider(
                    icon: Icons.place_rounded,
                    label: '目标地区',
                    value: _regionWeight,
                    color: const Color(0xFF2C5BF0),
                    onChanged: (value) => _autoBalance
                        ? _normalizeWeights('region', value)
                        : setState(() => _regionWeight = _round01(value)),
                  ),
                  if (_autoBalance && _candRegion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '候选: 地区 ${((_candRegion! * 100).round())}% · 层次 ${((_candTier! * 100).round())}% · 专业 ${( (_candMajor! * 100).round())}%',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7C8698)),
                      ),
                    ),
                  if (_autoBalance && _candRegion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _regionWeight = _round01(_candRegion!);
                              _tierWeight = _round01(_candTier!);
                              _majorWeight = _round01(_candMajor!);
                            });
                          },
                          child: const Text('应用候选'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _WeightSlider(
                    icon: Icons.school_rounded,
                    label: '院校层次',
                    value: _tierWeight,
                    color: const Color(0xFFFF9500),
                    onChanged: (value) => _autoBalance
                        ? _normalizeWeights('tier', value)
                        : setState(() => _tierWeight = _round01(value)),
                  ),
                  const SizedBox(height: 24),
                  _WeightSlider(
                    icon: Icons.library_books_rounded,
                    label: '专业方向',
                    value: _majorWeight,
                    color: const Color(0xFF21B573),
                    onChanged: (value) => _autoBalance
                        ? _normalizeWeights('major', value)
                        : setState(() => _majorWeight = _round01(value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (!_initialized) {
                    final scope = AuthScope.of(context);
                    _userId = scope.session.user.userId;
                    _initialized = true;
                  }
                  final sum = _regionWeight + _tierWeight + _majorWeight;
                  if (!_autoBalance && (sum - 1.0).abs() > 0.001) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('权重之和必须为100%')),
                    );
                    return;
                  }
                  await _saveWeights();
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
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
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
                  )
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
            divisions: 60,
          ),
        ),
      ],
    );
  }
}