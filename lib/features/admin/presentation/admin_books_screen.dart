import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. Quản lý trạng thái bộ lọc
final adminSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final adminStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'Tất cả');

// 2. Lắng nghe danh sách truyện Realtime
final adminBooksStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('books')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {
    'id': doc.id,
    ...doc.data(),
  }).toList());
});

class AdminBooksScreen extends ConsumerWidget {
  const AdminBooksScreen({super.key});

  Future<void> _updateBookStatus(BuildContext context, String bookId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('books').doc(bookId).update({'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật trạng thái thành: $newStatus')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _confirmDelete(BuildContext context, String bookId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tác phẩm'),
        content: Text('Bạn có chắc chắn muốn xóa vĩnh viễn truyện "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('books').doc(bookId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(adminBooksStreamProvider);
    final searchQuery = ref.watch(adminSearchQueryProvider);
    final statusFilter = ref.watch(adminStatusFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm duyệt Truyện', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 3. Khung Tìm kiếm & Lọc
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên truyện, tác giả...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) => ref.read(adminSearchQueryProvider.notifier).state = value,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: statusFilter,
                      items: ['Tất cả', 'Bản nháp', 'Đang ra', 'Đã hoàn thành', 'Khóa/Vi phạm']
                          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) ref.read(adminStatusFilterProvider.notifier).state = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 4. Danh sách Truyện đã được lọc
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
              data: (books) {
                // Lọc Client-side
                final filteredBooks = books.where((book) {
                  final title = (book['title'] ?? '').toString().toLowerCase();
                  final author = (book['author'] ?? '').toString().toLowerCase();
                  final status = book['status'] ?? 'Không rõ';

                  final matchesSearch = title.contains(searchQuery.toLowerCase()) || author.contains(searchQuery.toLowerCase());
                  final matchesStatus = statusFilter == 'Tất cả' || status == statusFilter;

                  return matchesSearch && matchesStatus;
                }).toList();

                if (filteredBooks.isEmpty) {
                  return const Center(child: Text('Không tìm thấy tác phẩm nào phù hợp.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    final status = book['status'] ?? 'Không rõ';

                    Color statusColor = Colors.green;
                    if (status == 'Khóa/Vi phạm') statusColor = Colors.red;
                    else if (status == 'Bản nháp') statusColor = Colors.grey;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            book['coverUrl'] ?? 'https://via.placeholder.com/150',
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
                        title: Text(book['title'] ?? 'Truyện không tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tác giả: ${book['author'] ?? 'Ẩn danh'}'),
                            Text('Trạng thái: $status', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _confirmDelete(context, book['id'], book['title']);
                            } else {
                              _updateBookStatus(context, book['id'], value);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'Đang ra', child: Text('Chuyển sang "Đang ra"')),
                            const PopupMenuItem(value: 'Đã hoàn thành', child: Text('Chuyển sang "Đã hoàn thành"')),
                            const PopupMenuItem(value: 'Khóa/Vi phạm', child: Text('Đánh dấu "Vi phạm"', style: TextStyle(color: Colors.orange))),
                            const PopupMenuDivider(),
                            const PopupMenuItem(value: 'delete', child: Text('Xóa truyện', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}