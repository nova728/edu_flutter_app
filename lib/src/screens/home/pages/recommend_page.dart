import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'package:zygc_flutter_prototype/src/services/api_client.dart';
import 'dart:convert';
import 'dart:async';
import 'favorite_colleges_page.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key, required this.onViewCollege});

  final ValueChanged<String>? onViewCollege;

  @override
  State<RecommendPage> createState() => RecommendPageState();
}

class RecommendPageState extends State<RecommendPage> with SingleTickerProviderStateMixin {
  // 权重设置
  double _regionWeight = 0.4;
  double _tierWeight = 0.35;
  double _majorWeight = 0.25;
  bool _autoBalance = false;
  double? _candRegion, _candTier, _candMajor;
  double? _sumPreview;

  Map<String, double> _computeCandidate() {
    double a = _regionWeight, b = _tierWeight, c = _majorWeight;
    String changed = (a >= b && a >= c)
        ? 'region'
        : (b >= a && b >= c)
            ? 'tier'
            : 'major';
    double v = changed == 'region' ? a : changed == 'tier' ? b : c;
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
    double a = _regionWeight, b = _tierWeight, c = _majorWeight;
    double v = value.clamp(0.1, 0.7);
    double o1, o2;
    if (changed == 'region') { o1 = b; o2 = c; }
    else if (changed == 'tier') { o1 = a; o2 = c; }
    else { o1 = a; o2 = b; }
    double sum = o1 + o2;
    double r1 = sum > 0 ? o1 / sum : 0.5;
    double r2 = 1 - r1;
    double n1 = (1 - v) * r1;
    double n2 = (1 - v) * r2;
    n1 = n1.clamp(0.1, 0.7);
    n2 = n2.clamp(0.1, 0.7);
    v = (1 - (n1 + n2)).clamp(0.1, 0.7);
    setState(() {
      if (changed == 'region') { _regionWeight = _round01(v); _tierWeight = _round01(n1); _majorWeight = _round01(n2); }
      else if (changed == 'tier') { _regionWeight = _round01(n1); _tierWeight = _round01(v); _majorWeight = _round01(n2); }
      else { _regionWeight = _round01(n1); _tierWeight = _round01(n2); _majorWeight = _round01(v); }
      _candRegion = _candTier = _candMajor = null;
      _sumPreview = null;
    });
  }

  void _previewCandidate(String changed, double value) {
    double a = _regionWeight, b = _tierWeight, c = _majorWeight;
    double v = value.clamp(0.1, 0.7);
    double o1, o2;
    if (changed == 'region') { o1 = b; o2 = c; }
    else if (changed == 'tier') { o1 = a; o2 = c; }
    else { o1 = a; o2 = b; }
    double sum = o1 + o2;
    double r1 = sum > 0 ? o1 / sum : 0.5;
    double r2 = 1 - r1;
    double n1 = (1 - v) * r1;
    double n2 = (1 - v) * r2;
    n1 = n1.clamp(0.1, 0.7);
    n2 = n2.clamp(0.1, 0.7);
    v = (1 - (n1 + n2)).clamp(0.1, 0.7);
    setState(() {
      if (changed == 'region') { _candRegion = v; _candTier = n1; _candMajor = n2; }
      else if (changed == 'tier') { _candRegion = n1; _candTier = v; _candMajor = n2; }
      else { _candRegion = n1; _candTier = n2; _candMajor = v; }
    });
  }

  void _previewSum(String changed, double value) {
    double a = _regionWeight, b = _tierWeight, c = _majorWeight;
    double v = value.clamp(0.1, 0.7);
    if (changed == 'region') a = v; else if (changed == 'tier') b = v; else c = v;
    setState(() { _sumPreview = a + b + c; });
  }
  
  // 筛选和排序
  final Set<String> _filters = <String>{'全部'};
  String _sortBy = '匹配度'; // 匹配度、录取概率、院校层次
  final ApiClient _client = ApiClient();
  final List<Map<String, dynamic>> _recommendations = [];
  final List<Map<String, dynamic>> _previewRecommendations = [];
  final TextEditingController _prefMajorController = TextEditingController();
  final Set<String> _prefRegions = {};
  bool _pref985 = false, _pref211 = false, _prefDFC = false;
  bool _applyMajorPrefForBackend = false;
  static const List<String> _allProvinces = [
    '北京市','天津市','河北省','山西省','内蒙古自治区','辽宁省','吉林省','黑龙江省','上海市','江苏省',
    '浙江省','安徽省','福建省','江西省','山东省','河南省','湖北省','湖南省','广东省','广西壮族自治区',
    '海南省','重庆市','四川省','贵州省','云南省','西藏自治区','陕西省','甘肃省','青海省','宁夏回族自治区',
    '新疆维吾尔自治区','香港特别行政区','澳门特别行政区','台湾省'
  ];
  
