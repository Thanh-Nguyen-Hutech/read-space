import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Thêm import này

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Đợi 2 giây để hiển thị UI
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // KIỂM TRA TRẠNG THÁI ĐĂNG NHẬP
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Đã đăng nhập -> Vào thẳng Home
        context.go('/home');
      } else {
        // Chưa đăng nhập -> Ra màn hình Login
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'ReadSpace',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Không gian đọc và chia sẻ',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}