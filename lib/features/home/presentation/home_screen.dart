import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../data/home_providers.dart';
import '../domain/book_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    // Gọi các luồng dữ liệu chuyên biệt đã định nghĩa
    final newBooksAsync = ref.watch(newBooksProvider);
    final hotBooksAsync = ref.watch(hotAllTimeBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReadSpace', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào buổi sáng,',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  Text(
                    user?.displayName ?? user?.email?.split('@')[0] ?? 'Người đọc',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            _buildSectionHeader(context, title: 'Mới cập nhật'),
            _buildHorizontalList(newBooksAsync),

            const SizedBox(height: 24),

            _buildSectionHeader(context, title: 'Hot nhất mọi thời gian'),
            _buildHorizontalList(hotBooksAsync),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
        ],
      ),
    );
  }

  // Khối xử lý giao diện cuộn ngang dựa trên trạng thái AsyncValue
  Widget _buildHorizontalList(AsyncValue<List<Book>> booksAsync) {
    return booksAsync.when(
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: 240,
        child: Center(child: Text('Lỗi: $error', style: const TextStyle(color: Colors.red))),
      ),
      data: (books) {
        if (books.isEmpty) {
          return const SizedBox(
            height: 240,
            child: Center(child: Text('Chưa có cuốn sách nào.')),
          );
        }
        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return _buildBookCard(context, books[index]);
            },
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
                child: Image.network(
                  book.coverUrl,
                  width: 140,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}