class CategoryModel {
  final String id;
  final String name;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      id: documentId,
      name: map['name'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isActive': isActive,
    };
  }
}