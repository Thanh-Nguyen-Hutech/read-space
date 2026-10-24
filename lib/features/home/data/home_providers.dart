import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../domain/book_model.dart';

// Provider cung cấp instance của Firebase Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ==========================================
// 1. PROVIDER CHO TRANG CHỦ (HOME SCREEN)
// ==========================================

// Sách mới đăng tải (Sắp xếp theo ngày tạo mới nhất)
final newBooksProvider = FutureProvider<List<Book>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = await firestore
      .collection('books')
      .where('status', isEqualTo: 'Đang ra')
      .orderBy('createdAt', descending: true)
      .limit(10)
      .get();

  return snapshot.docs.map((doc) => Book.fromMap(doc.data(), doc.id)).toList();
});

// Sách Hot mọi thời đại (Sắp xếp theo điểm đánh giá)
final hotAllTimeBooksProvider = FutureProvider<List<Book>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = await firestore
      .collection('books')
      .orderBy('rating', descending: true)
      .limit(10)
      .get();

  return snapshot.docs.map((doc) => Book.fromMap(doc.data(), doc.id)).toList();
});

// Provider fetch tất cả sách (Dùng cho dự phòng hoặc quản trị)
final booksProvider = FutureProvider<List<Book>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = await firestore.collection('books').get();
  return snapshot.docs.map((doc) => Book.fromMap(doc.data(), doc.id)).toList();
});

// ==========================================
// 2. PROVIDER CHO TAB KHÁM PHÁ (EXPLORE SCREEN)
// ==========================================

// Các State lưu trữ trạng thái bộ lọc của người dùng
final searchFilterProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<String>((ref) => 'all');
final timeFilterProvider = StateProvider<String>((ref) => 'newest');

// Luồng kết hợp đa bộ lọc: Thể loại + Thời gian + Từ khóa
final exploreBooksProvider = FutureProvider<List<Book>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final category = ref.watch(categoryFilterProvider);
  final timeFilter = ref.watch(timeFilterProvider);
  final searchQuery = ref.watch(searchFilterProvider).toLowerCase().trim();

  // Khởi tạo truy vấn gốc
  Query query = firestore.collection('books');

  // Lọc theo thể loại (Dùng arrayContains vì categoryIds là mảng)
  if (category != 'all') {
    query = query.where('categoryIds', arrayContains: category);
  }

  // Lọc theo trạng thái hoặc sắp xếp thời gian
  if (timeFilter == 'completed') {
    query = query.where('status', isEqualTo: 'Hoàn thành');
  } else {
    query = query.orderBy('createdAt', descending: true);
  }

  // Lấy dữ liệu từ Firestore
  final snapshot = await query.get();
  var books = snapshot.docs.map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

  // Lọc tìm kiếm theo từ khóa ở Client-side (Tìm trong Tên truyện hoặc Tên tác giả)
  if (searchQuery.isNotEmpty) {
    books = books.where((book) {
      final titleMatch = book.title.toLowerCase().contains(searchQuery);
      final authorMatch = book.author.toLowerCase().contains(searchQuery);
      return titleMatch || authorMatch;
    }).toList();
  }

  return books;
});