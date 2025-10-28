class Book {
  final int? id;
  final String title;
  final String author;
  final String isbn;
  final DateTime? publishDate;
  final bool isAvailable;
  final String? description;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.isbn,
    this.publishDate,
    required this.isAvailable,
    this.description,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int?,
      title: json['title'] as String,
      author: json['author'] as String,
      isbn: json['isbn'] as String,
      publishDate: json['publishDate'] != null
          ? DateTime.parse(json['publishDate'] as String)
          : null,
      isAvailable: json['isAvailable'] as bool,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'publishDate': publishDate?.toIso8601String(),
      'isAvailable': isAvailable,
      'description': description,
    };
  }
}
