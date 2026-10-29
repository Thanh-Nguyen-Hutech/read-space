import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../library/data/library_provider.dart';
import '../data/home_providers.dart';
import '../../reader/data/reader_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../studio/data/studio_repository.dart';
import '../../reviews/data/review_providers.dart';
import '../../reviews/domain/comment_model.dart';
import '../../auth/data/user_provider.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _showAllChapters = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booksAsync = ref.watch(booksProvider);
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;

    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final isAdmin = userProfileAsync.maybeWhen(data: (p) => p?.role == 'admin', orElse: () => false);

    return booksAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Lỗi: $e'))),
      data: (books) {
        final book = books.firstWhere((b) => b.id == widget.bookId, orElse: () => books.first);
        final isAuthor = currentUserId == book.authorId;

        // BỘ LỌC BẢO MẬT: CHẶN TRUYỆN VI PHẠM
        if (book.status == 'Khóa/Vi phạm' && !isAdmin && !isAuthor) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gavel_rounded, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Tác phẩm đã bị gỡ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Truyện này đang bị tạm khóa do vi phạm Tiêu chuẩn cộng đồng của hệ thống.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Quay lại'),
                  )
                ],
              ),
            ),
          );
        }

        Color statusColor = Colors.green;
        IconData statusIcon = Icons.info_outline_rounded;
        if (book.status == 'Khóa/Vi phạm') {
          statusColor = Colors.red;
          statusIcon = Icons.cancel_rounded;
        } else if (book.status == 'Đã hoàn thành') {
          statusColor = Colors.blue;
          statusIcon = Icons.check_circle_outline_rounded;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(book.title),
            actions: [
              Consumer(
                builder: (context, ref, child) {
                  final isSaved = ref.watch(libraryProvider.notifier).isBookSaved(book.id);
                  ref.watch(libraryProvider);

                  return IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: isSaved ? theme.colorScheme.primary : null,
                    ),
                    tooltip: isSaved ? 'Bỏ lưu' : 'Lưu sách',
                    onPressed: () {
                      ref.read(libraryProvider.notifier).toggleBookmark(book);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isSaved ? 'Đã bỏ lưu sách!' : 'Đã thêm vào Thư viện!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(book.coverUrl, height: 250, width: 170, fit: BoxFit.cover),
                ),
                const SizedBox(height: 24),
                Text(book.title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(book.author, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(book.rating.toString(), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),

                    Consumer(
                      builder: (context, ref, child) {
                        final chapAsync = ref.watch(chaptersProvider(book.id));
                        final count = chapAsync.maybeWhen(data: (c) => c.length, orElse: () => 0);
                        return Row(
                          children: [
                            const Icon(Icons.format_list_numbered_rounded, color: Colors.blue, size: 20),
                            const SizedBox(width: 4),
                            Text('$count chương', style: theme.textTheme.titleMedium),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 16),

                    Icon(statusIcon, color: statusColor, size: 20),
                    const SizedBox(width: 4),
                    Text(book.status, style: theme.textTheme.titleMedium?.copyWith(color: statusColor)),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: book.status == 'Khóa/Vi phạm' && !isAdmin && !isAuthor ? null : () {
                      context.push('/read/${book.id}');
                    },
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('Bắt đầu đọc', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                if (isAuthor) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  Text('Công cụ Tác giả', style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/add-chapter/${book.id}'),
                      icon: const Icon(Icons.add_box_rounded),
                      label: const Text('Đăng chương mới'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Xóa tác phẩm?'),
                            content: const Text('Hành động này không thể hoàn tác.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(studioRepositoryProvider).deleteBook(book.id);
                          ref.invalidate(booksProvider);
                          if (context.mounted) context.pop();
                        }
                      },
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      label: const Text('Xóa tác phẩm', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tóm tắt nội dung', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(
                  book.description,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, color: theme.colorScheme.onSurface),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Mục lục tác phẩm', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),

                Consumer(
                  builder: (context, ref, child) {
                    final chaptersAsync = ref.watch(chaptersProvider(book.id));

                    return chaptersAsync.when(
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
                      error: (e, st) => Text('Lỗi tải mục lục: $e'),
                      data: (chapters) {
                        if (chapters.isEmpty) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Truyện đang cập nhật, chưa có chương mới.', style: TextStyle(color: Colors.grey)),
                          );
                        }

                        final displayChapters = chapters.reversed.toList();
                        final int displayCount = _showAllChapters
                            ? displayChapters.length
                            : (displayChapters.length > 10 ? 10 : displayChapters.length);

                        return Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayCount,
                              itemBuilder: (context, index) {
                                final chapter = displayChapters[index];

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text(
                                      '${chapter.index}',
                                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey.shade400, fontWeight: FontWeight.bold)
                                  ),
                                  title: Text(chapter.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    DateFormat('dd/MM/yyyy - HH:mm').format(chapter.createdAt),
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                  trailing: isAuthor
                                      ? PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        context.push('/edit-chapter/${book.id}', extra: chapter);
                                      } else if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('Xóa chương này?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await ref.read(studioRepositoryProvider).deleteChapter(bookId: book.id, chapterId: chapter.id);
                                          ref.invalidate(chaptersProvider(book.id));
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Sửa chương')),
                                      const PopupMenuItem(value: 'delete', child: Text('Xóa chương', style: TextStyle(color: Colors.red))),
                                    ],
                                  )
                                      : const Icon(Icons.play_circle_outline_rounded, color: Colors.grey, size: 20),
                                  onTap: () {
                                    final originalIndex = chapters.indexOf(chapter);
                                    context.push('/read/${book.id}', extra: originalIndex);
                                  },
                                );
                              },
                            ),
                            if (!_showAllChapters && displayChapters.length > 10)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() => _showAllChapters = true);
                                },
                                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                label: const Text('Xem toàn bộ chương'),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                RatingBox(bookId: book.id, authorId: book.authorId),
                CommentSection(bookId: book.id, authorId: book.authorId),
                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CommentSection extends ConsumerStatefulWidget {
  final String bookId;
  final String authorId;
  const CommentSection({super.key, required this.bookId, required this.authorId});

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  int _commentLimit = 10;

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    final isAuthor = user.uid == widget.authorId;

    final newComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      userName: user.displayName ?? user.email ?? 'Ẩn danh',
      userAvatar: user.photoURL,
      content: _commentController.text.trim(),
      rating: 0,
      isAuthor: isAuthor,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(reviewRepositoryProvider).addComment(bookId: widget.bookId, comment: newComment);
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final isAuthor = user?.uid == widget.authorId;

    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final isAdmin = userProfileAsync.maybeWhen(data: (profile) => profile?.role == 'admin', orElse: () => false);

    final commentsAsync = ref.watch(bookCommentsProvider(widget.bookId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Khu vực Thảo luận', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: isAuthor ? 'Ghim thông báo của Tác giả...' : 'Chia sẻ suy nghĩ của bạn...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isSubmitting
                ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                : IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.blue, size: 28),
              onPressed: _submitComment,
            ),
          ],
        ),
        const SizedBox(height: 24),

        commentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Lỗi: $e'),
          data: (comments) {
            if (comments.isEmpty) return const Text('Chưa có bình luận nào. Hãy là người đầu tiên!', style: TextStyle(color: Colors.grey));

            final authorComments = comments.where((c) => c.isAuthor).toList();
            final readerComments = comments.where((c) => !c.isAuthor).toList();
            final displayReaderComments = readerComments.take(_commentLimit).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (authorComments.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.push_pin_rounded, color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text('Tác giả ghim', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: authorComments.length,
                          itemBuilder: (context, index) => CommentItemWidget(
                            comment: authorComments[index],
                            bookId: widget.bookId,
                            isAdmin: isAdmin,
                            currentUserId: user?.uid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (readerComments.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayReaderComments.length,
                    itemBuilder: (context, index) => CommentItemWidget(
                      comment: displayReaderComments[index],
                      bookId: widget.bookId,
                      isAdmin: isAdmin,
                      currentUserId: user?.uid,
                    ),
                  ),

                if (readerComments.length > _commentLimit)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _commentLimit += 10),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      label: const Text('Xem thêm bình luận'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class CommentItemWidget extends ConsumerWidget {
  final CommentModel comment;
  final String bookId;
  final bool isAdmin;
  final String? currentUserId;

  const CommentItemWidget({
    super.key,
    required this.comment,
    required this.bookId,
    required this.isAdmin,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorProfileAsync = ref.watch(userProfileByIdProvider(comment.userId));

    final currentName = authorProfileAsync.maybeWhen(
      data: (user) => user?.name ?? comment.userName,
      orElse: () => comment.userName,
    );
    final currentAvatar = authorProfileAsync.maybeWhen(
      data: (user) => user?.avatar ?? comment.userAvatar,
      orElse: () => comment.userAvatar,
    );

    final canDelete = (currentUserId == comment.userId) || isAdmin;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: currentAvatar != null ? NetworkImage(currentAvatar) : null,
            child: currentAvatar == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: comment.isAuthor ? Colors.blue.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: comment.isAuthor ? Border.all(color: Colors.blue.withOpacity(0.3)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(currentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (comment.isAuthor) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Tác giả', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM HH:mm').format(comment.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Text(comment.content),
                ],
              ),
            ),
          ),

          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Xóa bình luận?'),
                    content: isAdmin && currentUserId != comment.userId
                        ? const Text('BẠN ĐANG DÙNG QUYỀN ADMIN. Chắc chắn muốn xóa vi phạm?')
                        : const Text('Bạn có chắc chắn muốn xóa bình luận này?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(reviewRepositoryProvider).deleteComment(bookId, comment.id);
                }
              },
            ),
        ],
      ),
    );
  }
}

class RatingBox extends ConsumerWidget {
  final String bookId;
  final String authorId;

  const RatingBox({super.key, required this.bookId, required this.authorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    if (user == null || user.uid == authorId) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final ratingAsync = ref.watch(userRatingProvider(bookId));

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: ratingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Text('Lỗi tải đánh giá: $e'),
        data: (currentRating) {
          final hasRated = currentRating != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasRated ? 'Đánh giá của bạn ($currentRating/5)' : 'Bạn chấm tác phẩm này mấy sao?',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (hasRated)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      tooltip: 'Xóa đánh giá',
                      onPressed: () {
                        ref.read(reviewRepositoryProvider).deleteRating(bookId, user.uid);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final isSelected = hasRated && starValue <= currentRating;
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      ref.read(reviewRepositoryProvider).submitRating(bookId, user.uid, starValue);
                    },
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}