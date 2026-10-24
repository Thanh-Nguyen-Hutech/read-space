import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/studio_repository.dart';
import '../../home/data/home_providers.dart';

class UploadBookScreen extends ConsumerStatefulWidget {
  const UploadBookScreen({super.key});

  @override
  ConsumerState<UploadBookScreen> createState() => _UploadBookScreenState();
}

class _UploadBookScreenState extends ConsumerState<UploadBookScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  // Trạng thái cho Định dạng và Thể loại
  String _selectedType = 'Truyện chữ';
  final List<String> _selectedCategories = [];

  // Dữ liệu thể loại mẫu
  final Map<String, String> _availableCategories = {
    'tien-hiep': 'Tiên hiệp',
    'lang-man': 'Lãng mạn',
    'khoa-huyen': 'Khoa huyễn',
    'kiem-hiep': 'Kiếm hiệp',
    'kinh-di': 'Kinh dị',
    'hai-huoc': 'Hài hước',
  };

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_titleController.text.isEmpty ||
        _authorController.text.isEmpty ||
        _descController.text.isEmpty ||
        _imageFile == null ||
        _selectedCategories.isEmpty) { // Bắt buộc chọn ít nhất 1 thể loại
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đủ thông tin, chọn ảnh bìa và ít nhất 1 thể loại!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(studioRepositoryProvider).uploadBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descController.text.trim(),
        coverImage: _imageFile!,
        type: _selectedType,                 // Truyền định dạng
        categoryIds: _selectedCategories,    // Truyền danh sách thể loại
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng tác phẩm thành công!')),
        );
        ref.invalidate(booksProvider);

        // Reset form
        _titleController.clear();
        _authorController.clear();
        _descController.clear();
        _selectedCategories.clear();
        _selectedType = 'Truyện chữ';
        setState(() => _imageFile = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tác phẩm mới'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Khu vực chọn ảnh bìa
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
                  image: _imageFile != null
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text('Nhấn để chọn ảnh bìa', style: TextStyle(color: theme.colorScheme.primary)),
                  ],
                )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên tác phẩm',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Tên tác giả / Bút danh',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 16),

            // CHỌN ĐỊNH DẠNG TRUYỆN
            const Text('Định dạng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              isExpanded: true,
              items: ['Truyện chữ', 'Tiểu thuyết', 'Light Novel', 'Truyện ngắn']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 16),

            // CHỌN THỂ LOẠI (ĐA CHỌN)
            const Text('Thể loại (Chọn nhiều):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _availableCategories.entries.map((entry) {
                final isSelected = _selectedCategories.contains(entry.key);
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primaryContainer,
                  onSelected: (selected) {
                    setState(() {
                      selected ? _selectedCategories.add(entry.key) : _selectedCategories.remove(entry.key);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Tóm tắt nội dung',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            ),
            const SizedBox(height: 32),

            // Nút Đăng
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Đăng tải', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}