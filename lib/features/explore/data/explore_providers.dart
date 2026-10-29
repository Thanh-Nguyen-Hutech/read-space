import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../home/domain/book_model.dart';
import '../../home/data/home_providers.dart';
import '../../main/presentation/main_screen.dart';

// Trạng thái chiều sắp xếp (Tăng dần / Giảm dần)
final sortDescendingProvider = StateProvider<bool>((ref) => true);

// Trạng thái lọc thể loại
final categoryFilterProvider = StateProvider<String>((ref) => 'all');

final exploreBooksProvider = Provider.autoDispose<AsyncValue<List<Book>>>((ref) {
  final booksAsync = ref.watch(booksProvider);
  final searchQuery = ref.watch(exploreSearchQueryProvider).toLowerCase();
  final categoryId = ref.watch(categoryFilterProvider);
  final sortMode = ref.watch(exploreFilterModeProvider);
  final isDescending = ref.watch(sortDescendingProvider);

  return booksAsync.whenData((books) {
    // 1. Lọc theo trạng thái (Ẩn truyện vi phạm)
    var filtered = books.where((b) => b.status != 'Khóa/Vi phạm').toList();

    // 2. Lọc theo từ khóa tìm kiếm
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((b) =>
      b.title.toLowerCase().contains(searchQuery) ||
          b.author.toLowerCase().contains(searchQuery)
      ).toList();
    }

    // 3. Lọc theo thể loại (ĐÃ MỞ KHÓA)
    if (categoryId != 'all') {
      filtered = filtered.where((b) => b.categoryIds.contains(categoryId)).toList();
    }

    // 4. Sắp xếp đa chiều (Sort)
    filtered.sort((a, b) {
      int comparison = 0;
      switch (sortMode) {
        case 'Đánh giá cao':
          comparison = a.rating.compareTo(b.rating);
          break;
        case 'Lượt xem':
        // Cần trường views trong Book model, tạm dùng rating mô phỏng nếu chưa có
          comparison = a.rating.compareTo(b.rating);
          break;
        case 'Số chương':
        // Cần trường chapterCount trong Book model, tạm so sánh tiêu đề để test logic
          comparison = a.title.compareTo(b.title);
          break;
        case 'Mới cập nhật':
        default:
        // So sánh id (hoặc updatedAt nếu đã parse trong model) để lấy mới nhất
          comparison = a.id.compareTo(b.id);
          break;
      }
      return isDescending ? -comparison : comparison; // Đảo chiều nếu Giảm dần
    });

    return filtered;
  });
});