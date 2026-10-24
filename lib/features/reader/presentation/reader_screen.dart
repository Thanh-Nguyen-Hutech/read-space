import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/reader_providers.dart';
import 'package:intl/intl.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int initialIndex;
  const ReaderScreen({super.key, required this.bookId, this.initialIndex = 0});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> with WidgetsBindingObserver {
  double _fontSize = 18.0;
  late final PageController _pageController;
  late int _currentPage;

  // Khai báo biến đếm thời gian
  Timer? _readingTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: _currentPage);

    // Đăng ký theo dõi vòng đời ứng dụng & bắt đầu đếm giờ
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    // Hủy bộ đếm và observer khi thoát màn hình
    WidgetsBinding.instance.removeObserver(this);
    _readingTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Lắng nghe trạng thái: Tạm dừng đếm khi ẩn app (ra Home, nghe điện thoại...)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _readingTimer?.cancel();
    }
  }

  void _startTimer() {
    _readingTimer?.cancel();
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      if (_secondsElapsed >= 60) {
        _secondsElapsed = 0;
        _incrementReadingMinute();
      }
    });
  }

  Future<void> _incrementReadingMinute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'totalReadingMinutes': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Lỗi cập nhật thời gian đọc: $e');
    }
  }

  void _goToChapter(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  quill.QuillController _initReaderController(String rawContent) {
    try {
      final decoded = jsonDecode(rawContent);
      return quill.QuillController(
        document: quill.Document.fromJson(decoded),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      // Fix crash thiếu \n của các truyện cũ
      String safeText = rawContent.isEmpty ? '\n' : rawContent;
      if (!safeText.endsWith('\n')) safeText += '\n';

      final doc = quill.Document()..insert(0, safeText);
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chaptersAsync = ref.watch(chaptersProvider(widget.bookId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đọc truyện', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease_rounded),
            tooltip: 'Thu nhỏ chữ',
            onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(12.0, 32.0)),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase_rounded),
            tooltip: 'Phóng to chữ',
            onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(12.0, 32.0)),
          ),
        ],
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Lỗi tải nội dung: $e')),
        data: (chapters) {
          if (chapters.isEmpty) {
            return const Center(child: Text('Truyện chưa có nội dung.'));
          }

          return PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              final readController = _initReaderController(chapter.content);

              // Sử dụng Column + Expanded để chống crash chiều cao
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      chapter.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary
                      ),
                    ),
                  ),

                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: 1.8,
                        color: theme.colorScheme.onSurface,
                      ),
                      child: IgnorePointer(
                        ignoring: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: quill.QuillEditor.basic(
                            controller: readController,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Đã đăng lúc: ${DateFormat('HH:mm - dd/MM/yyyy').format(chapter.createdAt)}',
                        style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: chaptersAsync.hasValue && chaptersAsync.value!.isNotEmpty
          ? BottomAppBar(
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _currentPage > 0 ? () => _goToChapter(_currentPage - 1) : null,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
              label: const Text('Chương trước'),
            ),
            IconButton(
              icon: const Icon(Icons.menu_book_rounded),
              color: theme.colorScheme.primary,
              tooltip: 'Mục lục',
              onPressed: () {
                final chapters = chaptersAsync.value!;
                showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
                    ),
                    builder: (context) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final isCurrent = _currentPage == index;
                          return ListTile(
                            leading: Text('${index + 1}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            title: Text(
                              chapters[index].title,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? theme.colorScheme.primary : null,
                              ),
                            ),
                            trailing: isCurrent ? Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20) : null,
                            onTap: () {
                              Navigator.pop(context);
                              _goToChapter(index);
                            },
                          );
                        },
                      );
                    }
                );
              },
            ),
            TextButton(
              onPressed: _currentPage < chaptersAsync.value!.length - 1
                  ? () => _goToChapter(_currentPage + 1)
                  : null,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Chương sau'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
          ],
        ),
      )
          : null,
    );
  }
}