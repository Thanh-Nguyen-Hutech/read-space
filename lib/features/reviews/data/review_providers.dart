import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/home_providers.dart';
import '../domain/comment_model.dart';
import '../../auth/data/auth_repository.dart';

// 1. PROVIDER LẮNG NGHE BÌNH LUẬN (Phần bị thiếu)
final bookCommentsProvider = StreamProvider.family<List<CommentModel>, String>((ref, bookId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('books')
      .doc(bookId)
      .collection('comments')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => CommentModel.fromMap(doc.data(), doc.id)).toList());
});

// 2. LẮNG NGHE ĐÁNH GIÁ SAO CỦA USER HIỆN TẠI
final userRatingProvider = StreamProvider.family<int?, String>((ref, bookId) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(null);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('books')
      .doc(bookId)
      .collection('ratings')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? doc.data()!['rating'] as int : null);
});

// 3. REPOSITORY PROVIDER
final reviewRepositoryProvider = Provider((ref) => ReviewRepository(ref.watch(firestoreProvider)));

class ReviewRepository {
  final FirebaseFirestore _firestore;
  ReviewRepository(this._firestore);

  // ==========================================
  // LOGIC ĐÁNH GIÁ (RATINGS)
  // ==========================================
  Future<void> _updateBookAverageRating(String bookId) async {
    final snapshot = await _firestore.collection('books').doc(bookId).collection('ratings').get();

    double avgRating = 0.0;
    if (snapshot.docs.isNotEmpty) {
      double totalStars = 0;
      for (var doc in snapshot.docs) {
        totalStars += (doc.data()['rating'] as num).toDouble();
      }
      avgRating = totalStars / snapshot.docs.length;
    }

    await _firestore.collection('books').doc(bookId).update({
      'rating': double.parse(avgRating.toStringAsFixed(1)),
    });
  }

  Future<void> submitRating(String bookId, String userId, int rating) async {
    await _firestore.collection('books').doc(bookId).collection('ratings').doc(userId).set({
      'rating': rating,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _updateBookAverageRating(bookId);
  }

  Future<void> deleteRating(String bookId, String userId) async {
    await _firestore.collection('books').doc(bookId).collection('ratings').doc(userId).delete();
    await _updateBookAverageRating(bookId);
  }

  // ==========================================
  // LOGIC BÌNH LUẬN (COMMENTS)
  // ==========================================
  Future<void> addComment({required String bookId, required CommentModel comment}) async {
    await _firestore.collection('books').doc(bookId).collection('comments').doc(comment.id).set(comment.toMap());
  }

  Future<void> deleteComment(String bookId, String commentId) async {
    await _firestore.collection('books').doc(bookId).collection('comments').doc(commentId).delete();
  }

  Future<void> updateComment(String bookId, String commentId, String newContent) async {
    await _firestore.collection('books').doc(bookId).collection('comments').doc(commentId).update({
      'content': newContent,
    });
  }
}

final myCommentsHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return [];

  final firestore = ref.watch(firestoreProvider);

  // collectionGroup quét toàn bộ các sub-collection có tên là 'comments' ở bất kỳ sách nào
  final snapshot = await firestore
      .collectionGroup('comments')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs.map((doc) {
    // Lấy ID của cuốn sách chứa bình luận này (đường dẫn gốc: books/bookId/comments/commentId)
    final bookId = doc.reference.parent.parent?.id ?? '';
    return {
      'bookId': bookId,
      'comment': CommentModel.fromMap(doc.data(), doc.id),
    };
  }).toList();
});