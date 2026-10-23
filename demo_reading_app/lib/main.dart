import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

void main() {
  runApp(const MangaAppDemo());
}

// ============================================================
// APP
// ============================================================

class MangaAppDemo extends StatelessWidget {
  const MangaAppDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Truyện Online',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),

      home: const MainScreen(),
    );
  }
}

// ============================================================
// MAIN SCREEN
// ============================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Số thông báo chưa đọc
  int _notificationCount = 3;

  final List<Widget> _pages = const [
    HomePage(),
    DiscoverPage(),
    AddPage(),
    NotificationPage(),
    ProfilePage(),
  ];

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;

      // Khi mở trang thông báo -> đánh dấu đã đọc
      if (index == 3) {
        _notificationCount = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        title: const Text(
          'Ứng Dụng Đọc Truyện',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: false,

        backgroundColor: Colors.indigo,

        foregroundColor: Colors.white,

        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _currentIndex = 1;
              });
            },
          ),

          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              _showMessage(
                context,
                'Mở phần cài đặt',
              );
            },
          ),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // ======================================================
      // CONVEX BOTTOM BAR
      // ======================================================

      bottomNavigationBar: ConvexAppBar.badge(
        // Badge của tab Thông báo
        {
          if (_notificationCount > 0)
            3: _notificationCount > 99
                ? '99+'
                : _notificationCount.toString(),
        },

        // ----------------------------------------------------
        // ITEMS
        // ----------------------------------------------------

        items: const [
          TabItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            title: 'Trang chủ',
          ),

          TabItem(
            icon: Icons.search_outlined,
            activeIcon: Icons.search,
            title: 'Khám phá',
          ),

          TabItem(
            icon: Icons.add,
            activeIcon: Icons.add,
            title: 'Thêm',
          ),

          TabItem(
            icon: Icons.notifications_none,
            activeIcon: Icons.notifications,
            title: 'Thông báo',
          ),

          TabItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            title: 'Tài khoản',
          ),
        ],

        // ----------------------------------------------------
        // STYLE
        // ----------------------------------------------------

        style: TabStyle.reactCircle,

        // ----------------------------------------------------
        // COLOR
        // ----------------------------------------------------

        gradient: const LinearGradient(
          colors: [
            Colors.indigo,
            Colors.deepPurple,
          ],
        ),

        color: Colors.white60,

        activeColor: Colors.white,

        // ----------------------------------------------------
        // CONVEX CONFIG
        // ----------------------------------------------------

        height: 60,

        curveSize: 90,

        top: -20,

        // ----------------------------------------------------
        // SHADOW
        // ----------------------------------------------------

        elevation: 8,

        shadowColor: Colors.black45,

        // ----------------------------------------------------
        // ACTIVE TAB
        // ----------------------------------------------------

        initialActiveIndex: _currentIndex,

        // ----------------------------------------------------
        // TAP
        // ----------------------------------------------------

        onTap: _changePage,
      ),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // --------------------------------------------------
          // WELCOME
          // --------------------------------------------------

          const Text(
            'Xin chào 👋',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Hôm nay đọc gì?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // --------------------------------------------------
          // SEARCH
          // --------------------------------------------------

          _SearchBox(
            hintText: 'Tìm kiếm truyện...',
            onTap: () {
              // Demo
            },
          ),

          const SizedBox(height: 25),

          // --------------------------------------------------
          // FEATURED
          // --------------------------------------------------

          const SectionTitle(
            title: 'Truyện nổi bật',
            icon: Icons.star,
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 190,

            child: ListView(
              scrollDirection: Axis.horizontal,

              children: const [
                FeaturedMangaCard(
                  title: 'One Piece',
                  chapter: 'Chapter 1160',
                  icon: Icons.menu_book,
                ),

                FeaturedMangaCard(
                  title: 'Solo Leveling',
                  chapter: 'Chapter 210',
                  icon: Icons.auto_stories,
                ),

                FeaturedMangaCard(
                  title: 'Naruto',
                  chapter: 'Chapter 700',
                  icon: Icons.book,
                ),

                FeaturedMangaCard(
                  title: 'Demon Slayer',
                  chapter: 'Chapter 205',
                  icon: Icons.library_books,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --------------------------------------------------
          // NEW MANGA
          // --------------------------------------------------

          const SectionTitle(
            title: 'Mới cập nhật',
            icon: Icons.update,
          ),

          const SizedBox(height: 10),

          MangaListItem(
            title: 'One Piece',
            chapter: 'Chapter 1160',
            category: 'Action • Adventure',
            rating: '9.8',
          ),

          MangaListItem(
            title: 'Jujutsu Kaisen',
            chapter: 'Chapter 285',
            category: 'Action • Fantasy',
            rating: '9.5',
          ),

          MangaListItem(
            title: 'Solo Leveling',
            chapter: 'Chapter 210',
            category: 'Action • Fantasy',
            rating: '9.7',
          ),

          MangaListItem(
            title: 'Demon Slayer',
            chapter: 'Chapter 205',
            category: 'Action • Historical',
            rating: '9.6',
          ),

          MangaListItem(
            title: 'Naruto',
            chapter: 'Chapter 700',
            category: 'Action • Ninja',
            rating: '9.4',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DISCOVER PAGE
// ============================================================

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchController =
  TextEditingController();

  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Action',
    'Adventure',
    'Romance',
    'Fantasy',
    'Comedy',
    'Horror',
    'Drama',
    'School',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Khám phá',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Tìm kiếm những bộ truyện yêu thích',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          // SEARCH
          TextField(
            controller: _searchController,

            decoration: InputDecoration(
              hintText: 'Nhập tên truyện...',

              prefixIcon: const Icon(
                Icons.search,
              ),

              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.clear,
                ),

                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),

              filled: true,

              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),

            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 25),

          // CATEGORY
          const SectionTitle(
            title: 'Thể loại',
            icon: Icons.category,
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children: _categories.map((category) {
              final bool selected =
                  _selectedCategory == category;

              return ChoiceChip(
                label: Text(category),

                selected: selected,

                selectedColor: Colors.indigo,

                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.black87,
                ),

                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 25),

          // RESULTS
          SectionTitle(
            title: _searchController.text.isEmpty
                ? 'Đề xuất cho bạn'
                : 'Kết quả tìm kiếm',

            icon: Icons.recommend,
          ),

          const SizedBox(height: 10),

          MangaListItem(
            title: 'One Piece',
            chapter: 'Chapter 1160',
            category: 'Action • Adventure',
            rating: '9.8',
          ),

          MangaListItem(
            title: 'Solo Leveling',
            chapter: 'Chapter 210',
            category: 'Action • Fantasy',
            rating: '9.7',
          ),

          MangaListItem(
            title: 'Jujutsu Kaisen',
            chapter: 'Chapter 285',
            category: 'Action • Fantasy',
            rating: '9.5',
          ),

          MangaListItem(
            title: 'Demon Slayer',
            chapter: 'Chapter 205',
            category: 'Action • Drama',
            rating: '9.6',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD PAGE
// ============================================================

class AddPage extends StatelessWidget {
  const AddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // ICON
            Container(
              width: 110,
              height: 110,

              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.add_circle,
                size: 80,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Trung tâm',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Quản lý và thêm nội dung',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            // ADD BOOK
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () {
                  _showDialog(
                    context,
                    'Thêm truyện',
                    'Chức năng thêm truyện sẽ được phát triển sau.',
                  );
                },

                icon: const Icon(
                  Icons.book,
                ),

                label: const Text(
                  'Thêm truyện',
                ),

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // UPLOAD
            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () {
                  _showDialog(
                    context,
                    'Đăng truyện',
                    'Chức năng đăng truyện sẽ được phát triển sau.',
                  );
                },

                icon: const Icon(
                  Icons.upload,
                ),

                label: const Text(
                  'Đăng truyện',
                ),

                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // HISTORY
            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () {
                  _showDialog(
                    context,
                    'Lịch sử',
                    'Xem lịch sử hoạt động.',
                  );
                },

                icon: const Icon(
                  Icons.history,
                ),

                label: const Text(
                  'Lịch sử hoạt động',
                ),

                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showDialog(
      BuildContext context,
      String title,
      String message,
      ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Text(title),

          content: Text(message),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// NOTIFICATION PAGE
// ============================================================

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),

      children: [
        const Text(
          'Thông báo',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Cập nhật mới nhất từ thư viện truyện',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 20),

        NotificationItem(
          title: 'One Piece có chương mới',
          message:
          'Chapter 1160 vừa được cập nhật.',
          time: '5 phút trước',
          icon: Icons.menu_book,
          unread: true,
        ),

        NotificationItem(
          title: 'Solo Leveling có chương mới',
          message:
          'Chapter 210 đã được phát hành.',
          time: '2 giờ trước',
          icon: Icons.auto_stories,
          unread: true,
        ),

        NotificationItem(
          title: 'Jujutsu Kaisen',
          message:
          'Chapter 285 vừa được cập nhật.',
          time: 'Hôm qua',
          icon: Icons.book,
          unread: true,
        ),

        NotificationItem(
          title: 'Chào mừng bạn!',
          message:
          'Cảm ơn bạn đã sử dụng ứng dụng.',
          time: '2 ngày trước',
          icon: Icons.favorite,
          unread: false,
        ),

        NotificationItem(
          title: 'Bảo trì hệ thống',
          message:
          'Hệ thống đã được cập nhật.',
          time: '5 ngày trước',
          icon: Icons.settings,
          unread: false,
        ),
      ],
    );
  }
}

// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [
          const SizedBox(height: 20),

          // AVATAR
          const CircleAvatar(
            radius: 52,

            backgroundColor: Colors.indigo,

            child: Icon(
              Icons.person,
              size: 62,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Người dùng',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'user@example.com',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          // EDIT PROFILE
          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: () {
                _showMessage(
                  context,
                  'Mở chỉnh sửa thông tin cá nhân',
                );
              },

              icon: const Icon(
                Icons.edit,
              ),

              label: const Text(
                'Chỉnh sửa thông tin',
              ),
            ),
          ),

          const SizedBox(height: 20),

          // MENU
          ProfileMenuItem(
            icon: Icons.person_outline,
            title: 'Thông tin cá nhân',
            onTap: () {
              _showMessage(
                context,
                'Thông tin cá nhân',
              );
            },
          ),

          ProfileMenuItem(
            icon: Icons.history,
            title: 'Lịch sử đọc truyện',
            onTap: () {
              _showMessage(
                context,
                'Lịch sử đọc truyện',
              );
            },
          ),

          ProfileMenuItem(
            icon: Icons.bookmark_outline,
            title: 'Truyện đã lưu',
            onTap: () {
              _showMessage(
                context,
                'Truyện đã lưu',
              );
            },
          ),

          ProfileMenuItem(
            icon: Icons.settings_outlined,
            title: 'Cài đặt',
            onTap: () {
              _showMessage(
                context,
                'Cài đặt',
              );
            },
          ),

          ProfileMenuItem(
            icon: Icons.dark_mode_outlined,
            title: 'Chế độ tối',
            onTap: () {
              _showMessage(
                context,
                'Chế độ tối',
              );
            },
          ),

          ProfileMenuItem(
            icon: Icons.help_outline,
            title: 'Trợ giúp',
            onTap: () {
              _showMessage(
                context,
                'Trợ giúp',
              );
            },
          ),

          ProfileMenuItem(
            icon: Icons.logout,
            title: 'Đăng xuất',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () {
              _showMessage(
                context,
                'Đăng xuất',
              );
            },
          ),
        ],
      ),
    );
  }

  static void _showMessage(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================
// FEATURED MANGA CARD
// ============================================================

class FeaturedMangaCard extends StatelessWidget {
  final String title;
  final String chapter;
  final IconData icon;

  const FeaturedMangaCard({
    super.key,
    required this.title,
    required this.chapter,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,

      margin: const EdgeInsets.only(right: 12),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            Colors.indigo,
            Colors.deepPurple,
          ],
        ),

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              size: 55,
              color: Colors.white,
            ),

            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              chapter,

              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 8),

            const Icon(
              Icons.arrow_forward,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MANGA LIST ITEM
// ============================================================

class MangaListItem extends StatelessWidget {
  final String title;
  final String chapter;
  final String category;
  final String rating;

  const MangaListItem({
    super.key,
    required this.title,
    required this.chapter,
    required this.category,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),

      elevation: 1,

      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.all(10),

        // IMAGE PLACEHOLDER
        leading: Container(
          width: 58,
          height: 70,

          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),

            borderRadius:
            BorderRadius.circular(10),
          ),

          child: const Icon(
            Icons.menu_book,
            color: Colors.indigo,
            size: 30,
          ),
        ),

        // TITLE
        title: Text(
          title,

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        // INFORMATION
        subtitle: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 5),

            Text(
              category,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              chapter,

              style: const TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        // RATING
        trailing: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 18,
            ),

            const SizedBox(height: 3),

            Text(
              rating,

              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        onTap: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                'Mở truyện $title',
              ),

              behavior:
              SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// NOTIFICATION ITEM
// ============================================================

class NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final bool unread;

  const NotificationItem({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      color: unread
          ? Colors.indigo.withOpacity(0.05)
          : Colors.white,

      elevation: unread ? 2 : 1,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        leading: CircleAvatar(
          radius: 25,

          backgroundColor:
          Colors.indigo.withOpacity(0.1),

          child: Icon(
            icon,
            color: Colors.indigo,
          ),
        ),

        title: Text(
          title,

          style: TextStyle(
            fontWeight: unread
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),

        subtitle: Padding(
          padding:
          const EdgeInsets.only(top: 5),

          child: Text(message),
        ),

        trailing: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Text(
              time,

              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),

            if (unread) ...[
              const SizedBox(height: 5),

              Container(
                width: 8,
                height: 8,

                decoration:
                const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE MENU ITEM
// ============================================================

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),

      elevation: 1,

      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      child: ListTile(
        leading: Icon(
          icon,

          color:
          iconColor ?? Colors.indigo,
        ),

        title: Text(
          title,

          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),

        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// SEARCH BOX
// ============================================================

class _SearchBox extends StatelessWidget {
  final String hintText;
  final VoidCallback onTap;

  const _SearchBox({
    required this.hintText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 55,

        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(15),

          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(0.05),

              blurRadius: 8,

              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: Colors.grey,
            ),

            const SizedBox(width: 12),

            Text(
              hintText,

              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.indigo,
          size: 22,
        ),

        const SizedBox(width: 8),

        Text(
          title,

          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Spacer(),

        const Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: Colors.grey,
        ),
      ],
    );
  }
}