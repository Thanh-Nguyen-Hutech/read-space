import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendGlobalNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung.')));
      return;
    }

    setState(() => _isSending = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final usersSnapshot = await firestore.collection('users').get();

      // Firestore giới hạn 500 thao tác ghi cho mỗi Batch.
      // Ứng dụng quy mô nhỏ có thể dùng 1 batch, nếu nhiều user cần chia nhỏ thành các mảng (chunks).
      WriteBatch batch = firestore.batch();
      int count = 0;
      final uuid = const Uuid().v4(); // Tạo ID chung cho đợt thông báo này

      for (var doc in usersSnapshot.docs) {
        final notiRef = firestore.collection('users').doc(doc.id).collection('notifications').doc(uuid);
        batch.set(notiRef, {
          'id': uuid,
          'title': title,
          'body': body,
          'type': 'system',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        count++;
        // Commit batch nếu đạt giới hạn 500 để tránh lỗi
        if (count % 499 == 0) {
          await batch.commit();
          batch = firestore.batch();
        }
      }

      // Commit những thông báo còn sót lại
      if (count % 499 != 0) {
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã gửi thông báo thành công tới $count người dùng!')));
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi gửi thông báo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phát Thông Báo Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: Colors.blue, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Thông báo bạn tạo tại đây sẽ được gửi trực tiếp vào hòm thư (Tab Thông báo) của tất cả người dùng trên hệ thống.',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Tiêu đề thông báo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'VD: Cập nhật tính năng mới, Bảo trì hệ thống...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Nội dung chi tiết', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung chi tiết bạn muốn truyền đạt...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendGlobalNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSending ? 'Đang gửi thông báo...' : 'Phát Thông Báo Toàn Hệ Thống',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}