import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'videos/videos_screen.dart';
import 'quizzes/quizzes_screen.dart';
import 'storybooks/storybooks_screen.dart';
import 'profile/profile_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    VideosScreen(),
    QuizzesScreen(),
    StorybooksScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            items: _buildItems(),
          ),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildItems() {
    final items = [
      ('🏠', 'Home'),
      ('🎬', 'Videos'),
      ('🧩', 'Quizzes'),
      ('📖', 'Stories'),
      ('👤', 'Profile'),
    ];

    return items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final isSelected = _selectedIndex == i;

      return BottomNavigationBarItem(
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.12) : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            item.$1,
            style: TextStyle(fontSize: isSelected ? 24 : 22),
          ),
        ),
        label: item.$2,
      );
    }).toList();
  }
}
