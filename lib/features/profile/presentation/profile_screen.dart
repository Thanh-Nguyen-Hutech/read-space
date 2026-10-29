import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_repository.dart';
import '../../library/data/library_provider.dart';
import '../../../core/theme/theme_provider.dart';

// Provider lắng nghe luồng dữ liệu realtime của User hiện tại từ Firestore
final userProfileStreamProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.data());
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final savedBooksCount = ref.watch(libraryProvider).maybeWhen(data: (books) => books.length, orElse: () => 0);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    // Lắng nghe dữ liệu profile động
    final userProfileAsync = user != null
        ? ref.watch(userProfileStreamProvider(user.uid))
        : const AsyncValue.loading();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            // HEADER: THÔNG TIN TÀI KHOẢN & MỨC VIP (DYNAMIC)
            // ==========================================
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
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

                  Text(
                    user?.displayName ?? user?.email ?? 'Người dùng',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Dữ liệu Realtime từ Firestore
                  userProfileAsync.when(
                    data: (userData) {
                      if (userData == null) return const SizedBox();

                      final tierId = userData['tierId'] ?? 'bronze';
                      final readMins = userData['totalReadingMinutes'] ?? 0;
                      final posts = userData['totalPublishedChapters'] ?? 0;

                      return Column(
                        children: [
                          // Badge Hạng Thành Viên
                          _buildTierBadge(tierId),
                          const SizedBox(height: 24),

                          // Thống kê thành tích
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCard(theme, 'Số phút đọc', '$readMins phút', Icons.timer_rounded, Colors.blue),
                              _buildStatCard(theme, 'Đã xuất bản', '$posts chương', Icons.edit_document, Colors.green),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Lỗi tải dữ liệu: $e'),
                  ),

                  const SizedBox(height: 24),
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
            // ADMIN DASHBOARD (CHỈ HIỂN THỊ KHI ROLE LÀ ADMIN)
            // ==========================================
            if (userProfileAsync.value != null && userProfileAsync.value!['role'] == 'admin') ...[
              _buildSectionTitle(theme, 'Quản trị hệ thống'),
              _buildMenuItem(
                context,
                icon: Icons.admin_panel_settings_rounded,
                iconColor: Colors.red,
                title: 'Bảng điều khiển Admin',
                subtitle: 'Thống kê, Kiểm duyệt, Người dùng',
                onTap: () => context.push('/admin'),
              ),
              const Divider(height: 32),
            ],

            // ==========================================
            // SECTION 1: QUẢN LÝ NỘI DUNG (HOẠT ĐỘNG)
            // ==========================================
            _buildSectionTitle(theme, 'Hoạt động của tôi'),
            _buildMenuItem(
              context,
              icon: Icons.history_edu_rounded,
              iconColor: Colors.blue,
              title: 'Lịch sử đăng bài',
              subtitle: 'Quản lý tác phẩm của tôi',
              onTap: () => context.push('/my-works'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.bookmark_rounded,
              iconColor: Colors.purple,
              title: 'Thư viện sách đã lưu',
              subtitle: '$savedBooksCount cuốn sách',
              onTap: () {
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
              subtitle: 'Tắt/bật thông báo đẩy',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) {
                    bool pushEnabled = userProfileAsync.value?['pushEnabled'] ?? true;

                    return StatefulBuilder(
                        builder: (context, setModalState) {
                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Cài đặt Thông báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: const Text('Nhận thông báo đẩy (Push Notifications)'),
                                  subtitle: const Text('Cập nhật truyện mới, bình luận và thông báo từ hệ thống.'),
                                  value: pushEnabled,
                                  activeColor: Theme.of(context).colorScheme.primary,
                                  onChanged: (value) async {
                                    setModalState(() => pushEnabled = value);
                                    if (user != null) {
                                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                        'pushEnabled': value,
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                                  child: const Text('Hoàn tất'),
                                )
                              ],
                            ),
                          );
                        }
                    );
                  },
                );
              },
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
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // Tiện ích hiển thị Thẻ trạng thái (Stats)
  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  // Tiện ích hiển thị Badge Hạng thành viên
  Widget _buildTierBadge(String tierId) {
    String tierName = 'Đồng';
    List<Color> gradientColors = [Colors.brown.shade300, Colors.brown.shade400];

    if (tierId == 'silver') {
      tierName = 'Bạc';
      gradientColors = [Colors.grey.shade400, Colors.grey.shade600];
    } else if (tierId == 'gold') {
      tierName = 'Vàng';
      gradientColors = [const Color(0xFFFFD700), const Color(0xFFFFA500)];
    } else if (tierId == 'diamond') {
      tierName = 'Kim Cương';
      gradientColors = [Colors.blue.shade300, Colors.blue.shade600];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: gradientColors.last.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text('Thành viên $tierName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

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