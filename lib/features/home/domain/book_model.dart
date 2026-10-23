class Book {
  final String id;
  final String title;
  final String author;
  final String authorId;
  final String coverUrl;
  final double rating;
  final String description;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.authorId,
    required this.coverUrl,
    required this.rating,
    required this.description,
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
      'createdAt': DateTime.now(),
    };
  }
}