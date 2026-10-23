import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/book_model.dart';

// Provider cung cấp instance của Firebase Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Provider chuyên fetch danh sách sách từ Firestore (Bất đồng bộ)
final booksProvider = FutureProvider<List<Book>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  // Truy vấn Collection 'books' trên Firestore
  final snapshot = await firestore.collection('books').get();

  // Chuyển đổi danh sách Document thành danh sách Book
  return snapshot.docs.map((doc) {
    return Book.fromMap(doc.data(), doc.id);
  }).toList();
});