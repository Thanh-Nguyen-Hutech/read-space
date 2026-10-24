import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'system', 'admin', 'new_chapter'
  final String? referenceId; // Chứa bookId nếu là thông báo chương mới để bấm vào đọc ngay
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'system',
      referenceId: map['referenceId'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}