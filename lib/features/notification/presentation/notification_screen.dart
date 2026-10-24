import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/notification_model.dart';

// Lắng nghe danh sách thông báo realtime
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
      .toList());
});

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notiAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Đánh dấu đã đọc tất cả',
            onPressed: () {
              // TODO: Viết hàm update isRead = true cho toàn bộ sub-collection
            },
          )
        ],
      ),
      body: notiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('Bạn không có thông báo nào.'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final noti = notifications[index];
              return ListTile(
                tileColor: noti.isRead ? null : Colors.blue.withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor: noti.type == 'system' ? Colors.orange : Colors.green,
                  child: Icon(
                    noti.type == 'new_chapter' ? Icons.menu_book_rounded : Icons.info_rounded,
                    color: Colors.white,
                  ),
                ),
                title: Text(noti.title, style: TextStyle(fontWeight: noti.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(noti.body),
                onTap: () {
                  // Đánh dấu đã đọc
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(ref.read(firebaseAuthProvider).currentUser!.uid)
                      .collection('notifications')
                      .doc(noti.id)
                      .update({'isRead': true});

                  // Chuyển hướng nếu là thông báo truyện
                  if (noti.type == 'new_chapter' && noti.referenceId != null) {
                    context.push('/book/${noti.referenceId}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}