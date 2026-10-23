class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final int rating; // Số sao (1-5). Nếu là 0 tức là bình luận của Tác giả (không tính sao)
  final bool isAuthor; // Đánh dấu bình luận của Tác giả
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.rating,
    required this.isAuthor,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'rating': rating,
      'isAuthor': isAuthor,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CommentModel(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Tán tu',
      userAvatar: map['userAvatar'],
      content: map['content'] ?? '',
      rating: map['rating']?.toInt() ?? 0,
      isAuthor: map['isAuthor'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}