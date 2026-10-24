import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/data/home_providers.dart';
// Import file chứa activeCategoriesProvider vừa tạo ở bước trước
import '../../category/data/category_repository.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exploreBooksAsync = ref.watch(exploreBooksProvider);
    final selectedTime = ref.watch(timeFilterProvider);

    // Lắng nghe danh sách thể loại từ Firestore
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Thanh tìm kiếm
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tên truyện, tác giả...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => ref.read(searchFilterProvider.notifier).state = value,
                ),
                const SizedBox(height: 16),

                // Lọc thể loại trượt ngang (Dữ liệu động)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Lỗi tải danh mục: $err'),
                    data: (categories) {
                      return Row(
                        children: [
                          // Luôn giữ Chip "Tất cả" ở vị trí đầu tiên
                          _buildFilterChip(ref, 'all', 'Tất cả'),
                          // Trải phẳng các danh mục lấy từ Firebase
                          ...categories.map((cat) => _buildFilterChip(ref, cat.id, cat.name)),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Bộ lọc theo thời gian / Trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.sort_rounded, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedTime,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Mới cập nhật')),
                        DropdownMenuItem(value: 'completed', child: Text('Đã hoàn thành')),
                      ],
                      onChanged: (val) => ref.read(timeFilterProvider.notifier).state = val!,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lưới kết quả tìm kiếm
          Expanded(
            child: exploreBooksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
              data: (books) {
                if (books.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy tác phẩm nào phù hợp.', style: TextStyle(color: Colors.grey)),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return InkWell(
                      onTap: () => context.push('/book/${book.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(book.coverUrl, fit: BoxFit.cover, width: double.infinity),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
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

  Widget _buildFilterChip(WidgetRef ref, String id, String label) {
    final isSelected = ref.watch(categoryFilterProvider) == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => ref.read(categoryFilterProvider.notifier).state = id,
      ),
    );
  }
}