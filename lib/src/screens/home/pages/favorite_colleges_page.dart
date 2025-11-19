import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';
import 'package:zygc_flutter_prototype/src/services/api_client.dart';
import 'dart:convert';

class FavoriteCollegesPage extends StatefulWidget {
  const FavoriteCollegesPage({super.key});

  @override
  State<FavoriteCollegesPage> createState() => _FavoriteCollegesPageState();
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}

class _FavoriteCollegesPageState extends State<FavoriteCollegesPage> {
  final List<_FavoriteCollege> _favorites = [];
  bool _initialized = false;
  late String _userId;


  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('favorites_$_userId');
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      setState(() {
        _favorites
          ..clear()
          ..addAll(list.map((e) => _FavoriteCollege(
                name: e['name']?.toString() ?? '-',
                location: e['location']?.toString() ?? '-',
                tags: (e['tags'] as List?)?.map((x) => x.toString()).toList() ?? const [],
                addedDate: e['addedDate']?.toString() ?? '',
                notes: e['notes']?.toString() ?? '',
                code: e['code']?.toString(),
                probability: (e['probability'] as num?)?.toDouble(),
                matchScore: (e['matchScore'] as num?)?.toDouble(),
                category: e['category']?.toString(),
                admissions: ((e['admissions'] as List?)?.map((a) => {
                  'year': a['year'], 'minScore': a['minScore'], 'minRank': a['minRank'],
                }).toList() ?? const []),
              )));
      });
      _sortFavorites();
      await _hydrateFavorites();
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _favorites
        .map((c) => {
              'name': c.name,
              'location': c.location,
              'tags': c.tags,
              'addedDate': c.addedDate,
              'notes': c.notes,
              'code': c.code,
              'probability': c.probability,
              'matchScore': c.matchScore,
              'category': c.category,
              'admissions': c.admissions,
            })
        .toList();
    await prefs.setString('favorites_$_userId', jsonEncode(list));
  }

  void _sortFavorites() {
    _favorites.sort((a, b) => _orderKey(a).compareTo(_orderKey(b)));
  }

  int _orderKey(_FavoriteCollege c) {
    final cat = (c.category ?? '').trim();
    if (cat == '参考') return 0;
    if (cat == '冲' || cat == '冲刺') return 1;
    if (cat == '稳' || cat == '稳妥') return 2;
    if (cat == '保' || cat == '保底') return 3;
    final p = c.probability ?? 0.0;
    if (p >= 0.75) return 3;
    if (p >= 0.4) return 2;
    if (p >= 0.2) return 1;
    return 0;
  }

  void _removeFromFavorites(int index) {
    final college = _favorites[index];
    setState(() {
      _favorites.removeAt(index);
    });
    _saveFavorites();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('已移出目标院校 ${college.name}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            setState(() {
              _favorites.insert(index, college);
            });
            _saveFavorites();
          },
        ),
      ),
    );
  }

  Future<void> _hydrateFavorites() async {
    final client = ApiClient();
    final scope = AuthScope.of(context);
    final token = scope.session.token;
    bool changed = false;
    for (var i = 0; i < _favorites.length; i++) {
      var fav = _favorites[i];
      String? code = fav.code;
      if (code == null || code.isEmpty) {
        try {
          final search = await client.get('/colleges', query: {'q': fav.name, 'pageSize': '1'});
          final rows = (search['data'] as List?) ?? const [];
          if (rows.isNotEmpty) {
            code = (rows.first['COLLEGE_CODE']?.toString()) ?? '';
          }
        } catch (_) {}
      }
      Map<String, dynamic> detail = {};
      if (code != null && code.isNotEmpty) {
        try {
          final d = await client.get('/colleges/$code');
          detail = (d['data'] as Map<String, dynamic>?) ?? {};
        } catch (_) {}
        if (fav.admissions.isEmpty) {
          try {
            final a = await client.get('/colleges/$code/admissions', headers: {'Authorization': 'Bearer $token'});
            final list = (a['data'] as List?)?.map((e) => {
              'year': e['ADMISSION_YEAR'],
              'minScore': e['MIN_SCORE'],
              'minRank': e['MIN_RANK'],
            }).toList() ?? [];
            fav = _FavoriteCollege(
              name: fav.name,
              location: (detail['PROVINCE']?.toString() ?? fav.location),
              tags: fav.tags.isEmpty
                  ? [
                      if ((detail['IS_985']?.toString() ?? '0') == '1') '985',
                      if ((detail['IS_211']?.toString() ?? '0') == '1') '211',
                      if ((detail['IS_DFC']?.toString() ?? detail['IS_DOUBLE_FIRST_CLASS']?.toString() ?? '0') == '1') '双一流',
                    ]
                  : fav.tags,
              addedDate: fav.addedDate,
              notes: fav.notes,
              code: code,
              probability: fav.probability,
              matchScore: fav.matchScore,
              category: fav.category,
              admissions: list,
            );
            _favorites[i] = fav;
            changed = true;
          } catch (_) {}
        }
      }
    }
    if (changed) {
      _sortFavorites();
      await _saveFavorites();
      if (mounted) setState(() {});
    }
  }

  void _editNotes(int index) {
    final controller = TextEditingController(text: _favorites[index].notes);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑备注'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '添加你对这所院校的备注...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _favorites[index] = _FavoriteCollege(
                  name: _favorites[index].name,
                  location: _favorites[index].location,
                  tags: _favorites[index].tags,
                  addedDate: _favorites[index].addedDate,
                  notes: controller.text,
                );
              });
              _saveFavorites();
              Navigator.of(context).pop();
              final messenger = ScaffoldMessenger.maybeOf(context);
              messenger?.clearSnackBars();
              messenger?.showSnackBar(
                const SnackBar(
                  content: Text('备注已更新'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  dismissDirection: DismissDirection.horizontal,
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetailByName(String name) async {
    final scope = AuthScope.of(context);
    final token = scope.session.token;
    final client = ApiClient();
    try {
      final search = await client.get('/colleges', query: {'q': name, 'pageSize': '1'});
      final rows = search['data'] as List? ?? const [];
      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('未找到院校：$name')),
        );
        return;
      }
      final row = rows.first as Map<String, dynamic>;
      final code = (row['COLLEGE_CODE'] ?? row['collegeCode'])?.toString() ?? '';
      final detail = await client.get(
        '/colleges/$code',
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = (detail['data'] as Map<String, dynamic>?) ?? {};

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['COLLEGE_NAME']?.toString() ?? name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('院校代码：$code', style: const TextStyle(color: Color(0xFF7C8698))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(title: const Text('所在省份'), trailing: Text((data['PROVINCE'] ?? '-').toString())),
                ListTile(title: const Text('所在城市'), trailing: Text((data['CITY_NAME'] ?? '-').toString())),
                ListTile(title: const Text('院校类型'), trailing: Text((data['COLLEGE_TYPE'] ?? '-').toString())),
                ListTile(
                  title: const Text('院校标签'),
                  trailing: Text([
                    if ((data['IS_985']?.toString() ?? '') == '1' || (data['IS_985'] == true)) '985',
                    if ((data['IS_211']?.toString() ?? '') == '1' || (data['IS_211'] == true)) '211',
                    if ((data['IS_DFC']?.toString() ?? data['IS_DOUBLE_FIRST_CLASS']?.toString() ?? '') == '1') '双一流',
                  ].join(' · ')),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('详情加载失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_initialized) {
      final scope = AuthScope.of(context);
      _userId = scope.session.user.userId;
      _initialized = true;
      _loadFavorites();
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
        title: const Text('目标院校'),
        actions: [
          if (_favorites.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('清空目标院校'),
                    content: const Text('确定要清空所有目标院校吗？此操作不可撤销。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _favorites.clear();
                          });
                          _saveFavorites();
                          Navigator.of(context).pop();
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          messenger?.clearSnackBars();
                          messenger?.showSnackBar(
                            const SnackBar(
                              content: Text('已清空目标院校'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              dismissDirection: DismissDirection.horizontal,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF04F52),
                        ),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('清空'),
            ),
        ],
      ),
      body: _favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无目标院校',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在推荐页点击目标院校按钮添加',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('去推荐页'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final favorite = _favorites[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _FavoriteCard(
                    favorite: favorite,
                    onRemove: () => _removeFromFavorites(index),
                    onEditNotes: () => _editNotes(index),
                    onViewDetail: () async {
                      await _openDetailByName(favorite.name);
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _FavoriteCollege {
  const _FavoriteCollege({
    required this.name,
    required this.location,
    required this.tags,
    required this.addedDate,
    required this.notes,
    this.code,
    this.probability,
    this.matchScore,
    this.category,
    this.admissions = const [],
  });

  final String name;
  final String location;
  final List<String> tags;
  final String addedDate;
  final String notes;
  final String? code;
  final double? probability;
  final double? matchScore;
  final String? category;
  final List<Map<String, dynamic>> admissions;
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.favorite,
    required this.onRemove,
    required this.onEditNotes,
    required this.onViewDetail,
  });

  final _FavoriteCollege favorite;
  final VoidCallback onRemove;
  final VoidCallback onEditNotes;
  final VoidCallback onViewDetail;

  Color _categoryColor(String? category, double? probability) {
    final c = (category ?? '').trim();
    if (c == '保底' || c == '保') return const Color(0xFF2C5BF0);
    if (c == '稳妥' || c == '稳') return const Color(0xFF21B573);
    if (c == '冲刺' || c == '冲') return const Color(0xFFF04F52);
    if (c == '参考') return const Color(0xFF7C8698);
    final p = probability ?? 0.0;
    if (p >= 0.75) return const Color(0xFF2C5BF0);
    if (p >= 0.4) return const Color(0xFF21B573);
    if (p >= 0.2) return const Color(0xFFF04F52);
    return const Color(0xFF7C8698);
  }

  String _categoryLabel(String? category, double? probability) {
    final c = (category ?? '').trim();
    if (c == '保底' || c == '保') return '保';
    if (c == '稳妥' || c == '稳') return '稳';
    if (c == '冲刺' || c == '冲') return '冲';
    if (c == '参考') return '参考';
    final p = probability ?? 0.0;
    if (p >= 0.75) return '保';
    if (p >= 0.4) return '稳';
    if (p >= 0.2) return '冲';
    return '参考';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _categoryColor(favorite.category, favorite.probability);
    final categoryLabel = _categoryLabel(favorite.category, favorite.probability);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE8ECF4)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 140) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              favorite.location,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            favorite.addedDate,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: onRemove,
                          color: const Color(0xFF7C8698),
                          iconSize: 22,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            favorite.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.place_rounded, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  favorite.location,
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                favorite.addedDate,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: onRemove,
                      color: const Color(0xFF7C8698),
                      iconSize: 22,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                TagChip(label: categoryLabel, color: categoryColor),
                ...favorite.tags.map((tag) => TagChip(label: tag)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    label: '录取概率',
                    value: favorite.probability != null ? '${(favorite.probability! * 100).round()}%' : '-',
                    valueColor: categoryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoRow(
                    label: '匹配度',
                    value: favorite.matchScore != null ? '${((favorite.matchScore ?? 0) * 100).round()}%' : '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (favorite.probability != null) ...[
              LinearProgressIndicator(
                value: favorite.probability ?? 0.0,
                minHeight: 10,
                backgroundColor: const Color(0xFFE3E8EF),
                valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
              ),
              const SizedBox(height: 12),
            ],
            if (favorite.admissions.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('历年录取数据', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF424A59))),
                    const SizedBox(height: 8),
                    ...favorite.admissions.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('${a['year']}：最低分 ${a['minScore']} | 位次 ${a['minRank']}', style: const TextStyle(fontSize: 12, color: Color(0xFF4B5769))),
                        )),
                  ],
                ),
              ),
            if (favorite.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: Color(0xFF7C8698),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        favorite.notes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF4B5769),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditNotes,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('编辑备注'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onViewDetail,
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('查看详情'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
