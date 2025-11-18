import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/models/auth_models.dart';
import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'pages/analysis_page.dart';
import 'pages/college_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/info_page.dart';
import 'pages/profile_page.dart';
import 'pages/recommend_page.dart';
import 'pages/favorite_colleges_page.dart'; 

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.session,
    required this.onSignOut,
    required this.onUpdateUser,
    super.key,
  });

  final AuthSession session;
  final VoidCallback onSignOut;
  final ValueChanged<AuthUser> onUpdateUser;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 2;
  final GlobalKey<RecommendPageState> _recommendKey = GlobalKey<RecommendPageState>();
  late final List<_HomeDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = [
      _HomeDestination(
        label: '高考',
        icon: Icons.edit_note_rounded,
        builder: (context) => InfoPage(
          onEditProfile: () => _navigateTo(4),
          onViewPreferences: () => _navigateTo(1),
          onViewAnalysis: () => _navigateTo(0), // 改为页内跳转到分析区域
        ),
      ),
      _HomeDestination(
        label: '推荐',
        icon: Icons.track_changes_rounded,
        builder: (context) => RecommendPage(
          key: _recommendKey,
          onViewCollege: (collegeCode) => _navigateTo(3),
        ),
      ),
      _HomeDestination(
        label: '首页',
        icon: Icons.home_filled,
        builder: (context) => DashboardPage(
          onGoInfo: () => _navigateTo(0),
          onGoRecommend: () => _navigateTo(1),
          onGoProfile: () => _navigateTo(4),
          onGoCollege: () => _navigateTo(3),
          onGoAnalysis: () => _navigateTo(0), 
        ),
      ),
      _HomeDestination(
        label: '院校',
        icon: Icons.account_balance_rounded,
        builder: (context) => const CollegePage(),
      ),
      _HomeDestination(
        label: '我的',
        icon: Icons.person_rounded,
        builder: (context) => ProfilePage(
          onSignOut: widget.onSignOut,
          onEditProfile: () => _navigateTo(0),
          onAdjustWeights: () => _navigateTo(1),
          onManageShare: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('共享设置'),
              content: const Text('请前往协同管理页面设置共享对象。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('好的'),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  void _navigateTo(int value) {
    if (_index == value) return;
    setState(() => _index = value); // 通过修改索引切换页面,不使用路由栈
  }

  void _onDestinationSelected(int value) => _navigateTo(value);

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_index];

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FF),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFEFF3FF), Color(0xFFFAFBFF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: KeyedSubtree(
                        key: ValueKey(destination.label),
                        child: destination.builder(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 24,
              bottom: 108, // 从 92 调整到 108，向上移动 16px
              child: _FloatingAction(currentIndex: _index, onNavigate: _navigateTo, recommendKey: _recommendKey),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomNavBar(
                items: _destinations,
                currentIndex: _index,
                onChanged: _onDestinationSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDestination {
  const _HomeDestination({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

class _FloatingAction extends StatelessWidget {
  const _FloatingAction({required this.currentIndex, required this.onNavigate, this.recommendKey});

  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final GlobalKey<RecommendPageState>? recommendKey;

  @override
  Widget build(BuildContext context) {
    // 根据当前页面显示不同的浮动操作
    final String tooltip;
    final IconData icon;
    final VoidCallback action;

    switch (currentIndex) {
      case 0: // 高考信息页
        tooltip = '快速录入成绩';
        icon = Icons.add_chart_rounded;
        action = () => _showScoreInputDialog(context);
        break;
      case 1: // 推荐页
        tooltip = '保存推荐方案';
        icon = Icons.save_rounded;
        action = () {
          final state = recommendKey?.currentState;
          if (state != null) {
            state.saveRecommendationPlan();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('页面未就绪，稍后再试')));
          }
        };
        break;
      case 2: // 收藏功能
        tooltip = '我的收藏';
        icon = Icons.favorite_rounded;
        action = () => _openFavoritesPage(context);
        break;
      default: // 我的和院校页
        return const SizedBox.shrink();
    }

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2430),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: action,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF2C5BF0),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5A2C5BF0),
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  void _showScoreInputDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('快速录入成绩', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: '总分', hintText: '请输入总分'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: '省内排名', hintText: '请输入排名'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('成绩录入成功')),
                        );
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateRecommendations(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生成推荐方案'),
        content: const Text('系统将根据您的成绩和偏好生成个性化推荐方案，是否继续?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('正在生成推荐方案...')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _openFavoritesPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FavoriteCollegesPage(),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<_HomeDestination> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(15, 23, 42, 0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Color(0x1A000000), offset: Offset(0, -4), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _BottomNavItem(
                icon: items[i].icon,
                label: items[i].label,
                selected: currentIndex == i,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = selected ? Colors.white : Colors.white.withOpacity(0.6);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: selected ? 6 : 0),
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: selected ? 12 : 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2C5BF0) : Colors.transparent,
          borderRadius: BorderRadius.circular(selected ? 16 : 14),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x592C5BF0), blurRadius: 28, offset: Offset(0, 14))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: selected ? 24 : 22, color: textColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: selected ? 12 : 11,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: selected ? 0.6 : 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
