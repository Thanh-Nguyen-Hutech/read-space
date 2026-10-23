import 'package:flutter/material.dart';
import '../../home/presentation/home_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../studio/presentation/upload_book_screen.dart';
import '../../profile/presentation/profile_screen.dart'; // THÊM IMPORT NÀY

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Khai báo 4 màn hình chính thức
  final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
    const UploadBookScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // Cập nhật lại các icon và label cho khớp với 4 màn hình
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books_rounded), label: 'Thư viện'),
          NavigationDestination(icon: Icon(Icons.edit_document), selectedIcon: Icon(Icons.edit_document), label: 'Sáng tác'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Cá nhân'),
        ],
      ),
    );
  }
}