import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final adminBannersProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collection('banners')
      .orderBy('createdAt', descending: true)
      .snapshots();
});

class AdminBannersScreen extends ConsumerWidget {
  const AdminBannersScreen({super.key});

  Future<void> _addOrEditBanner(BuildContext context, {String? docId, String? currentImageUrl, String? currentLink}) async {
    final imageUrlController = TextEditingController(text: currentImageUrl);
    final linkController = TextEditingController(text: currentLink);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? 'Thêm Banner mới' : 'Sửa Banner'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Link ảnh (URL)',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value != null && value.trim().isEmpty ? 'Vui lòng nhập link ảnh' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: 'Link điều hướng (Tùy chọn)',
                  hintText: 'https://momo.vn/...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final imageUrl = imageUrlController.text.trim();
                final link = linkController.text.trim();
                final collection = FirebaseFirestore.instance.collection('banners');

                if (docId == null) {
                  await collection.add({
                    'imageUrl': imageUrl,
                    'link': link,
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  await collection.doc(docId).update({
                    'imageUrl': imageUrl,
                    'link': link,
                  });
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBannerStatus(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('banners').doc(docId).update({
      'isActive': !currentStatus,
    });
  }

  Future<void> _deleteBanner(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa Banner?'),
        content: const Text('Banner này sẽ bị xóa vĩnh viễn khỏi hệ thống.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('banners').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminBannersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Quảng cáo / Banner', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditBanner(context),
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Thêm Banner'),
      ),
      body: bannersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(child: Text('Chưa có banner nào. Hãy thêm mới!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isActive = data['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      data['imageUrl'] ?? '',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    ),
                    ListTile(
                      title: Text(
                        data['link'] != null && data['link'].toString().isNotEmpty
                            ? 'Đích đến: ${data['link']}'
                            : 'Không có link điều hướng',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        isActive ? 'Đang hiển thị trên app' : 'Đang ẩn',
                        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isActive,
                            onChanged: (_) => _toggleBannerStatus(doc.id, isActive),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                            onPressed: () => _addOrEditBanner(
                              context,
                              docId: doc.id,
                              currentImageUrl: data['imageUrl'],
                              currentLink: data['link'],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.red),
                            onPressed: () => _deleteBanner(context, doc.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}