class Book {
  final String id;
  final String title;
  final String author;
  final String authorId;
  final String coverUrl;
  final double rating;
  final String description;
  final String status;
  final List<String> categoryIds; // Bổ sung trường quản lý mảng thể loại

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.authorId,
    required this.coverUrl,
    required this.rating,
    required this.description,
    this.status = 'Đang ra',
    this.categoryIds = const [], // Khởi tạo danh sách rỗng mặc định
  });

  factory Book.fromMap(Map<String, dynamic> map, String documentId) {
    return Book(
      id: documentId,
      title: map['title'] ?? 'Chưa cập nhật',
      author: map['author'] ?? 'Vô danh',
      authorId: map['authorId'] ?? '',
      coverUrl: map['coverUrl'] ?? 'https://via.placeholder.com/150',
      rating: (map['rating'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      status: map['status'] ?? 'Đang ra',
      categoryIds: List<String>.from(map['categoryIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'authorId': authorId,
      'coverUrl': coverUrl,
      'rating': rating,
      'description': description,
      'status': status,
      'categoryIds': categoryIds,
      'createdAt': DateTime.now(),
    };
  }
}