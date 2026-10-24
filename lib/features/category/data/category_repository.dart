import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/category_model.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(FirebaseFirestore.instance);
});

class CategoryRepository {
  final FirebaseFirestore _firestore;
  CategoryRepository(this._firestore);

  // Thêm mới danh mục (Admin) - Ép ID thành chuỗi không dấu tĩnh (ví dụ: tien-hiep)
  Future<void> addCategory(String id, String name) async {
    await _firestore.collection('categories').doc(id).set({
      'name': name,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Cập nhật trạng thái Ẩn/Hiện (Admin)
  Future<void> toggleCategoryStatus(String id, bool isActive) async {
    await _firestore.collection('categories').doc(id).update({
      'isActive': isActive,
    });
  }

  // Xóa danh mục (Admin)
  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }
}

// Provider lắng nghe luồng danh mục hiển thị cho User (Chỉ lấy mục isActive = true)
final activeCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('categories')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
      .toList());
});