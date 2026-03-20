// ═══════════════════════════════════════════════════════════════
// Velvet Sync · lib/screens/main_navigation.dart
// Navegación principal con Bottom Navigation Bar
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LvsColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          CatalogScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: LvsColors.bg,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: LvsColors.pink,
          unselectedItemColor: LvsColors.text3,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          unselectedLabelStyle: const TextStyle(fontSize: 10, letterSpacing: 1),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.devices_rounded, size: 20),
              label: 'CONTROL',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_rounded, size: 20),
              label: 'CATÁLOGO',
            ),
          ],
        ),
      ),
    );
  }
}
