import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// THÊM IMPORT NÀY ĐỂ NHẬN firestoreProvider
import '../../home/data/home_providers.dart';

// Cung cấp instance của FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Cung cấp AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider), // Giờ sẽ không bị báo lỗi đỏ nữa
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // CẬP NHẬT: Ghi dữ liệu người dùng (role: 'user') ngay khi đăng ký
  Future<UserCredential> signUp(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Lấy phần trước ký tự '@' của email làm tên mặc định
    final defaultName = email.split('@')[0];
    await userCredential.user?.updateDisplayName(defaultName);
    await userCredential.user?.reload();

    // Ghi dữ liệu phân quyền lên Firestore ngay lập tức
    if (userCredential.user != null) {
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': defaultName,
        'role': 'user', // Mặc định là độc giả
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // CẬP NHẬT: Đồng bộ cập nhật thông tin (Tên, Avatar) sang bảng `users`
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final uid = _auth.currentUser?.uid;

    if (name != null && name.isNotEmpty) {
      await _auth.currentUser?.updateDisplayName(name);
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({'name': name}, SetOptions(merge: true));
      }
    }

    if (photoUrl != null && photoUrl.isNotEmpty) {
      await _auth.currentUser?.updatePhotoURL(photoUrl);
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({'avatar': photoUrl}, SetOptions(merge: true));
      }
    }

    await _auth.currentUser?.reload();
  }
}