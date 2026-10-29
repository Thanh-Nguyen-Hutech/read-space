import 'package:cloud_firestore/cloud_firestore.dart';

class Chapter {
  final String id;
  final String bookId;
  final String title;
  final String content;
  final int index;
  final DateTime createdAt; // Sử dụng DateTime thay vì String

  Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.content,
    required this.index,
    required this.createdAt,
  });

  factory Chapter.fromMap(Map<String, dynamic> map, String docId) {
    return Chapter(
      id: docId,
      bookId: map['bookId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      index: map['index']?.toInt() ?? 0,
      // SỬA LỖI TẠI ĐÂY: Ép kiểu an toàn từ Timestamp của Firestore sang DateTime của Dart
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'title': title,
      'content': content,
      'index': index,
      // Giữ nguyên khi ghi lên Firebase (nên dùng FieldValue.serverTimestamp() ở Repository)
      'createdAt': createdAt,
    };
  }
}