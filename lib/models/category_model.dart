class CategoryModel {
  final int categoryId;
  final String categoryName;
  final String categoryImage;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.categoryImage,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      categoryImage: json['categoryImage'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CategoryModel && runtimeType == other.runtimeType && categoryId == other.categoryId;

  @override
  int get hashCode => categoryId.hashCode;
}
