import 'package:flutter/material.dart';

import 'pages/college_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/info_page.dart';
import 'pages/profile_page.dart';
import 'pages/recommend_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 2;

  late final List<_HomeDestination> _destinations = [
    _HomeDestination(
      label: '高考',
      icon: Icons.edit_note_rounded,
      builder: (context) => const InfoPage(),
    ),
    _HomeDestination(
      label: '推荐',
      icon: Icons.track_changes_rounded,
      builder: (context) => const RecommendPage(),
    ),
    _HomeDestination(
      label: '首页',
      icon: Icons.home_filled,
      builder: (context) => const DashboardPage(),
    ),
    _HomeDestination(
      label: '院校',
      icon: Icons.account_balance_rounded,
      builder: (context) => const CollegePage(),
    ),
    _HomeDestination(
      label: '我的',
      icon: Icons.person_rounded,
      builder: (context) => ProfilePage(onSignOut: widget.onSignOut),
    ),
  ];

  void _onDestinationSelected(int value) {
    setState(() => _index = value);
  }

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
            const Positioned(
              right: 24,
              bottom: 92,
              child: _FloatingAction(),
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
  const _FloatingAction();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF2C5BF0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x5A2C5BF0), blurRadius: 32, offset: Offset(0, 16)),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
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
