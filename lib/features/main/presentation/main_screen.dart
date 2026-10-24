import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_screen.dart';
import '../../explore/presentation/explore_screen.dart';
import '../../profile/presentation/my_works_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  // Đã xóa UploadBookScreen, chỉ giữ lại đúng 5 màn hình tương ứng với 5 tab
  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const MyWorksScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.explore_rounded), label: 'Khám phá'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded), label: 'Sáng tác'),
          NavigationDestination(icon: Icon(Icons.bookmarks_rounded), label: 'Thư viện'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Cá nhân'),
        ],
      ),
    );
  }
}