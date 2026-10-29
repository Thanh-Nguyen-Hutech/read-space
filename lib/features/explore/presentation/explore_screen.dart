import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main/presentation/main_screen.dart';
import '../data/explore_providers.dart';
import '../../category/data/category_repository.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exploreBooksAsync = ref.watch(exploreBooksProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    final sortMode = ref.watch(exploreFilterModeProvider);
    final isDescending = ref.watch(sortDescendingProvider);

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
                // Thanh tìm kiếm sử dụng StateProvider toàn cục
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tên truyện, tác giả...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  onChanged: (value) => ref.read(exploreSearchQueryProvider.notifier).state = value,
                ),
                const SizedBox(height: 16),

                // Lọc thể loại trượt ngang
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Lỗi tải danh mục: $err'),
                    data: (categories) {
                      return Row(
                        children: [
                          _buildFilterChip(ref, 'all', 'Tất cả'),
                          ...categories.map((cat) => _buildFilterChip(ref, cat.id, cat.name)),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Bộ lọc Sắp xếp phức hợp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cột trái: Đảo chiều (Tăng / Giảm)
                    InkWell(
                      onTap: () => ref.read(sortDescendingProvider.notifier).state = !isDescending,
                      child: Row(
                        children: [
                          Icon(isDescending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(isDescending ? 'Giảm dần' : 'Tăng dần', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    // Cột phải: Tiêu chí
                    Row(
                      children: [
                        const Icon(Icons.sort_rounded, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: sortMode,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'Mới cập nhật', child: Text('Mới cập nhật')),
                            DropdownMenuItem(value: 'Đánh giá cao', child: Text('Đánh giá cao')),
                            DropdownMenuItem(value: 'Lượt xem', child: Text('Nhiều lượt xem')),
                            DropdownMenuItem(value: 'Số chương', child: Text('Số lượng chương')),
                          ],
                          onChanged: (val) => ref.read(exploreFilterModeProvider.notifier).state = val!,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lưới kết quả
          Expanded(
            child: exploreBooksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi tải danh sách: $err')),
              data: (books) {
                if (books.isEmpty) return const Center(child: Text('Không tìm thấy tác phẩm nào phù hợp.', style: TextStyle(color: Colors.grey)));

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
                              child: Image.network(book.coverUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
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