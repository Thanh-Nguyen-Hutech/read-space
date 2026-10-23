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
    final booksAsyncValue = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReadSpace'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              context.push('/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      // Dùng SingleChildScrollView để toàn bộ màn hình có thể cuộn dọc
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Lời chào
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
                    user?.email?.split('@')[0] ?? 'Người đọc',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Section: Load dữ liệu sách
            booksAsyncValue.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Text('Lỗi tải dữ liệu: $error', style: const TextStyle(color: Colors.red)),
              ),
              data: (books) {
                if (books.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Chưa có cuốn sách nào trên hệ thống.'),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mục: Dành cho bạn
                    _buildSectionHeader(context, title: 'Dành cho bạn'),
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(context, books[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mục: Mới cập nhật
                    _buildSectionHeader(context, title: 'Mới cập nhật'),
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: books.reversed.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(context, books.reversed.toList()[index]);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Widget dùng chung để tạo Tiêu đề cho các danh mục
  Widget _buildSectionHeader(BuildContext context, {required String title}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Xem tất cả'),
          ),
        ],
      ),
    );
  }

  // Widget dùng chung để vẽ Thẻ sách (Book Card)
  Widget _buildBookCard(BuildContext context, Book book) {
    final theme = Theme.of(context);

    // Sử dụng InkWell để tạo hiệu ứng gợn sóng khi bấm
    return InkWell(
      onTap: () {
        // Chuyển hướng và truyền ID lên URL
        context.push('/book/${book.id}');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140, // Chiều rộng cố định của mỗi thẻ sách
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa sách
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
            // Tên sách
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            // Tác giả
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