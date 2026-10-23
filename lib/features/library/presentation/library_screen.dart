import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/library_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Lắng nghe danh sách sách đã lưu từ provider
    final savedBooks = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện của tôi'),
        centerTitle: true,
      ),
      body: savedBooks.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_add_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Thư viện trống',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy khám phá và lưu lại những cuốn sách yêu thích nhé!',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cột
          childAspectRatio: 0.6, // Tỉ lệ chiều rộng/chiều cao của thẻ sách
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: savedBooks.length,
        itemBuilder: (context, index) {
          final book = savedBooks[index];
          return InkWell(
            onTap: () => context.push('/book/${book.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      book.coverUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}