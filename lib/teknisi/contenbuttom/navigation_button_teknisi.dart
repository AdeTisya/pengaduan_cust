// lib/teknisi/contenbuttom/navigation_button_teknisi.dart

import 'package:flutter/material.dart';
import 'dashbord_teknisi.dart';
import 'complaint_list_teknisi.dart';
import 'profile_teknisi.dart';

class AppNavigatorTeknisi {
  static PageRouteBuilder slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class MainScaffoldTeknisi extends StatefulWidget {
  final int initialIndex;
  const MainScaffoldTeknisi({super.key, this.initialIndex = 0});

  @override
  State<MainScaffoldTeknisi> createState() => _MainScaffoldTeknisiState();
}

class _MainScaffoldTeknisiState extends State<MainScaffoldTeknisi> {
  late int _currentIndex;

  // Ganti dengan halaman-halaman milik teknisi
  final List<Widget> _pages = const [
    DashboardTeknisi(),
    ComplaintListTeknisi(),
    ProfileTeknisi(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _CustomBottomNavTeknisi(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _CustomBottomNavTeknisi extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CustomBottomNavTeknisi({
    required this.currentIndex,
    required this.onTap,
  });

  static const _bgColor     = Color(0xFF1E2A5E);
  static const _activeColor = Color(0xFF6B7DB3);

  static const _items = [
    _NavItemTeknisi(icon: Icons.home,               label: 'Home'),
    _NavItemTeknisi(icon: Icons.assignment_outlined, label: 'Tugas'),
    _NavItemTeknisi(icon: Icons.person_outline,      label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top:    8,
        bottom: bottomPadding > 0 ? bottomPadding : 12,
        left:   16,
        right:  16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final item     = _items[index];
          final isActive = index == currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve:    Curves.easeInOut,
                margin:   const EdgeInsets.symmetric(horizontal: 4),
                padding:  const EdgeInsets.symmetric(vertical: 10),
                decoration: isActive
                    ? BoxDecoration(
                        color:        _activeColor,
                        borderRadius: BorderRadius.circular(16),
                      )
                    : const BoxDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color:      Colors.white,
                        fontSize:   12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItemTeknisi {
  final IconData icon;
  final String   label;
  const _NavItemTeknisi({required this.icon, required this.label});
}