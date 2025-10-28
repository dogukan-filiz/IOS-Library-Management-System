import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BookService {
  final String baseUrl = 'http://localhost:5038/api';

  Future<List<Book>> getBooks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/books'));
      if (response.statusCode == 200) {
        List<dynamic> booksJson = json.decode(response.body);
        return booksJson.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }

  Future<Book> getBook(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/books/$id'));
      if (response.statusCode == 200) {
        return Book.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load book');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }

  Future<Book> addBook(Book book) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/books'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(book.toJson()),
      );
      if (response.statusCode == 201) {
        return Book.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add book');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }

  Future<Book> updateBook(int id, Book book) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/books/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(book.toJson()),
      );
      if (response.statusCode == 200) {
        return Book.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update book');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }

  Future<void> deleteBook(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/books/$id'));
      if (response.statusCode != 204) {
        throw Exception('Failed to delete book');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }
}
