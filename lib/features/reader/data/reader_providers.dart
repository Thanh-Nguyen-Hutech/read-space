import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/home_providers.dart';
import '../../studio/domain/chapter_model.dart';


final chaptersProvider = FutureProvider.family<List<Chapter>, String>((ref, bookId) async {
  final firestore = ref.watch(firestoreProvider);

  final snapshot = await firestore
      .collection('books')
      .doc(bookId)
      .collection('chapters')
      .orderBy('index')
      .get();

  return snapshot.docs.map((doc) => Chapter.fromMap(doc.data(), doc.id)).toList();
});