import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import '../../home/data/home_providers.dart';
import '../../reader/data/reader_providers.dart';
import '../data/studio_repository.dart';

class AddChapterScreen extends ConsumerStatefulWidget {
  final String bookId;

  const AddChapterScreen({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<AddChapterScreen> createState() => _AddChapterScreenState();
}

class _AddChapterScreenState extends ConsumerState<AddChapterScreen> {
  final _titleController = TextEditingController();
  final _quillController = quill.QuillController.basic();
  bool _isLoading = false;

  Future<void> _handleUpload() async {
    if (_titleController.text.trim().isEmpty || _quillController.document.isEmpty()) return;

    setState(() => _isLoading = true);
    try {
      final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

      // Không cần truyền bookTitle từ UI nữa
      await ref.read(studioRepositoryProvider).addChapter(
        bookId: widget.bookId,
        title: _titleController.text.trim(),
        content: contentJson,
      );

      ref.invalidate(chaptersProvider(widget.bookId));
      ref.invalidate(newBooksProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm chương mới'),
        actions: [
          _isLoading
              ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())
              : TextButton(onPressed: _handleUpload, child: const Text('XUẤT BẢN', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Tên chương...', border: InputBorder.none),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const Divider(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: quill.QuillSimpleToolbar(controller: _quillController),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: quill.QuillEditor.basic(controller: _quillController),
            ),
          ),
        ],
      ),
    );
  }
}