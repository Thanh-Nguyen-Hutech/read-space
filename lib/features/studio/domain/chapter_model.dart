class Chapter {
  final String id;
  final String bookId;
  final String title; // Ví dụ: "Chương 1: Khởi đầu"
  final String content; // Nội dung chữ của chương
  final int index; // Số thứ tự chương để sắp xếp
  final DateTime createdAt;

  Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.content,
    required this.index,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'title': title,
      'content': content,
      'index': index,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map, String documentId) {
    return Chapter(
      id: documentId,
      bookId: map['bookId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      index: map['index']?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}