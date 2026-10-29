import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_repository.dart';
import '../data/home_providers.dart';
import '../domain/book_model.dart';
import '../../main/presentation/main_screen.dart';

// 1. PROVIDER LẤY DANH SÁCH BANNER ĐANG HOẠT ĐỘNG
final activeBannersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

final randomBooksProvider = FutureProvider.autoDispose<List<Book>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('books').get();

  final validBooks = snapshot.docs
      .map((doc) => Book.fromMap(doc.data(), doc.id))
      .where((b) => b.status != 'Khóa/Vi phạm')
      .toList();

  validBooks.shuffle();
  return validBooks.take(15).toList();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    final newBooksAsync = ref.watch(newBooksProvider);
    final hotBooksAsync = ref.watch(hotAllTimeBooksProvider);
    final randomBooksAsync = ref.watch(randomBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ReadSpace', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(randomBooksProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chào buổi sáng,', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                    Text(user?.displayName ?? user?.email?.split('@')[0] ?? 'Người đọc', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // 2. TÍCH HỢP KHUNG BANNER DƯỚI LỜI CHÀO
              _buildBannerSection(ref),
              const SizedBox(height: 16),

              _buildSectionHeader(context, title: 'Mới cập nhật', onTap: () {
                ref.read(exploreFilterModeProvider.notifier).state = 'Mới cập nhật';
                ref.read(mainTabIndexProvider.notifier).state = 1;
              }),
              _buildHorizontalList(newBooksAsync),
              const SizedBox(height: 24),

              _buildSectionHeader(context, title: 'Hot nhất mọi thời gian', onTap: () {
                ref.read(exploreFilterModeProvider.notifier).state = 'Đánh giá cao';
                ref.read(mainTabIndexProvider.notifier).state = 1;
              }),
              _buildHorizontalList(hotBooksAsync),
              const SizedBox(height: 24),

              _buildSectionHeader(context, title: 'Có thể bạn sẽ thích', onTap: () {
                ref.read(exploreFilterModeProvider.notifier).state = 'Lượt xem';
                ref.read(mainTabIndexProvider.notifier).state = 1;
              }),
              _buildVerticalList(randomBooksAsync),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // KHỐI GIAO DIỆN HIỂN THỊ BANNER QUẢNG CÁO
  Widget _buildBannerSection(WidgetRef ref) {
    final bannersAsync = ref.watch(activeBannersProvider);

    return bannersAsync.when(
      loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink(); // Ẩn khung nếu Admin không đăng Banner nào

        return SizedBox(
          height: 160,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.92), // Giúp nhìn thấy lấp ló banner tiếp theo
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(banner['imageUrl'] ?? 'https://via.placeholder.com/600x200'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Xử lý khi nhấn vào Banner (Mở link QR Donate hoặc Link truyện)
                      final link = banner['link'];
                      if (link != null && link.toString().isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đang mở link: $link')));
                        // Tương lai bạn có thể dùng thư viện url_launcher để mở web tại đây
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          TextButton(onPressed: onTap, child: const Text('Xem tất cả')),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(AsyncValue<List<Book>> booksAsync) {
    return booksAsync.when(
      loading: () => const SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
      error: (error, stack) => SizedBox(height: 240, child: Center(child: Text('Lỗi: $error', style: const TextStyle(color: Colors.red)))),
      data: (books) {
        if (books.isEmpty) return const SizedBox(height: 240, child: Center(child: Text('Chưa có cuốn sách nào.')));
        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: books.length,
            itemBuilder: (context, index) => _buildBookCard(context, books[index]),
          ),
        );
      },
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/book/${book.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(book.coverUrl, width: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
              ),
            ),
            const SizedBox(height: 8),
            Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalList(AsyncValue<List<Book>> booksAsync) {
    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Lỗi: $error', style: const TextStyle(color: Colors.red))),
      data: (books) {
        if (books.isEmpty) return const SizedBox();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: books.length,
          itemBuilder: (context, index) => _buildVerticalBookCard(context, books[index]),
        );
      },
    );
  }

  Widget _buildVerticalBookCard(BuildContext context, Book book) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/book/${book.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 110,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.coverUrl,
                width: 75,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        book.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}