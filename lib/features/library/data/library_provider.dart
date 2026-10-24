import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../home/domain/book_model.dart';

class LibraryNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() async {
    return _fetchSavedBooks();
  }

  Future<List<Book>> _fetchSavedBooks() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return [];

    final db = FirebaseFirestore.instance;
    final librarySnapshot = await db.collection('users').doc(user.uid).collection('library').orderBy('savedAt', descending: true).get();

    List<Book> books = [];
    for (var doc in librarySnapshot.docs) {
      final bookDoc = await db.collection('books').doc(doc.id).get();
      if (bookDoc.exists) {
        // Lưu ý điều chỉnh hàm fromMap() cho khớp với model Book của bạn
        books.add(Book.fromMap(bookDoc.data() as Map<String, dynamic>, bookDoc.id));
      }
    }
    return books;
  }

  Future<void> toggleBookmark(Book book) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instance;
    final libraryRef = db.collection('users').doc(user.uid).collection('library').doc(book.id);

    final previousState = state.value ?? [];
    final isSaved = previousState.any((b) => b.id == book.id);

    if (isSaved) {
      // Xóa khỏi DB và cập nhật UI ngay lập tức
      state = AsyncData(previousState.where((b) => b.id != book.id).toList());
      await libraryRef.delete();
    } else {
      // Thêm vào DB và cập nhật UI
      state = AsyncData([book, ...previousState]);
      await libraryRef.set({'savedAt': FieldValue.serverTimestamp()});
    }
  }

  bool isBookSaved(String bookId) {
    return state.value?.any((b) => b.id == bookId) ?? false;
  }
}

final libraryProvider = AsyncNotifierProvider<LibraryNotifier, List<Book>>(() {
  return LibraryNotifier();
});