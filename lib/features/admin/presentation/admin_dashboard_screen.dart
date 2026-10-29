import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_books_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_banners_screen.dart'; // 1. IMPORT FILE QUẢN LÝ BANNER
import 'admin_notifications_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // 2. THÊM AdminBannersScreen VÀO DANH SÁCH MÀN HÌNH
  final List<Widget> _pages = const [
    AdminOverviewScreen(),
    AdminBooksScreen(),
    AdminUsersScreen(),
    AdminCategoriesScreen(),
    AdminBannersScreen(), // <-- Thêm vào đây
    AdminNotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Tự động mở rộng thanh menu nếu màn hình lớn (Tablet/Web)
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          // Thanh điều hướng bên trái
          NavigationRail(
            extended: isLargeScreen,
            backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: isLargeScreen
                  ? Text('ReadSpace Admin', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary))
                  : Icon(Icons.admin_panel_settings, color: theme.colorScheme.primary, size: 32),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Tổng quan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books_rounded),
                label: Text('Kiểm duyệt Truyện'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: Text('Tài khoản'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category_rounded),
                label: Text('Thể loại'),
              ),
              // 3. THÊM TAB MENU CHO QUẢNG CÁO
              NavigationRailDestination(
                icon: Icon(Icons.view_carousel_outlined),
                selectedIcon: Icon(Icons.view_carousel_rounded),
                label: Text('Quảng cáo'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign_rounded),
                label: Text('Thông báo'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Vùng hiển thị nội dung chính
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}