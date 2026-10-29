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
    required String type,
    required List<String> categoryIds,
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

      final bookMap = newBook.toMap();
      bookMap['type'] = type;
      bookMap['categoryIds'] = categoryIds;
      bookMap['status'] = 'Đang ra';
      bookMap['createdAt'] = FieldValue.serverTimestamp();
      // THÊM: Gắn mốc thời gian cập nhật để luôn nhảy lên Top
      bookMap['updatedAt'] = FieldValue.serverTimestamp();

      await newBookRef.set(bookMap);

      // Bắn thông báo toàn hệ thống khi có truyện mới ra mắt
      final usersSnapshot = await _firestore.collection('users').get();
      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in usersSnapshot.docs) {
        final notiRef = _firestore.collection('users').doc(doc.id).collection('notifications').doc();
        batch.set(notiRef, {
          'title': 'Truyện mới ra mắt! 🎉',
          'body': 'Tác phẩm "$title" vừa lên sóng. Đọc ngay!',
          'type': 'new_book',
          'bookId': newBookRef.id, // Khóa deep-link
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        count++;
        if (count % 495 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }
      if (count % 495 != 0) await batch.commit();

    } else {
      throw Exception('Lỗi upload ảnh lên ImgBB: ${jsonMap['error']['message']}');
    }
  }

  Future<void> addChapter({
    required String bookId,
    required String title,
    required String content,
  }) async {
    // 1. TỰ ĐỘNG LẤY THÔNG TIN TRUYỆN ĐỂ LẤY TÊN (TITLE)
    final bookSnap = await _firestore.collection('books').doc(bookId).get();
    final bookTitle = bookSnap.data()?['title'] ?? 'Tác phẩm';

    final chaptersRef = _firestore.collection('books').doc(bookId).collection('chapters');
    final snapshot = await chaptersRef.get();
    final nextIndex = snapshot.docs.length + 1;

    // 2. Thêm chương mới
    final newChapterRef = chaptersRef.doc();
    await newChapterRef.set({
      'bookId': bookId,
      'title': title,
      'content': content,
      'index': nextIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. ÉP TRUYỆN NHẢY LÊN ĐẦU TRANG CHỦ "MỚI CẬP NHẬT"
    await _firestore.collection('books').doc(bookId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 4. GỬI THÔNG BÁO CHO NHỮNG NGƯỜI ĐÃ LƯU TRUYỆN
    final usersSnapshot = await _firestore.collection('users').get();
    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;

      final libraryDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('library')
          .doc(bookId)
          .get();

      if (libraryDoc.exists) {
        final notiRef = _firestore.collection('users').doc(userId).collection('notifications').doc();
        batch.set(notiRef, {
          'title': 'Chương mới: $bookTitle 🎉',
          'body': 'Chương $nextIndex: $title vừa lên sóng.',
          'type': 'new_chapter',
          'bookId': bookId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        count++;
        if (count % 495 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }
    }
    if (count % 495 != 0) await batch.commit();

    // 5. Cập nhật bộ đếm
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
      // KHÔNG cập nhật 'updatedAt' của truyện ở đây để tránh làm xáo trộn bảng xếp hạng khi chỉ sửa lỗi chính tả
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

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).set({
        'totalPublishedChapters': FieldValue.increment(-1)
      }, SetOptions(merge: true));
    }
  }
}