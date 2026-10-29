import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. Quản lý trạng thái bộ lọc tài khoản
final adminUserSearchProvider = StateProvider.autoDispose<String>((ref) => '');
final adminUserRoleFilterProvider = StateProvider.autoDispose<String>((ref) => 'Tất cả');

// 2. Lắng nghe danh sách User Realtime
final adminUsersStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => {
    'uid': doc.id,
    ...doc.data(),
  }).toList());
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  // Cập nhật phân quyền
  Future<void> _updateUserRole(BuildContext context, String uid, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': newRole});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật quyền thành: $newRole')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  // Khóa tài khoản (Thực tế là thêm trường isBanned hoặc đổi role thành banned)
  void _confirmBanUser(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khóa tài khoản'),
        content: Text('Bạn có chắc chắn muốn khóa tài khoản "$name"? Người này sẽ không thể đăng nhập hoặc thao tác trên ứng dụng.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'banned'});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Khóa ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersStreamProvider);
    final searchQuery = ref.watch(adminUserSearchProvider);
    final roleFilter = ref.watch(adminUserRoleFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 3. Khung Tìm kiếm & Lọc
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, email...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) => ref.read(adminUserSearchProvider.notifier).state = value,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: roleFilter,
                      items: ['Tất cả', 'user', 'admin', 'banned']
                          .map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase())))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) ref.read(adminUserRoleFilterProvider.notifier).state = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 4. Danh sách Tài khoản
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
              data: (users) {
                // Lọc Client-side
                final filteredUsers = users.where((user) {
                  final name = (user['name'] ?? '').toString().toLowerCase();
                  final email = (user['email'] ?? '').toString().toLowerCase();
                  final role = user['role'] ?? 'user';

                  final matchesSearch = name.contains(searchQuery.toLowerCase()) || email.contains(searchQuery.toLowerCase());
                  final matchesRole = roleFilter == 'Tất cả' || role == roleFilter;

                  return matchesSearch && matchesRole;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('Không tìm thấy tài khoản nào phù hợp.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final role = user['role'] ?? 'user';

                    Color roleColor = Colors.grey;
                    if (role == 'admin') roleColor = Colors.blue;
                    else if (role == 'banned') roleColor = Colors.red;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
                          child: user['avatar'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(user['name'] ?? 'Ẩn danh', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'Không có email'),
                            Text('Quyền: ${role.toUpperCase()}', style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'ban') {
                              _confirmBanUser(context, user['uid'], user['name'] ?? 'người dùng này');
                            } else {
                              _updateUserRole(context, user['uid'], value);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'user', child: Text('Cấp quyền User (Mặc định)')),
                            const PopupMenuItem(value: 'admin', child: Text('Cấp quyền Admin', style: TextStyle(color: Colors.blue))),
                            const PopupMenuDivider(),
                            const PopupMenuItem(value: 'ban', child: Text('Khóa tài khoản (Ban)', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}