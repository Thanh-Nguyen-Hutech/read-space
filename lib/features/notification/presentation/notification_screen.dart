import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';

final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final userNotificationsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  Future<void> _markAsRead(String notiId, String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notiId)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Lỗi tải thông báo: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('Bạn chưa có thông báo nào.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final noti = notifications[index];
              final isRead = noti['isRead'] ?? false;
              final timestamp = noti['createdAt'] as Timestamp?;

              // Đã gỡ bỏ Container và sử dụng tileColor trực tiếp trong ListTile
              return ListTile(
                tileColor: isRead ? Colors.transparent : Colors.blue.withOpacity(0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                      child: Icon(
                        noti['type'] == 'system' ? Icons.campaign_rounded : Icons.notifications_rounded,
                        color: isRead ? Colors.grey : Colors.blue,
                      ),
                    ),
                    if (!isRead)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  noti['title'] ?? 'Không có tiêu đề',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: isRead ? Colors.black87 : Colors.black,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      noti['body'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isRead ? Colors.grey.shade600 : Colors.black87,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (timestamp != null)
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate()),
                        style: TextStyle(fontSize: 12, color: isRead ? Colors.grey.shade500 : Colors.blue.shade700),
                      ),
                  ],
                ),
                onTap: () {
                  if (!isRead && user != null) {
                    _markAsRead(noti['id'], user.uid);
                  }

                  if (noti['bookId'] != null) {
                    context.push('/book/${noti['bookId']}');
                  } else {
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text(noti['title'] ?? ''),
                        content: Text(noti['body'] ?? ''),
                        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Đóng'))],
                      ),
                    );
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