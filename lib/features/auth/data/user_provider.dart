import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import '../../home/data/home_providers.dart';

// 1. Định nghĩa cấu trúc User đầy đủ
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? avatar;
  final String role;

  UserModel({required this.uid, required this.email, required this.name, this.avatar, required this.role});

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? 'Ẩn danh',
      avatar: map['avatar'],
      role: map['role'] ?? 'user',
    );
  }
}

// 2. Provider lấy thông tin của CHÍNH MÌNH (dùng cho phân quyền Admin)
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(null);

  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('users').doc(user.uid).snapshots().map((doc) {
    if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
    return null;
  });
});

// 3. THÊM MỚI: Provider lấy thông tin của NGƯỜI KHÁC thông qua UID (dùng để update bình luận)
final userProfileByIdProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('users').doc(uid).snapshots().map((doc) {
    if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
    return null;
  });
});