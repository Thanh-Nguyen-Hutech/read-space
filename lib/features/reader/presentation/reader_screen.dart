import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../data/reader_providers.dart';
import 'package:intl/intl.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int initialIndex;
  const ReaderScreen({super.key, required this.bookId, this.initialIndex = 0});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  double _fontSize = 18.0;

  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      final doc = quill.Document()..insert(0, rawContent);
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

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SỬ DỤNG DEFAULT_TEXT_STYLE ĐỂ ÉP MÀU DARK MODE MÀ KHÔNG BỊ LỖI CÚ PHÁP
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: 1.8,
                        color: theme.colorScheme.onSurface, // Tự động trắng/đen theo chế độ
                      ),
                      child: IgnorePointer(
                        ignoring: true, // Chặn mọi thao tác chạm để bàn phím không hiện lên
                        child: quill.QuillEditor.basic(
                          controller: readController,
                          // Đã xóa tham số readOnly: true để sửa triệt để lỗi đỏ
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Đã đăng lúc: ${DateFormat('HH:mm - dd/MM/yyyy').format(chapter.createdAt)}',
                        style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
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