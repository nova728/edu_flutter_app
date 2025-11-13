import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';

class FavoriteCollegesPage extends StatefulWidget {
  const FavoriteCollegesPage({super.key});

  @override
  State<FavoriteCollegesPage> createState() => _FavoriteCollegesPageState();
}

class _FavoriteCollegesPageState extends State<FavoriteCollegesPage> {
  final List<_FavoriteCollege> _favorites = [
    _FavoriteCollege(
      name: '华东师范大学',
      location: '上海',
      tags: ['985', '211', '双一流'],
      addedDate: '2024-11-10',
      notes: '教育学专业全国排名前三',
    ),
    _FavoriteCollege(
      name: '南京大学',
      location: '江苏',
      tags: ['985', '211', '双一流'],
      addedDate: '2024-11-08',
      notes: '综合实力强，氛围好',
    ),
    _FavoriteCollege(
      name: '浙江大学',
      location: '浙江',
      tags: ['985', '211', '双一流'],
      addedDate: '2024-11-05',
      notes: '工科优势明显',
    ),
  ];

  void _removeFromFavorites(int index) {
    final college = _favorites[index];
    setState(() {
      _favorites.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已取消收藏 ${college.name}'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            setState(() {
              _favorites.insert(index, college);
            });
          },
        ),
      ),
    );
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
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('备注已更新')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

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
        title: const Text('我的收藏'),
        actions: [
          if (_favorites.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('清空收藏'),
                    content: const Text('确定要清空所有收藏吗？此操作不可撤销。'),
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
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已清空收藏')),
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
                    '暂无收藏院校',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在院校列表中点击收藏按钮添加',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('去浏览院校'),
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
                    onViewDetail: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('查看 ${favorite.name} 详情')),
                      );
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
  });

  final String name;
  final String location;
  final List<String> tags;
  final String addedDate;
  final String notes;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            Row(
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
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            favorite.location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            favorite.addedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_rounded),
                  onPressed: onRemove,
                  color: const Color(0xFFF04F52),
                  iconSize: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: favorite.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C5BF0).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C5BF0),
                          ),
                        ),
                      ))
                  .toList(),
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
