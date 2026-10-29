import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final adminCategoriesStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('categories')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {
    'id': doc.id,
    ...doc.data(),
  }).toList());
});

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hiển thị Popup Thêm hoặc Sửa thể loại
  void _showCategoryDialog(BuildContext context, [Map<String, dynamic>? category]) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: isEdit ? category['name'] : '');
    final idController = TextEditingController(text: isEdit ? category['id'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Sửa thể loại' : 'Thêm thể loại mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                enabled: !isEdit, // Chỉ cho nhập ID khi tạo mới (vd: tien-hiep)
                decoration: const InputDecoration(labelText: 'Mã thể loại (ID)', hintText: 'VD: tien-hiep, lang-man'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên hiển thị', hintText: 'VD: Tiên hiệp, Lãng mạn'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final id = idController.text.trim();
                final name = nameController.text.trim();

                if (id.isEmpty || name.isEmpty) return;

                if (isEdit) {
                  // Cập nhật
                  await _firestore.collection('categories').doc(category['id']).update({'name': name});
                } else {
                  // Thêm mới
                  await _firestore.collection('categories').doc(id).set({'name': name, 'isActive': true});
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa thể loại "$name" không? Các truyện thuộc thể loại này sẽ bị ảnh hưởng.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _firestore.collection('categories').doc(id).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Thể loại', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showCategoryDialog(context),
            tooltip: 'Thêm thể loại',
          )
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi tải dữ liệu: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Chưa có thể loại nào. Hãy thêm mới!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.category_rounded),
                  ),
                  title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ID: ${cat['id']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                        onPressed: () => _showCategoryDialog(context, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.red),
                        onPressed: () => _confirmDelete(context, cat['id'], cat['name']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
      ),
    );
  }
}