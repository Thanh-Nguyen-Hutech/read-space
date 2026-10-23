import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../reviews/data/review_providers.dart';
import '../../reviews/domain/comment_model.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myCommentsAsync = ref.watch(myCommentsHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bình luận & Đánh giá')),
      body: myCommentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Lỗi truy xuất: $e\n\n(Lưu ý: Nếu lỗi Index, hãy mở Debug Console trên máy tính và bấm vào đường link Firebase cung cấp để tạo Index)', textAlign: TextAlign.center),
        )),
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('Bạn chưa có bình luận nào.'));

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final bookId = item['bookId'] as String;
              final comment = item['comment'] as CommentModel;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.comment_rounded, color: Colors.blue),
                ),
                title: Text(comment.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('HH:mm - dd/MM/yyyy').format(comment.createdAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                onTap: () {
                  // Bấm vào bình luận sẽ dẫn thẳng tới cuốn sách đó
                  context.push('/book/$bookId');
                },
              );
            },
          );
        },
      ),
    );
  }
}