import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key, required this.onViewCollege});

  final ValueChanged<String>? onViewCollege;

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> with SingleTickerProviderStateMixin {
  // 权重设置
  double _regionWeight = 0.4;
  double _tierWeight = 0.35;
  double _majorWeight = 0.25;
  
  // 筛选和排序
  final Set<String> _filters = <String>{'全部'};
  String _sortBy = '匹配度'; // 匹配度、录取概率、院校层次
  
  // 收藏和草案
  final Set<String> _favoriteColleges = {};
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
    super.dispose();
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
    ScaffoldMessenger.of(context).showSnackBar(
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
      ),
    );
  }

  /// 显示院校详情弹窗
  void _showCollegeDetail(String collegeName, String collegeCode) {
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
              // 拖动指示器
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3D9E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题栏
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collegeName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1F2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '院校代码：$collegeCode',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7C8698),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F7FB),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 内容区域
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    _DetailSection(
                      title: '院校概况',
                      icon: Icons.school_outlined,
                      children: [
                        _DetailItem(label: '院校类型', value: '师范类'),
                        _DetailItem(label: '院校层次', value: '985/211/双一流'),
                        _DetailItem(label: '办学性质', value: '公办'),
                        _DetailItem(label: '所在地区', value: '上海市'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _DetailSection(
                      title: '招生信息',
                      icon: Icons.assignment_outlined,
                      children: [
                        _DetailItem(label: '2024年计划', value: '120人'),
                        _DetailItem(label: '实际录取', value: '118人'),
                        _DetailItem(label: '最低分数', value: '612分'),
                        _DetailItem(label: '最低位次', value: '10,800名'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _DetailSection(
                      title: '特色专业',
                      icon: Icons.stars_outlined,
                      children: [
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text('教育学', style: TextStyle(fontSize: 12)),
                              backgroundColor: Color(0xFFE3F2FD),
                            ),
                            Chip(
                              label: Text('心理学', style: TextStyle(fontSize: 12)),
                              backgroundColor: Color(0xFFE8F5E9),
                            ),
                            Chip(
                              label: Text('地理科学', style: TextStyle(fontSize: 12)),
                              backgroundColor: Color(0xFFFFF3E0),
                            ),
                            Chip(
                              label: Text('统计学', style: TextStyle(fontSize: 12)),
                              backgroundColor: Color(0xFFF3E5F5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 底部按钮
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
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
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _draftColleges.add(collegeName);
                          });
                          _showToast('已加入草案', backgroundColor: Colors.green);
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('加入草案'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF2C5BF0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
  void _toggleFavorite(String collegeName) {
    setState(() {
      if (_favoriteColleges.contains(collegeName)) {
        _favoriteColleges.remove(collegeName);
        _showToast('已取消收藏 $collegeName');
      } else {
        _favoriteColleges.add(collegeName);
        _showToast('已收藏 $collegeName', backgroundColor: Colors.orange);
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

  /// 重置权重
  void _resetWeights() {
    setState(() {
      _regionWeight = 0.4;
      _tierWeight = 0.35;
      _majorWeight = 0.25;
    });
    _showToast('权重已重置');
  }

  /// 应用权重
  void _applyWeights() {
    setState(() {
      _isLoading = true;
    });
    
    // 模拟应用权重的延迟
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
                  totalCount: 4,
                  favoriteCount: _favoriteColleges.length,
                  draftCount: _draftColleges.length,
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
                            Row(
                              children: const [
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
                            _AlgorithmItem(
                              label: '客观数据',
                              items: ['历年录取线 40%', '生源因素 25%', '报考历史 15%'],
                            ),
                            const SizedBox(height: 8),
                            _AlgorithmItem(
                              label: '主观偏好',
                              items: [
                                '目标地区 ${(_regionWeight * 100).round()}%',
                                '院校层次 ${(_tierWeight * 100).round()}%',
                                '专业方向 ${(_majorWeight * 100).round()}%',
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
                                  Row(
                                    children: const [
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
                                  _PreferenceSlider(
                                    label: '目标地区',
                                    icon: Icons.location_on_outlined,
                                    value: _regionWeight,
                                    onChanged: (value) => setState(() => _regionWeight = value),
                                  ),
                                  const SizedBox(height: 12),
                                  _PreferenceSlider(
                                    label: '院校层次',
                                    icon: Icons.school_outlined,
                                    value: _tierWeight,
                                    onChanged: (value) => setState(() => _tierWeight = value),
                                  ),
                                  const SizedBox(height: 12),
                                  _PreferenceSlider(
                                    label: '专业方向',
                                    icon: Icons.work_outline,
                                    value: _majorWeight,
                                    onChanged: (value) => setState(() => _majorWeight = value),
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
                      icon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
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
                        '985院校',
                        '211院校',
                        '长三角'
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

                // 院校卡片列表
                _CollegeCard(
                  name: '华东师范大学',
                  code: '10269',
                  location: '上海 · 师范类 · 985/211',
                  matchScore: 92,
                  probability: 0.68,
                  categoryLabel: '稳妥',
                  categoryColor: const Color(0xFF21B573),
                  description:
                      '成绩匹配度高（高出 16 分）+ 偏好吻合（教育学 + 长三角）+ 高中历史录取率 86%。',
                  tags: const [
                    TagChip(label: '稳妥', color: Color(0xFF21B573)),
                    TagChip(label: '偏好吻合'),
                    TagChip(label: '高中录取率 86%', color: Color(0xFF2C5BF0)),
                  ],
                  highlights: const [
                    '2024：最低分 612 | 位次 10,800',
                    '2023：最低分 608 | 位次 11,200',
                    '2022：最低分 606 | 位次 11,650'
                  ],
                  isFavorite: _favoriteColleges.contains('华东师范大学'),
                  isInDraft: _draftColleges.contains('华东师范大学'),
                  onView: () => _showCollegeDetail('华东师范大学', '10269'),
                  onCollect: () => _toggleFavorite('华东师范大学'),
                  onAddDraft: () => _addToDraft('华东师范大学'),
                ),
                const SizedBox(height: 16),
                _CollegeCard(
                  name: '南京大学',
                  code: '10284',
                  location: '江苏 · 综合类 · 985/211',
                  matchScore: 88,
                  probability: 0.54,
                  categoryLabel: '冲刺',
                  categoryColor: const Color(0xFFF04F52),
                  description:
                      '与目标线差距 4 分，偏好匹配度高，建议关注位次提升与复习节奏。',
                  tags: const [
                    TagChip(label: '冲刺', color: Color(0xFFF04F52)),
                    TagChip(label: '偏好吻合'),
                    TagChip(label: '提升空间'),
                  ],
                  highlights: const [
                    '2024：最低分 632 | 位次 9,200',
                    '2023：最低分 628 | 位次 9,800',
                    '2022：最低分 627 | 位次 10,100'
                  ],
                  isFavorite: _favoriteColleges.contains('南京大学'),
                  isInDraft: _draftColleges.contains('南京大学'),
                  onView: () => _showCollegeDetail('南京大学', '10284'),
                  onCollect: () => _toggleFavorite('南京大学'),
                  onAddDraft: () => _addToDraft('南京大学'),
                ),
                const SizedBox(height: 16),
                _CollegeCard(
                  name: '北京理工大学',
                  code: '10007',
                  location: '北京 · 工科 · 985/211',
                  matchScore: 90,
                  probability: 0.62,
                  categoryLabel: '稳妥',
                  categoryColor: const Color(0xFF2C5BF0),
                  description: '当前分数高于近三年录取线 8 分，适合作为稳妥备选。',
                  tags: const [
                    TagChip(label: '稳妥', color: Color(0xFF2C5BF0)),
                    TagChip(label: '课程调研'),
                  ],
                  highlights: const [
                    '2024：最低分 620 | 位次 11,600',
                    '2023：最低分 618 | 位次 11,900',
                    '2022：最低分 615 | 位次 12,300'
                  ],
                  isFavorite: _favoriteColleges.contains('北京理工大学'),
                  isInDraft: _draftColleges.contains('北京理工大学'),
                  onView: () => _showCollegeDetail('北京理工大学', '10007'),
                  onCollect: () => _toggleFavorite('北京理工大学'),
                  onAddDraft: () => _addToDraft('北京理工大学'),
                ),
                const SizedBox(height: 16),
                _CollegeCard(
                  name: '东北师范大学',
                  code: '10200',
                  location: '吉林 · 师范类 · 211',
                  matchScore: 80,
                  probability: 0.92,
                  categoryLabel: '保底',
                  categoryColor: const Color(0xFF21B573),
                  description: '成绩优势明显，高于近三年录取线 28 分，是可靠保底选择。',
                  tags: const [
                    TagChip(label: '保底', color: Color(0xFF21B573)),
                    TagChip(label: '安全选择'),
                    TagChip(label: '高中录取率 92%', color: Color(0xFF21B573)),
                  ],
                  highlights: const [
                    '2024：最低分 598 | 位次 18,500',
                    '2023：最低分 595 | 位次 19,200',
                    '2022：最低分 593 | 位次 19,800'
                  ],
                  isFavorite: _favoriteColleges.contains('东北师范大学'),
                  isInDraft: _draftColleges.contains('东北师范大学'),
                  onView: () => _showCollegeDetail('东北师范大学', '10200'),
                  onCollect: () => _toggleFavorite('东北师范大学'),
                  onAddDraft: () => _addToDraft('东北师范大学'),
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
    required this.draftCount,
  });

  final int totalCount;
  final int favoriteCount;
  final int draftCount;

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
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.drafts,
              label: '草案',
              value: draftCount.toString(),
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
class _PreferenceSlider extends StatelessWidget {
  const _PreferenceSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;

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
                  Icon(icon, size: 18, color: const Color(0xFF424A59)),
                  const SizedBox(width: 8),
                  Text(
                    label,
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
                  '${(value * 100).round()}%',
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
              value: value,
              onChanged: onChanged,
              min: 0.1,
              max: 0.7,
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
    required this.description,
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
  final String description;
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
                          if (isInDraft)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF21B573),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '已在草案',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: const Color(0xFF7C8698),
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

                // 描述
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF424A59),
                    height: 1.5,
                  ),
                ),
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
                      Row(
                        children: const [
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
                          isFavorite ? '已收藏' : '收藏',
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
                      child: OutlinedButton.icon(
                        onPressed: isInDraft ? null : onAddDraft,
                        icon: Icon(
                          isInDraft ? Icons.check : Icons.add,
                          size: 16,
                        ),
                        label: Text(
                          isInDraft ? '已加入' : '草案',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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