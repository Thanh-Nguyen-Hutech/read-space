import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import '../data/studio_repository.dart';
import '../domain/chapter_model.dart';
import '../../reader/data/reader_providers.dart';

class EditChapterScreen extends ConsumerStatefulWidget {
  final String bookId;
  final Chapter chapter;

  const EditChapterScreen({super.key, required this.bookId, required this.chapter});

  @override
  ConsumerState<EditChapterScreen> createState() => _EditChapterScreenState();
}

class _EditChapterScreenState extends ConsumerState<EditChapterScreen> {
  late final TextEditingController _titleController;
  late final quill.QuillController _quillController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.chapter.title);

    try {
      final decoded = jsonDecode(widget.chapter.content);
      _quillController = quill.QuillController(
        document: quill.Document.fromJson(decoded),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      final doc = quill.Document()..insert(0, widget.chapter.content);
      _quillController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateChapter() async {
    if (_titleController.text.isEmpty || _quillController.document.isEmpty()) return;

    setState(() => _isLoading = true);
    try {
      final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

      await ref.read(studioRepositoryProvider).updateChapter(
        bookId: widget.bookId,
        chapterId: widget.chapter.id,
        title: _titleController.text.trim(),
        content: contentJson,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
        ref.invalidate(chaptersProvider(widget.bookId));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa chương'),
        actions: [
          _isLoading
              ? const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())
              : TextButton(onPressed: _handleUpdateChapter, child: const Text('LƯU LẠI')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Tên chương', border: InputBorder.none),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const Divider(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: quill.QuillSimpleToolbar(
              controller: _quillController,
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: quill.QuillEditor.basic(
                controller: _quillController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}