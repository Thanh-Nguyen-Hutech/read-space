import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Khởi tạo hiệu ứng mờ dần (Fade-in) kéo dài 1.5 giây
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Giữ màn hình Splash tối thiểu 2.5 giây để người dùng kịp nhìn thấy Logo
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // KẾT NỐI LUỒNG: Kiểm tra session đăng nhập hiện tại
    final user = ref.read(firebaseAuthProvider).currentUser;

    if (user != null) {
      // Đã đăng nhập -> Vào thẳng trang chủ
      context.go('/home');
    } else {
      // Chưa đăng nhập hoặc phiên hết hạn -> Bắt đăng nhập
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ứng dụng (Có thể thay thế bằng Image.asset nếu bạn có file logo riêng)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Tên ứng dụng
              Text(
                'ReadSpace',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),

              // Slogan
              Text(
                'Không gian sáng tạo của bạn',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 48),
              // Vòng xoay tải dữ liệu nhỏ gọn
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}