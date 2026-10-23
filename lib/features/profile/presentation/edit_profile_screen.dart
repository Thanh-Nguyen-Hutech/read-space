import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';

const String imgbbApiKey = '932115cb13a5250aadc00a1e0762e183';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  File? _avatarFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Lấy tên hiện tại điền sẵn vào ô nhập liệu
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null && user.displayName != null) {
      _nameController.text = user.displayName!;
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      String? newAvatarUrl;

      // Nếu người dùng có chọn ảnh mới -> Up lên ImgBB trước
      if (_avatarFile != null) {
        final url = Uri.parse('https://api.imgbb.com/1/upload');
        final request = http.MultipartRequest('POST', url);
        request.fields['key'] = imgbbApiKey;
        request.files.add(await http.MultipartFile.fromPath('image', _avatarFile!.path));

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final jsonMap = json.decode(responseData);

        if (jsonMap['success'] == true) {
          newAvatarUrl = jsonMap['data']['url'];
        } else {
          throw Exception('Lỗi upload ảnh: ${jsonMap['error']['message']}');
        }
      }

      // Cập nhật Firebase Auth
      await ref.read(authRepositoryProvider).updateProfile(
        name: _nameController.text.trim(),
        photoUrl: newAvatarUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
        // Buộc màn hình Profile tải lại dữ liệu mới
        ref.invalidate(firebaseAuthProvider);
        context.pop(); // Quay về trang trước
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Khu vực đổi Avatar
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: _avatarFile != null
                        ? FileImage(_avatarFile!) as ImageProvider
                        : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
                    child: (_avatarFile == null && user?.photoURL == null)
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Ô nhập tên mới
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị / Bút danh',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 48),

            // Nút Lưu thay đổi
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}