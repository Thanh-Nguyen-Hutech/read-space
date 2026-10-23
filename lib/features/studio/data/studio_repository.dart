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
  }) async {
    final url = Uri.parse('https://api.imgbb.com/1/upload');
    final request = http.MultipartRequest('POST', url);

    request.fields['key'] = imgbbApiKey;
    request.files.add(await http.MultipartFile.fromPath('image', coverImage.path));

    // 2. THỰC THI GỬI ẢNH VÀ CHỜ KẾT QUẢ
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonMap = json.decode(responseData);

    if (jsonMap['success'] == true) {
      // Lấy đường link URL của ảnh vừa được ImgBB lưu trữ
      final coverUrl = jsonMap['data']['url'];

      // 3. TẠO OBJECT BOOK VÀ LƯU VÀO FIRESTORE
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

      await newBookRef.set(newBook.toMap());
    } else {
      throw Exception('Lỗi upload ảnh lên ImgBB: ${jsonMap['error']['message']}');
    }
  }

  Future<void> addChapter({
    required String bookId,
    required String title,
    required String content,
  }) async {
    // Trỏ vào sub-collection 'chapters' của cuốn sách đó
    final chaptersRef = _firestore.collection('books').doc(bookId).collection('chapters');

    // Đếm số lượng chương hiện tại để đánh số thứ tự (index) tự động
    final snapshot = await chaptersRef.get();
    final nextIndex = snapshot.docs.length + 1;

    final newChapterRef = chaptersRef.doc();
    final newChapter = Chapter(
      id: newChapterRef.id,
      bookId: bookId,
      title: title,
      content: content,
      index: nextIndex,
      createdAt: DateTime.now(),
    );

    await newChapterRef.set(newChapter.toMap());
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
  }
}