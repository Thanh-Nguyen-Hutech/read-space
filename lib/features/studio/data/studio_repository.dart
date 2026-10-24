import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../home/domain/book_model.dart';
import '../../home/data/home_providers.dart';
import '../domain/chapter_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String imgbbApiKey = '932115cb13a5250aadc00a1e0762e183';

final studioRepositoryProvider = Provider<StudioRepository>((ref) {
  return StudioRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class StudioRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StudioRepository(this._firestore, this._auth);

  Future<void> uploadBook({
    required String title,
    required String author,
    required String description,
    required File coverImage,
    required String type,               // THÊM: Định dạng truyện
    required List<String> categoryIds,  // THÊM: Mảng đa thể loại
  }) async {
    final url = Uri.parse('https://api.imgbb.com/1/upload');
    final request = http.MultipartRequest('POST', url);

    request.fields['key'] = imgbbApiKey;
    request.files.add(await http.MultipartFile.fromPath('image', coverImage.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonMap = json.decode(responseData);

    if (jsonMap['success'] == true) {
      final coverUrl = jsonMap['data']['url'];
      final newBookRef = _firestore.collection('books').doc();

      final newBook = Book(
        id: newBookRef.id,
        title: title,
        author: author,
        authorId: _auth.currentUser?.uid ?? '',
        description: description,
        coverUrl: coverUrl,
        rating: 0.0,
      );

      // Chuyển book thành Map và GỘP THÊM các trường mới của hệ thống
      final bookMap = newBook.toMap();
      bookMap['type'] = type;
      bookMap['categoryIds'] = categoryIds;
      bookMap['status'] = 'Đang ra';
      bookMap['createdAt'] = FieldValue.serverTimestamp();

      await newBookRef.set(bookMap);
    } else {
      throw Exception('Lỗi upload ảnh lên ImgBB: ${jsonMap['error']['message']}');
    }
  }

  Future<void> addChapter({
    required String bookId,
    required String title,
    required String content,
    required String bookTitle, // Thêm tham số này để lấy tên truyện đưa vào thông báo
  }) async {
    final chaptersRef = _firestore.collection('books').doc(bookId).collection('chapters');
    final snapshot = await chaptersRef.get();
    final nextIndex = snapshot.docs.length + 1;

    // 1. Thêm chương mới
    final newChapterRef = chaptersRef.doc();
    await newChapterRef.set({
      'bookId': bookId,
      'title': title,
      'content': content,
      'index': nextIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Phát tán thông báo cho toàn bộ độc giả đang theo dõi (Lưu trong library)
    // Lưu ý: Cần tạo Index dạng collectionGroup cho collection 'library' trên Firebase Console
    final followersSnapshot = await _firestore
        .collectionGroup('library')
    // documentId của library chính là bookId
        .where(FieldPath.documentId, isEqualTo: bookId)
        .get();

    final batch = _firestore.batch();
    for (var doc in followersSnapshot.docs) {
      // Lấy uid của độc giả từ đường dẫn: users/{uid}/library/{bookId}
      final readerUid = doc.reference.parent.parent!.id;
      final notiRef = _firestore.collection('users').doc(readerUid).collection('notifications').doc();

      batch.set(notiRef, {
        'title': 'Chương mới: $bookTitle',
        'body': 'Tác giả vừa cập nhật chương $nextIndex: $title',
        'type': 'new_chapter',
        'referenceId': bookId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    // Thực thi ghi hàng loạt thông báo
    await batch.commit();

    // 3. Cập nhật bộ đếm tác giả
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).set({
        'totalPublishedChapters': FieldValue.increment(1)
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).delete();
  }

  Future<void> updateChapter({
    required String bookId,
    required String chapterId,
    required String title,
    required String content,
  }) async {
    await _firestore
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId)
        .update({
      'title': title,
      'content': content,
    });
  }

  Future<void> deleteChapter({
    required String bookId,
    required String chapterId,
  }) async {
    await _firestore
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId)
        .delete();

    // Tự động trừ 1 tổng số chương khi xóa
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).set({
        'totalPublishedChapters': FieldValue.increment(-1)
      }, SetOptions(merge: true));
    }
  }
}