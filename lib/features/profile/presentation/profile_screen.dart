import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../library/data/library_provider.dart';
import '../../../core/theme/theme_provider.dart';
import 'my_works_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final savedBooksCount = ref.watch(libraryProvider).length;
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final myWorksAsync = ref.watch(myWorksProvider);
    final myWorksCount = myWorksAsync.maybeWhen(data: (books) => books.length, orElse: () => 0);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt hệ thống',
            onPressed: () => _showComingSoon(context, 'Cài đặt ứng dụng'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==========================================
            // HEADER: THÔNG TIN TÀI KHOẢN & MỨC VIP
            // ==========================================
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  // Avatar có nút chỉnh sửa nhỏ bên cạnh
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null
                            ? Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () => context.push('/edit-profile'),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tên / Email
                  Text(
                    user?.displayName ?? user?.email ?? 'Người dùng',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Mức VIP / Thẻ hạng
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Vàng gradient VIP
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('Thành viên Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút Cập nhật thông tin
                  OutlinedButton.icon(
                    onPressed: () => context.push('/edit-profile'),
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text('Chỉnh sửa thông tin'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // SECTION 1: QUẢN LÝ NỘI DUNG (HOẠT ĐỘNG)
            // ==========================================
            _buildSectionTitle(theme, 'Hoạt động của tôi'),
            _buildMenuItem(
              context,
              icon: Icons.history_edu_rounded,
              iconColor: Colors.blue,
              title: 'Lịch sử đăng bài (Tác phẩm của tôi)',
              subtitle: '$myWorksCount tác phẩm đã đăng tải',
              onTap: () => context.push('/my-works'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.bookmark_rounded,
              iconColor: Colors.purple,
              title: 'Thư viện sách đã lưu',
              subtitle: '$savedBooksCount cuốn sách',
              onTap: () {
                // Điều hướng sang Tab Thư viện (Index 1)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng bấm sang Tab Thư viện bên dưới')));
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.comment_rounded,
              iconColor: Colors.teal,
              title: 'Bình luận & Đánh giá',
              onTap: () => context.push('/my-reviews'),
            ),

            // ==========================================
            // SECTION 2: CÀI ĐẶT & HỖ TRỢ
            // ==========================================
            _buildSectionTitle(theme, 'Cài đặt chung'),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black87.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.dark_mode_rounded, color: Colors.grey, size: 22),
              ),
              title: const Text('Giao diện Tối (Dark Mode)', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: Switch(
                value: isDarkMode,
                activeColor: theme.colorScheme.primary,
                onChanged: (value) {
                  // Kích hoạt hàm đổi theme
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.dark_mode_rounded,
              iconColor: Colors.black87,
              title: 'Giao diện & Hiển thị',
              subtitle: 'Sáng / Tối / Tự động',
              onTap: () => _showComingSoon(context, 'Cài đặt giao diện'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.notifications_active_rounded,
              iconColor: Colors.orange,
              title: 'Cài đặt thông báo',
              onTap: () => _showComingSoon(context, 'Cài đặt thông báo'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.security_rounded,
              iconColor: Colors.green,
              title: 'Bảo mật & Đổi mật khẩu',
              onTap: () => _showComingSoon(context, 'Bảo mật tài khoản'),
            ),

            // ==========================================
            // SECTION 3: ĐĂNG XUẤT
            // ==========================================
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48), // Padding đáy
          ],
        ),
      ),
    );
  }

  // Tiêu đề của từng khu vực (Section Header)
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // Các dòng chức năng (ListTile)
  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Hàm tiện ích hiển thị thông báo "Tính năng đang phát triển"
  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng "$featureName" sẽ được cập nhật ở phiên bản sau!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}