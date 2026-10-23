import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/domain/book_model.dart';

// Notifier giúp quản lý một state phức tạp (như List) và thông báo cho UI khi có thay đổi
class LibraryNotifier extends Notifier<List<Book>> {
  @override
  List<Book> build() {
    // Khởi tạo thư viện trống ban đầu
    return [];
  }

  // Hàm thêm hoặc xóa sách khỏi thư viện
  void toggleBookmark(Book book) {
    final isSaved = state.any((b) => b.id == book.id);
    if (isSaved) {
      // Nếu đã lưu rồi -> Xóa đi
      state = state.where((b) => b.id != book.id).toList();
    } else {
      // Nếu chưa lưu -> Thêm vào danh sách hiện tại
      state = [...state, book];
    }
  }

  // Hàm kiểm tra xem một cuốn sách đã được lưu hay chưa
  bool isBookSaved(String bookId) {
    return state.any((b) => b.id == bookId);
  }
}

// Provider để cung cấp LibraryNotifier cho toàn app
final libraryProvider = NotifierProvider<LibraryNotifier, List<Book>>(() {
  return LibraryNotifier();
});