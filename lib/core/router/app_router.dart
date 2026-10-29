import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/main/presentation/main_screen.dart';
import '../../features/home/presentation/book_detail_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/studio/presentation/add_chapter_screen.dart';
import '../../features/studio/domain/chapter_model.dart';
import '../../features/studio/presentation/edit_chapter_screen.dart';
import '../../features/profile/presentation/my_works_screen.dart';
import '../../features/profile/presentation/my_reviews_screen.dart';
import '../../features/studio/presentation/upload_book_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/user_provider.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/book/:id',
        name: 'book_detail',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return BookDetailScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/read/:id',
        name: 'read',
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          final initialIndex = state.extra as int? ?? 0;
          return ReaderScreen(bookId: bookId, initialIndex: initialIndex);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit_profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/add-chapter/:bookId',
        name: 'add_chapter',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          // Đã xóa phần truyền bookTitle
          return AddChapterScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/my-works',
        name: 'my_works',
        builder: (context, state) => const MyWorksScreen(),
      ),
      GoRoute(
        path: '/edit-chapter/:bookId',
        name: 'edit_chapter',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final chapter = state.extra as Chapter;
          return EditChapterScreen(bookId: bookId, chapter: chapter);
        },
      ),
      GoRoute(
        path: '/my-reviews',
        name: 'my_reviews',
        builder: (context, state) => const MyReviewsScreen(),
      ),
      GoRoute(
        path: '/upload-book',
        name: 'upload_book',
        builder: (context, state) => const UploadBookScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});