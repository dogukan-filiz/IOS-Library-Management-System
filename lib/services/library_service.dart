import 'dart:convert';
import 'package:http/http.dart' as http;

class Book {
  final int id;
  final String title;
  final String author;
  final String isbn;
  final DateTime? publishDate;
  final bool isAvailable;
  final String? description;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    this.publishDate,
    required this.isAvailable,
    this.description,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      isbn: json['isbn'],
      publishDate: json['publishDate'] != null
          ? DateTime.parse(json['publishDate'])
          : null,
      isAvailable: json['isAvailable'],
      description: json['description'],
    );
  }
}

class LibraryService {
  static const String baseUrl = 'https://localhost:7217/api'; // ASP.NET Core default port

  Future<List<Book>> getBooks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/books'));

      if (response.statusCode == 200) {
        List<dynamic> booksJson = jsonDecode(response.body);
        return booksJson.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  Future<Book> getBook(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/books/$id'));

    if (response.statusCode == 200) {
      return Book.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load book');
    }
  }
}
