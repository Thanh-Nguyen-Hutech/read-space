import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../home/data/home_providers.dart';
import '../../home/domain/book_model.dart';
import '../../auth/data/auth_repository.dart';

// Provider chỉ lấy sách của chính mình
final myWorksProvider = FutureProvider<List<Book>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return [];

  final snapshot = await firestore
      .collection('books')
      .where('authorId', isEqualTo: user.uid)
      .get();

  return snapshot.docs.map((doc) => Book.fromMap(doc.data(), doc.id)).toList();
});

class MyWorksScreen extends ConsumerWidget {
  const MyWorksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWorksAsync = ref.watch(myWorksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tác phẩm của tôi')),
      body: myWorksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Lỗi: $e')),
        data: (books) {
          if (books.isEmpty) {
            return const Center(child: Text('Bạn chưa xuất bản tác phẩm nào.'));
          }
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: Image.network(book.coverUrl, width: 50, height: 70, fit: BoxFit.cover),
                title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Đánh giá: ${book.rating} ⭐'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/book/${book.id}'),
              );
            },
          );
        },
      ),
    );
  }
}