  // 收藏和草案
  final Set<String> _favoriteColleges = {};
  bool _initialized = false;
  late String _userId;

  final Set<String> _draftColleges = {};
  
  // 状态管理
  bool _isLoading = false;
  bool _isAdjustingWeights = false;
  
  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _prefMajorController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final scope = AuthScope.of(context);
      _userId = scope.session.user.userId;
      _loadInitialData();
      _loadSavedPlan();
    }
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawFav = prefs.getString('favorites_$_userId');
    Set<String> favs = _favoriteColleges;
    if (rawFav != null && rawFav.isNotEmpty) {
      try {
        final list = (jsonDecode(rawFav) as List).cast<Map<String, dynamic>>();
        favs = list
            .map((e) => e['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet();
      } catch (_) {}
    }
    final rawWeights = prefs.getString('weights_$_userId');
    double a = _regionWeight, b = _tierWeight, c = _majorWeight;
    if (rawWeights != null && rawWeights.isNotEmpty) {
      try {
        final map = jsonDecode(rawWeights) as Map<String, dynamic>;
        a = (map['region'] as num?)?.toDouble() ?? a;
        b = (map['tier'] as num?)?.toDouble() ?? b;
        c = (map['major'] as num?)?.toDouble() ?? c;
      } catch (_) {}
    }
    final pm = prefs.getString('pref_major_$_userId') ?? '';
    final pr = prefs.getString('pref_regions_$_userId') ?? '';
    final pl = prefs.getString('pref_levels_$_userId');
    bool lv985 = _pref985, lv211 = _pref211, lvDFC = _prefDFC;
    if (pl != null && pl.isNotEmpty) {
      try {
        final m = jsonDecode(pl) as Map<String, dynamic>;
        lv985 = (m['is985'] == true) || (m['is985']?.toString() == '1');
        lv211 = (m['is211'] == true) || (m['is211']?.toString() == '1');
        lvDFC = (m['isDFC'] == true) || (m['isDFC']?.toString() == '1');
      } catch (_) {}
    }
    final regionSet = pr.isNotEmpty ? pr.split(',').where((e) => e.trim().isNotEmpty).map((e) => e.trim()).toSet() : <String>{};
    if (mounted) {
      setState(() {
        _favoriteColleges
          ..clear()
          ..addAll(favs);
        _regionWeight = a;
        _tierWeight = b;
        _majorWeight = c;
        _prefMajorController.text = pm;
        _prefRegions
          ..clear()
          ..addAll(regionSet);
        _pref985 = lv985;
        _pref211 = lv211;
        _prefDFC = lvDFC;
        _initialized = true;
      });
    }
  }

  /// 切换筛选标签
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

  /// 显示提示消息
  void _showToast(String message, {Color? backgroundColor}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.green 
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF2C5BF0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// 显示院校详情弹窗（真实数据）
  Future<void> _showCollegeDetail(String collegeName, String collegeCode) async {
    final scope = AuthScope.of(context);
    final client = ApiClient();
    final token = scope.session.token;
    Map<String, dynamic> data = {};
    try {
      final resp = await client.get('/colleges/$collegeCode');
      data = (resp['data'] as Map<String, dynamic>?) ?? {};
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3D9E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['COLLEGE_NAME']?.toString() ?? collegeName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1F2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '院校代码：${data['COLLEGE_CODE']?.toString() ?? collegeCode}',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF7C8698)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFF5F7FB)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    _DetailSection(
                      title: '院校概况',
                      icon: Icons.school_outlined,
                      children: [
                        _DetailItem(label: '所在省份', value: (data['PROVINCE'] ?? '-').toString()),
                        _DetailItem(label: '所在城市', value: (data['CITY_NAME'] ?? '-').toString()),
                        _DetailItem(label: '院校类型', value: (data['COLLEGE_TYPE'] ?? '-').toString()),
                        _DetailItem(
                          label: '院校标签',
                          value: [
                            if ((data['IS_985']?.toString() ?? '') == '1' || (data['IS_985'] == true)) '985',
                            if ((data['IS_211']?.toString() ?? '') == '1' || (data['IS_211'] == true)) '211',
                            if ((data['IS_DFC']?.toString() ?? data['IS_DOUBLE_FIRST_CLASS']?.toString() ?? '') == '1') '双一流',
                          ].join(' · '),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (widget.onViewCollege != null) {
                            widget.onViewCollege!(collegeCode);
                          }
                        },
                        icon: const Icon(Icons.launch, size: 18),
                        label: const Text('完整信息'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 切换收藏状态
  Future<void> _saveFavoriteItem(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favorites_$_userId';
    final raw = prefs.getString(key);
    final list = raw == null || raw.isEmpty ? <dynamic>[] : (jsonDecode(raw) as List);
    if (!list.any((e) => (e['name'] ?? '') == name)) {
      final source = _previewRecommendations.isNotEmpty ? _previewRecommendations : _recommendations;
      final rec = source.firstWhere(
        (e) => (e['COLLEGE_NAME']?.toString() ?? '') == name,
        orElse: () => <String, dynamic>{},
      );
      final tags = <String>[];
      if ((rec['IS_985']?.toString() ?? '0') == '1') tags.add('985');
      if ((rec['IS_211']?.toString() ?? '0') == '1') tags.add('211');
      if ((rec['IS_DFC']?.toString() ?? '0') == '1') tags.add('双一流');
      final admissions = (rec['admissions'] as List?)?.map((a) => {
        'year': a['year'],
        'minScore': a['minScore'],
        'minRank': a['minRank'],
      }).toList();
      list.insert(0, {
        'name': name,
        'code': rec['COLLEGE_CODE']?.toString() ?? '',
        'location': rec['PROVINCE']?.toString() ?? '',
        'probability': (rec['probability'] as num?)?.toDouble(),
        'matchScore': (rec['matchScore'] as num?)?.toDouble(),
        'category': rec['category']?.toString(),
        'tags': tags,
        'admissions': admissions ?? [],
        'addedDate': DateTime.now().toString(),
        'notes': '',
      });
      await prefs.setString(key, jsonEncode(list));
    }
  }

  Future<void> _removeFavoriteItem(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'favorites_$_userId';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;
    final list = (jsonDecode(raw) as List).where((e) => (e['name'] ?? '') != name).toList();
    await prefs.setString(key, jsonEncode(list));
  }

  void _toggleFavorite(String collegeName) {
    setState(() {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      if (_favoriteColleges.contains(collegeName)) {
        _favoriteColleges.remove(collegeName);
        _removeFavoriteItem(collegeName);
        messenger.showSnackBar(
          SnackBar(
            content: Text('已取消收藏 $collegeName'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _favoriteColleges.add(collegeName);
        _saveFavoriteItem(collegeName);
        messenger.showSnackBar(
          SnackBar(
            content: Text('已收藏 $collegeName'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '查看',
              onPressed: () {
                messenger.hideCurrentSnackBar();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoriteCollegesPage()),
                );
              },
            ),
          ),
        );
      }
    });
  }

  /// 加入草案
  void _addToDraft(String collegeName) {
    setState(() {
      if (_draftColleges.contains(collegeName)) {
        _showToast('$collegeName 已在草案中');
      } else {
        _draftColleges.add(collegeName);
        _showToast('已加入草案', backgroundColor: Colors.green);
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_major_$_userId', _prefMajorController.text.trim());
    await prefs.setString('pref_regions_$_userId', _prefRegions.join(','));
    await prefs.setString('pref_levels_$_userId', jsonEncode({
      'is985': _pref985,
      'is211': _pref211,
      'isDFC': _prefDFC,
    }));
  }

  void _togglePrefRegion(String region) {
    setState(() {
      if (_prefRegions.contains(region)) {
        _prefRegions.remove(region);
      } else {
        _prefRegions.add(region);
      }
    });
  }

  Future<void> _showProvincePicker() async {
    final initial = Set<String>.from(_prefRegions);
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selections = Set<String>.from(initial);
            void toggle(String province) {
              setModalState(() {
                if (initial.contains(province)) {
                  initial.remove(province);
                } else {
                  initial.add(province);
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD3D9E5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '选择偏好省份',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (initial.isNotEmpty)
                              TextButton(
                                onPressed: () => setModalState(() => initial.clear()),
                                child: const Text('清空'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _allProvinces.length,
                          itemBuilder: (context, index) {
                            final province = _allProvinces[index];
                            return CheckboxListTile(
                              value: initial.contains(province),
                              title: Text(province),
                              dense: true,
                              onChanged: (_) => toggle(province),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(initial),
                          child: Text(initial.isEmpty ? '不设置省份' : '确定 (${initial.length})'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null && mounted) {
      setState(() {
        _prefRegions
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _loadRecommendations() async {
    final query = <String, String>{
      'objectiveWeight': '0.8',
    };
    final sum = _regionWeight + _tierWeight + _majorWeight;
    if (sum > 0) {
      query['sw_region'] = (_regionWeight / sum).toStringAsFixed(4);
      query['sw_level'] = (_tierWeight / sum).toStringAsFixed(4);
      query['sw_major'] = (_majorWeight / sum).toStringAsFixed(4);
    }
    if (_pref985) query['is985'] = '1';
    if (_pref211) query['is211'] = '1';
    if (_prefDFC) query['isDFC'] = '1';
    if (_prefRegions.isNotEmpty) {
      query['regions'] = _prefRegions.join(',');
    }
    final majorPattern = _prefMajorController.text.trim();
    if (_applyMajorPrefForBackend && majorPattern.isNotEmpty) query['majorPattern'] = majorPattern;
    final scope = AuthScope.of(context);
    final prov = scope.session.user.province;
    if (prov != null && prov.isNotEmpty) {
      final normProv = _normalizeProvince(prov);
      if (normProv.isNotEmpty) query['province'] = normProv;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('scores_$_userId');
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = (jsonDecode(raw) as List).cast<dynamic>();
          debugPrint('recommend local scores count=${list.length} for user=$_userId');
          int? rank;
          for (final e in list) {
            final m = e is Map<String, dynamic> ? e : null;
            if (m == null) continue;
            final keys = m.keys.join(',');
            final mockName = m['MOCK_EXAM_NAME']?.toString() ?? '';
            if (mockName.isNotEmpty) {
              debugPrint('recommend skip mock exam record keys=[$keys] mock=$mockName');
              continue;
            }
            final candidates = [
              m['RANK_IN_PROVINCE'],
              m['rankInProvince'],
              m['rank'],
              m['minRank'],
              m['provinceRank'],
            ];
            int? r;
            for (final c in candidates) {
              r = int.tryParse(c?.toString() ?? '');
              if (r != null && r > 0) break;
            }
            if (r != null && r > 0) {
              rank = r;
              debugPrint('recommend rank (gaokao) found keys=[$keys] value=$r');
              break;
            } else {
              debugPrint('recommend inspecting GAOKAO entry keys=[$keys], no valid rank field');
            }
          }
          if (rank != null) {
            query['rank'] = rank.toString();
            debugPrint('recommend rank extracted: $rank');
          } else {
            debugPrint('recommend rank missing in local scores for user=$_userId');
          }
        } catch (err) {
          debugPrint('recommend rank parse error: $err');
        }
      } else {
        debugPrint('recommend no local scores for user=$_userId');
      }
      debugPrint('recommend query: ' + query.entries.map((e) => '${e.key}=${e.value}').join('&'));
      final resp = await _client.get('/colleges/recommend', query: query);
      final rows = resp['data'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _previewRecommendations
          ..clear()
          ..addAll(rows.cast<Map<String, dynamic>>());
      });
      _showToast('已生成预览，共${rows.length}所', backgroundColor: Colors.green);
    } catch (_) {}
  }

  Future<void> _loadSavedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('recommend_plan_$_userId');
    if (raw == null || raw.isEmpty) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final list = (m['list'] as List?)?.cast<dynamic>() ?? const [];
      final rows = list.map((e) {
        final mm = e as Map<String, dynamic>;
        return {
          'COLLEGE_CODE': mm['code']?.toString() ?? '',
          'COLLEGE_NAME': mm['name']?.toString() ?? '',
          'PROVINCE': mm['province']?.toString() ?? '',
          'probability': (mm['probability'] as num?)?.toDouble() ?? 0.0,
          'matchScore': (mm['matchScore'] as num?)?.toDouble() ?? 0.0,
          'IS_985': mm['IS_985'],
          'IS_211': mm['IS_211'],
          'IS_DFC': mm['IS_DFC'],
          'admissions': (mm['admissions'] as List?)?.map((a) => {
            'year': a['year'],
            'minScore': a['minScore'],
            'minRank': a['minRank'],
          }).toList() ?? [],
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _recommendations
          ..clear()
          ..addAll(rows);
      });
    } catch (_) {}
  }

  Future<void> saveRecommendationPlan() async {
    if (_previewRecommendations.isNotEmpty) {
      setState(() {
        _recommendations
          ..clear()
          ..addAll(_previewRecommendations);
      });
    }
    final prefs = await SharedPreferences.getInstance();
    final key = 'recommend_plan_$_userId';
    final list = _recommendations.map((e) => {
      'code': e['COLLEGE_CODE']?.toString() ?? '',
      'name': e['COLLEGE_NAME']?.toString() ?? '',
      'province': e['PROVINCE']?.toString(),
      'probability': (e['probability'] as num?)?.toDouble(),
      'matchScore': (e['matchScore'] as num?)?.toDouble(),
      'IS_985': e['IS_985'],
      'IS_211': e['IS_211'],
      'IS_DFC': e['IS_DFC'],
      'admissions': (e['admissions'] as List?)?.map((a) => {
        'year': a['year'],
        'minScore': a['minScore'],
        'minRank': a['minRank'],
      }).toList(),
    }).toList();
    await prefs.setString(key, jsonEncode({
      'count': _recommendations.length,
      'list': list,
      'savedAt': DateTime.now().toIso8601String(),
    }));
    _showToast('已保存并应用（${_recommendations.length} 所）', backgroundColor: Colors.green);
  }

  bool _isCategoryChip(String f) => f == '冲刺' || f == '稳妥' || f == '保底' || f == '参考';

  String _categoryFromProb(double p) {
    if (p >= 0.75) return '保';
    if (p >= 0.4) return '稳';
    if (p >= 0.2) return '冲';
    return '参考';
  }

  List<Map<String, dynamic>> _applyDisplayFilters(List<Map<String, dynamic>> list) {
    if (_filters.contains('全部')) return list;

    final cats = _filters.where(_isCategoryChip).toSet();
    final need985 = _filters.contains('985院校');
    final need211 = _filters.contains('211院校');
    final needDFC = _filters.contains('双一流院校');
    final needYangtze = _filters.contains('长三角院校');
    const yangtze = {'上海','江苏','浙江','安徽'};

    return list.where((rec) {
      final p = (rec['probability'] as num?)?.toDouble() ?? 0.0;
      final cat = (rec['category']?.toString().isNotEmpty == true)
          ? rec['category'].toString()
          : _categoryFromProb(p);
      if (cats.isNotEmpty && !((cat == '冲' && cats.contains('冲刺')) || (cat == '稳' && cats.contains('稳妥')) || (cat == '保' && cats.contains('保底')) || (cat == '参考' && cats.contains('参考')))) {
        return false;
      }
      if (need985 && (rec['IS_985']?.toString() ?? '0') != '1') return false;
      if (need211 && (rec['IS_211']?.toString() ?? '0') != '1') return false;
      if (needDFC && (rec['IS_DFC']?.toString() ?? '0') != '1') return false;
      if (needYangtze && !yangtze.contains(rec['PROVINCE']?.toString() ?? '')) return false;
      return true;
    }).toList();
  }

  String _normalizeProvince(String input) {
    var result = input.trim();
    const suffixes = ['特别行政区','维吾尔自治区','壮族自治区','回族自治区','自治区','省','市'];
    for (final s in suffixes) {
      if (result.endsWith(s)) {
        result = result.substring(0, result.length - s.length);
        break;
      }
    }
    return result;
  }

  /// 重置权重
  Future<void> _saveWeights() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'region': _regionWeight,
      'tier': _tierWeight,
      'major': _majorWeight,
    };
    await prefs.setString('weights_$_userId', jsonEncode(payload));
  }

  void _resetWeights() {
    setState(() {
      _regionWeight = 0.4;
      _tierWeight = 0.35;
      _majorWeight = 0.25;
    });
    _saveWeights();
    _showToast('权重已重置');
  }

  /// 应用权重
  double _round01(double x) => (x.clamp(0.1, 0.7) * 100).round() / 100.0;
  void _fixToHundred() {
    final sum = _regionWeight + _tierWeight + _majorWeight;
    final delta = 1.0 - sum;
    if (delta.abs() < 0.0001) return;
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

  void _applyWeights() {
    final sum = _regionWeight + _tierWeight + _majorWeight;
    if (!_autoBalance && (sum - 1.0).abs() > 0.001) {
      _showToast('权重之和必须为100%', backgroundColor: Colors.red);
      return;
    }
    setState(() {
      _isLoading = true;
    });
    _saveWeights();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAdjustingWeights = false;
        });
        _showToast('推荐结果已更新', backgroundColor: Colors.green);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 统计概览卡片
                _StatisticsCard(
                  totalCount: _recommendations.length,
                  favoriteCount: _favoriteColleges.length,
                ),
                const SizedBox(height: 20),

                // 智能推荐方案
                SectionCard(
                  title: '智能推荐方案',
                  subtitle: '基于历史数据与个人偏好的智能匹配',
                  trailing: IconButton(
                    icon: Icon(
                      _isAdjustingWeights 
                          ? Icons.keyboard_arrow_up 
                          : Icons.tune,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isAdjustingWeights = !_isAdjustingWeights;
                      });
                    },
                    tooltip: '调整权重',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 数据说明
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2C5BF0).withOpacity(0.1),
                              const Color(0xFF00B8D4).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2C5BF0).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 18,
                                  color: Color(0xFF2C5BF0),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '推荐算法说明',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C5BF0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const _AlgorithmItem(
                              label: '客观数据',
                              items: ['历年录取分数线 80%'],
                            ),
                            const SizedBox(height: 8),
                            _AlgorithmItem(
                              label: '主观偏好',
                              items: [
                                '目标地区 ${((_regionWeight / (_regionWeight + _tierWeight + _majorWeight)) * 20).round()}%',
                                '院校层次 ${((_tierWeight / (_regionWeight + _tierWeight + _majorWeight)) * 20).round()}%',
                                '专业方向 ${((_majorWeight / (_regionWeight + _tierWeight + _majorWeight)) * 20).round()}%',
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 权重调整区域
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _isAdjustingWeights
                            ? Column(
                                children: [
                                  const SizedBox(height: 20),
                                  const Divider(height: 1),
                                  const SizedBox(height: 20),
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.settings_suggest,
                                        size: 18,
                                        color: Color(0xFF424A59),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '调整偏好权重',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF424A59),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('自动平衡'),
                                      Switch(
                                        value: _autoBalance,
                                        onChanged: (v) {
                                          setState(() {
                                            _autoBalance = v;
                                            _sumPreview = null;
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
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('总计: ${((((_sumPreview ?? (_regionWeight + _tierWeight + _majorWeight)) * 100).round()))}%'),
                                      OutlinedButton(onPressed: _fixToHundred, child: const Text('补齐为100%')),
                                    ],
                                  ),
                                  if (_autoBalance && _candRegion != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '候选: 地区 ${((_candRegion! * 100).round())}% · 层次 ${((_candTier! * 100).round())}% · 专业 ${( (_candMajor! * 100).round())}%',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF7C8698)),
                                    ),
                                    const SizedBox(height: 8),
                                    const SizedBox.shrink(),
                                  ],
                                  _PreferenceSlider(
                                    label: '目标地区',
                                    icon: Icons.location_on_outlined,
                                    value: _regionWeight,
                                    onPreview: (v) => _autoBalance ? _previewCandidate('region', v) : _previewSum('region', v),
                                    onChanged: (value) {
                                      if (_autoBalance) {
                                        _normalizeWeights('region', value);
                                      } else {
                                        setState(() {
                                          _regionWeight = _round01(value);
                                          _sumPreview = null;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _PreferenceSlider(
                                    label: '院校层次',
                                    icon: Icons.school_outlined,
                                    value: _tierWeight,
                                    onPreview: (v) => _autoBalance ? _previewCandidate('tier', v) : _previewSum('tier', v),
                                    onChanged: (value) {
                                      if (_autoBalance) {
                                        _normalizeWeights('tier', value);
                                      } else {
                                        setState(() {
                                          _tierWeight = _round01(value);
                                          _sumPreview = null;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _PreferenceSlider(
                                    label: '专业方向',
                                    icon: Icons.work_outline,
                                    value: _majorWeight,
                                    onPreview: (v) => _autoBalance ? _previewCandidate('major', v) : _previewSum('major', v),
                                    onChanged: (value) {
                                      if (_autoBalance) {
                                        _normalizeWeights('major', value);
                                      } else {
                                        setState(() {
                                          _majorWeight = _round01(value);
                                          _sumPreview = null;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _resetWeights,
                                          icon: const Icon(Icons.refresh, size: 18),
                                          label: const Text('重置'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: FilledButton.icon(
                                          onPressed: _isLoading ? null : _applyWeights,
                                          icon: _isLoading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.check, size: 18),
                                          label: Text(_isLoading ? '应用中...' : '应用权重'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF2C5BF0),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SectionCard(
                  title: '偏好设置',
                  subtitle: '地区/层次/专业偏好将参与主观20%匹配',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showProvincePicker,
                              icon: const Icon(Icons.public_rounded),
                              label: const Text('选择偏好省份'),
                            ),
                          ),
                          if (_prefRegions.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: () => setState(() => _prefRegions.clear()),
                              icon: const Icon(Icons.clear_rounded),
                              tooltip: '清空省份',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      _prefRegions.isEmpty
                          ? const Text(
                              '暂未选择省份，默认全国范围参与匹配。',
                              style: TextStyle(color: Color(0xFF7C8698)),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _prefRegions.map((province) {
                                return InputChip(
                                  label: Text(province),
                                  onDeleted: () => _togglePrefRegion(province),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final tileWidth = constraints.maxWidth > 520
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: tileWidth,
                                child: SwitchListTile.adaptive(
                                  value: _pref985,
                                  onChanged: (v) => setState(() => _pref985 = v),
                                  title: const Text('偏好 985'),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  tileColor: const Color(0xFFF5F7FB),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              SizedBox(
                                width: tileWidth,
                                child: SwitchListTile.adaptive(
                                  value: _pref211,
                                  onChanged: (v) => setState(() => _pref211 = v),
                                  title: const Text('偏好 211'),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  tileColor: const Color(0xFFF5F7FB),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              SizedBox(
                                width: tileWidth,
                                child: SwitchListTile.adaptive(
                                  value: _prefDFC,
                                  onChanged: (v) => setState(() => _prefDFC = v),
                                  title: const Text('偏好 双一流'),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  tileColor: const Color(0xFFF5F7FB),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _prefMajorController,
                        decoration: InputDecoration(
                          labelText: '专业关键词',
                          hintText: '例如 计算机（用于模糊匹配）',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await _savePreferences();
                                _showToast('偏好已保存');
                              },
                              child: const Text('保存偏好'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async { await _savePreferences(); setState(() => _applyMajorPrefForBackend = true); await _loadRecommendations(); setState(() => _applyMajorPrefForBackend = false); },
                              child: const Text('保存并应用'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 筛选和排序栏
                Row(
                  children: [
                    const Text(
                      '推荐院校',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1F2E),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      initialValue: _sortBy,
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                        });
                        _showToast('已按 $value 排序');
                      },
                      icon: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sort, size: 18),
                          SizedBox(width: 4),
                          Text(
                            '排序',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: '匹配度',
                          child: Text('匹配度'),
                        ),
                        const PopupMenuItem(
                          value: '录取概率',
                          child: Text('录取概率'),
                        ),
                        const PopupMenuItem(
                          value: '院校层次',
                          child: Text('院校层次'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 筛选标签
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in const [
                        '全部',
                        '冲刺',
                        '稳妥',
                        '保底',
                        '参考',
                        '985院校',
                        '211院校',
                        '双一流院校',
                        '长三角院校'
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChip(
                            label: Text(filter),
                            selected: _filters.contains(filter),
                            onSelected: (_) => _toggleFilter(filter),
                            selectedColor: const Color(0xFF2C5BF0).withOpacity(0.15),
                            checkmarkColor: const Color(0xFF2C5BF0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: _filters.contains(filter)
                                    ? const Color(0xFF2C5BF0)
                                    : const Color(0xFFD3D9E5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 院校卡片列表（后端返回）
                ...(
                  (() {
                    final display = _applyDisplayFilters(_recommendations);
                    return display.isEmpty
                        ? [const Text('暂无推荐数据，调整偏好或应用权重后重试')]
                        : List.generate(display.length, (index) {
                            final rec = display[index];
                          final name = rec['COLLEGE_NAME']?.toString() ?? '-';
                      final code = RegExp(r'\d+').stringMatch(rec['COLLEGE_CODE']?.toString() ?? '') ?? '';
                      final province = rec['PROVINCE']?.toString() ?? '-';
                          final prob = (rec['probability'] as num?)?.toDouble() ?? 0.0;
                          final matchPct = (((rec['matchScore'] as num?)?.toDouble() ?? 0.0) * 100).round();
                          final cat = (rec['category']?.toString() ?? '').trim();
                          String categoryLabel;
                          Color categoryColor;
                          if (cat == '保' || cat == '保底') { categoryLabel = '保底'; categoryColor = const Color(0xFF2C5BF0); }
                          else if (cat == '稳' || cat == '稳妥') { categoryLabel = '稳妥'; categoryColor = const Color(0xFF21B573); }
                          else if (cat == '冲' || cat == '冲刺') { categoryLabel = '冲刺'; categoryColor = const Color(0xFFF04F52); }
                          else if (cat == '参考') { categoryLabel = '参考'; categoryColor = const Color(0xFF7C8698); }
                          else {
                            if (prob >= 0.75) { categoryLabel = '保底'; categoryColor = const Color(0xFF2C5BF0); }
                            else if (prob >= 0.4) { categoryLabel = '稳妥'; categoryColor = const Color(0xFF21B573); }
                            else if (prob >= 0.2) { categoryLabel = '冲刺'; categoryColor = const Color(0xFFF04F52); }
                            else { categoryLabel = '参考'; categoryColor = const Color(0xFF7C8698); }
                          }
                          final admissions = (rec['admissions'] as List? ?? const [])
                              .map((e) => e as Map<String, dynamic>)
                              .toList();
                          final highlights = admissions
                              .map((a) => '${a['year']}：最低分 ${a['minScore']} | 位次 ${a['minRank']}')
                              .toList();
                          final tags = <Widget>[
                            TagChip(label: categoryLabel, color: categoryColor),
                            if ((rec['IS_985']?.toString() ?? '0') == '1') const TagChip(label: '985'),
                            if ((rec['IS_211']?.toString() ?? '0') == '1') const TagChip(label: '211'),
                            if ((rec['IS_DFC']?.toString() ?? '0') == '1') const TagChip(label: '双一流'),
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CollegeCard(
                              name: name,
                              code: code,
                              location: '$province',
                              matchScore: matchPct,
                              probability: prob,
                              categoryLabel: categoryLabel,
                              categoryColor: categoryColor,
                              tags: tags,
                              highlights: highlights,
                              isFavorite: _favoriteColleges.contains(name),
                              isInDraft: _draftColleges.contains(name),
                              onView: () => _showCollegeDetail(name, code),
                              onCollect: () => _toggleFavorite(name),
                              onAddDraft: () => _addToDraft(name),
                            ),
                          );
                        });
                  })()
                ),
              ],
            ),
          ),
        ),
        
        // 加载遮罩
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          '正在更新推荐结果...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF424A59),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// 统计卡片
class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({
    required this.totalCount,
    required this.favoriteCount,
  });

  final int totalCount;
  final int favoriteCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C5BF0), Color(0xFF1E47CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C5BF0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.recommend,
              label: '推荐院校',
              value: totalCount.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.favorite,
              label: '已收藏',
              value: favoriteCount.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

// 算法说明项
class _AlgorithmItem extends StatelessWidget {
  const _AlgorithmItem({
    required this.label,
    required this.items,
  });

  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424A59),
            ),
          ),
        ),
        Expanded(
          child: Text(
            items.join(' · '),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7C8698),
            ),
          ),
        ),
      ],
    );
  }
}

// 偏好滑块
class _PreferenceSlider extends StatefulWidget {
  const _PreferenceSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.onPreview,
  });

  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onPreview;

  @override
  State<_PreferenceSlider> createState() => _PreferenceSliderState();
}

class _PreferenceSliderState extends State<_PreferenceSlider> {
  late double _val;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _val = widget.value;
  }

  @override
  void didUpdateWidget(covariant _PreferenceSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.0001) {
      _val = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(widget.icon, size: 18, color: const Color(0xFF424A59)),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424A59),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C5BF0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_val * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: const Color(0xFF2C5BF0),
              inactiveTrackColor: const Color(0xFFD3D9E5),
              thumbColor: const Color(0xFF2C5BF0),
              overlayColor: const Color(0xFF2C5BF0).withOpacity(0.2),
            ),
            child: Slider(
              value: _val,
              onChanged: (v) {
                setState(() => _val = v);
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 60), () {
                  widget.onPreview?.call(_val);
                });
              },
              onChangeEnd: (v) => widget.onChanged(v),
              min: 0.1,
              max: 0.7,
              divisions: 60,
            ),
          ),
        ],
      ),
    );
  }
}

// 院校卡片
class _CollegeCard extends StatelessWidget {
  const _CollegeCard({
    required this.name,
    required this.code,
    required this.location,
    required this.matchScore,
    required this.probability,
    required this.categoryLabel,
    required this.categoryColor,
    required this.tags,
    required this.highlights,
    this.isFavorite = false,
    this.isInDraft = false,
    this.onView,
    this.onCollect,
    this.onAddDraft,
  });

  final String name;
  final String code;
  final String location;
  final int matchScore;
  final double probability;
  final String categoryLabel;
  final Color categoryColor;
  final List<Widget> tags;
  final List<String> highlights;
  final bool isFavorite;
  final bool isInDraft;
  final VoidCallback? onView;
  final VoidCallback? onCollect;
  final VoidCallback? onAddDraft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE3E8EF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withOpacity(0.1),
                  categoryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1F2E),
                              ),
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFF7C8698),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7C8698),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        matchScore.toString(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '匹配度',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7C8698),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 内容
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标签
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags,
                ),
                const SizedBox(height: 16),

                // 录取概率
                Row(
                  children: [
                    const Icon(
                      Icons.show_chart,
                      size: 16,
                      color: Color(0xFF424A59),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '录取概率',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424A59),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(probability * 100).round()}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: probability,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE3E8EF),
                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),

                // 历年数据
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 16,
                            color: Color(0xFF424A59),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '历年录取数据',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424A59),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < highlights.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i < highlights.length - 1 ? 8 : 0,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7C8698),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                highlights[i],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5769),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCollect,
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: isFavorite
                              ? const Color(0xFFF04F52)
                              : null,
                        ),
                        label: Text(
                          isFavorite ? '已收藏' : '目标院校',
                          style: TextStyle(
                            fontSize: 13,
                            color: isFavorite
                                ? const Color(0xFFF04F52)
                                : null,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isFavorite
                                ? const Color(0xFFF04F52)
                                : const Color(0xFFD3D9E5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onView,
                        icon: const Icon(Icons.chevron_right, size: 16),
                        label: const Text('详情', style: TextStyle(fontSize: 13)),
                        style: FilledButton.styleFrom(
                          backgroundColor: categoryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 详情区域
class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF2C5BF0)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1F2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

// 详情项
class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7C8698),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424A59),
              ),
            ),
          ),
        ],
      ),
    );
  }
}