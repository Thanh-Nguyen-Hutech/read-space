import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/data/user_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../../explore/presentation/explore_screen.dart';
import '../../notification/presentation/notification_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../profile/presentation/profile_screen.dart';

// 1. CÁC BIẾN TOÀN CỤC ĐIỀU KHIỂN TỪ XA
final mainTabIndexProvider = StateProvider<int>((ref) => 0);
final exploreSearchQueryProvider = StateProvider<String>((ref) => '');
final exploreFilterModeProvider = StateProvider<String>((ref) => 'Mới cập nhật');

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const NotificationScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _trackDailyVisit();
    _requestPushNotificationPermissions();
  }

  Future<void> _requestPushNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (token != null && user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'pushEnabled': true,
        });
      }
    }
  }

  Future<void> _trackDailyVisit() async {
    try {
      final now = DateTime.now();
      final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final month = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      final docRef = FirebaseFirestore.instance.collection('analytics').doc('visits');
      await docRef.set({
        'daily_$today': FieldValue.increment(1),
        'monthly_$month': FieldValue.increment(1),
        'total': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Lỗi ghi nhận truy cập: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainTabIndexProvider);

    // 2. ĐỌC SỐ LƯỢNG THÔNG BÁO CHƯA ĐỌC TỪ PROVIDER
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadCountAsync.maybeWhen(data: (count) => count, orElse: () => 0);

    ref.listen(currentUserProfileProvider, (previous, next) {
      final userProfile = next.value;
      if (userProfile != null && userProfile.role == 'banned') {
        ref.read(authRepositoryProvider).signOut();
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phiên đăng nhập hết hạn hoặc tài khoản bị khóa!'))
        );
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(mainTabIndexProvider.notifier).state = index;
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          const NavigationDestination(icon: Icon(Icons.explore_rounded), label: 'Khám phá'),

          // 3. TÍCH HỢP BADGE VÀO ICON THÔNG BÁO (Đã gỡ bỏ chữ const ở mảng destinations)
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0, // Chỉ hiện chấm đỏ khi số lượng > 0
              label: Text(unreadCount.toString()),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount.toString()),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Thông báo',
          ),

          const NavigationDestination(icon: Icon(Icons.bookmarks_rounded), label: 'Thư viện'),
          const NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Cá nhân'),
        ],
      ),
    );
  }
}