import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/data/home_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Lấy toàn bộ danh sách sách từ Firestore (đã được cache qua provider)
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true, // Tự động mở bàn phím khi vào trang
          decoration: const InputDecoration(
            hintText: 'Tìm tên sách, tác giả...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
          )
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Lỗi: $e')),
        data: (books) {
          // Lọc sách theo từ khóa (tìm theo Tên hoặc Tác giả)
          final filteredBooks = books.where((b) {
            return b.title.toLowerCase().contains(_searchQuery) ||
                b.author.toLowerCase().contains(_searchQuery);
          }).toList();

          if (_searchQuery.isEmpty) {
            return const Center(
              child: Text('Hãy nhập từ khóa để tìm kiếm tác phẩm', style: TextStyle(color: Colors.grey)),
            );
          }

          if (filteredBooks.isEmpty) {
            return const Center(
              child: Text('Không tìm thấy tác phẩm nào phù hợp.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: filteredBooks.length,
            itemBuilder: (context, index) {
              final book = filteredBooks[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    book.coverUrl,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.book, size: 50),
                  ),
                ),
                title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(book.author, style: const TextStyle(color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () {
                  // Bấm vào kết quả thì chuyển sang trang Chi tiết sách
                  context.push('/book/${book.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}