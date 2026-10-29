import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final firestore = FirebaseFirestore.instance;

  // 1. Lấy thống kê cơ bản bằng hàm count() để tiết kiệm chi phí đọc
  final booksSnap = await firestore.collection('books').count().get();
  final usersSnap = await firestore.collection('users').count().get();
  final categoriesSnap = await firestore.collection('categories').count().get();

  final bannedBooksSnap = await firestore.collection('books')
      .where('status', isEqualTo: 'Khóa/Vi phạm')
      .count()
      .get();

  // 2. Lấy dữ liệu lưu lượng truy cập từ collection analytics
  final now = DateTime.now();
  final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  final analyticsDoc = await firestore.collection('analytics').doc('visits').get();
  int totalVisits = 0;
  int todayVisits = 0;

  if (analyticsDoc.exists) {
    final data = analyticsDoc.data()!;
    totalVisits = data['total'] ?? 0;
    todayVisits = data['daily_$today'] ?? 0;
  }

  return {
    'total_books': booksSnap.count ?? 0,
    'total_users': usersSnap.count ?? 0,
    'total_categories': categoriesSnap.count ?? 0,
    'banned_books': bannedBooksSnap.count ?? 0,
    'total_visits': totalVisits,
    'today_visits': todayVisits,
  };
});

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới dữ liệu',
            onPressed: () => ref.invalidate(adminStatsProvider),
          )
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi tải dữ liệu: $err')),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminStatsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BẢNG THEO DÕI LƯU LƯỢNG TRUY CẬP (TRAFFIC)
                  Text('Lưu lượng truy cập', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTrafficCard(
                            theme,
                            'Truy cập hôm nay',
                            stats['today_visits'].toString(),
                            Icons.visibility_rounded,
                            Colors.teal
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTrafficCard(
                            theme,
                            'Tổng lượt truy cập',
                            stats['total_visits'].toString(),
                            Icons.public_rounded,
                            Colors.indigo
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text('Dữ liệu hệ thống', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // LƯỚI THỐNG KÊ CƠ BẢN
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: [
                      _buildStatCard(theme, 'Tổng Số Truyện', stats['total_books'], Icons.menu_book_rounded, Colors.blue),
                      _buildStatCard(theme, 'Người Dùng', stats['total_users'], Icons.people_alt_rounded, Colors.green),
                      _buildStatCard(theme, 'Thể Loại', stats['total_categories'], Icons.category_rounded, Colors.orange),
                      _buildStatCard(theme, 'Truyện Vi Phạm', stats['banned_books'], Icons.gavel_rounded, Colors.red),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.insights_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Biểu đồ doanh thu chi tiết', textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Sẽ được kích hoạt khi có tính năng thanh toán.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrafficCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 16),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.titleSmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value.toString(), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}