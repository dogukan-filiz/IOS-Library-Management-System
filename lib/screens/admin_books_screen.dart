import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  static const String baseUrl = 'http://localhost:5038/api';
  bool _isLoading = true;
  List<dynamic> _books = [];
  List<dynamic> _filteredBooks = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/Books'));

      if (response.statusCode == 200) {
        final books = json.decode(response.body) as List;
        setState(() {
          _books = books;
          _filteredBooks = books;
          _isLoading = false;
        });
      } else {
        throw Exception('Kitaplar yüklenemedi');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _searchBooks(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredBooks = _books;
      });
      return;
    }

    setState(() {
      _filteredBooks = _books.where((book) {
        final title = (book['title'] ?? '').toLowerCase();
        final author = (book['author'] ?? '').toLowerCase();
        final category = (book['category'] ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        return title.contains(searchLower) ||
            author.contains(searchLower) ||
            category.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _deleteBook(int bookId, String bookTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kitabı Sil'),
        content: Text('$bookTitle kitabını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/Books/$bookId'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kitap silindi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadBooks();
        }
      } else {
        throw Exception('Silme işlemi başarısız');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _showBookDialog({Map<String, dynamic>? book}) {
    final isEdit = book != null;
    final titleController = TextEditingController(text: book?['title'] ?? '');
    final authorController = TextEditingController(text: book?['author'] ?? '');
    final isbnController = TextEditingController(text: book?['isbn'] ?? '');
    final categoryController = TextEditingController(text: book?['category'] ?? '');
    final publisherController = TextEditingController(text: book?['publisher'] ?? '');
    final descriptionController = TextEditingController(text: book?['description'] ?? '');
    final totalCopiesController = TextEditingController(
      text: book?['totalCopies']?.toString() ?? '1',
    );
    final availableCopiesController = TextEditingController(
      text: book?['availableCopies']?.toString() ?? '1',
    );
    final pagecountController = TextEditingController(
      text: book?['pageCount']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Kitabı Düzenle' : 'Yeni Kitap Ekle'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Kitap Adı *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: 'Yazar *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: isbnController,
                  decoration: const InputDecoration(
                    labelText: 'ISBN',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: publisherController,
                  decoration: const InputDecoration(
                    labelText: 'Yayınevi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalCopiesController,
                        decoration: const InputDecoration(
                          labelText: 'Toplam Kopya *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: availableCopiesController,
                        decoration: const InputDecoration(
                          labelText: 'Mevcut Kopya *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pagecountController,
                  decoration: const InputDecoration(
                    labelText: 'Sayfa Sayısı',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveBook(
                bookId: book?['id'],
                title: titleController.text,
                author: authorController.text,
                isbn: isbnController.text,
                category: categoryController.text,
                publisher: publisherController.text,
                description: descriptionController.text,
                totalCopies: int.tryParse(totalCopiesController.text) ?? 1,
                availableCopies: int.tryParse(availableCopiesController.text) ?? 1,
                pageCount: int.tryParse(pagecountController.text),
              );
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Güncelle' : 'Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBook({
    int? bookId,
    required String title,
    required String author,
    required String isbn,
    required String category,
    required String publisher,
    required String description,
    required int totalCopies,
    required int availableCopies,
    int? pageCount,
  }) async {
    if (title.isEmpty || author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kitap adı ve yazar zorunludur')),
      );
      return;
    }

    try {
      final body = {
        'title': title,
        'author': author,
        'isbn': isbn.isEmpty ? null : isbn,
        'category': category.isEmpty ? null : category,
        'publisher': publisher.isEmpty ? null : publisher,
        'description': description.isEmpty ? null : description,
        'totalCopies': totalCopies,
        'availableCopies': availableCopies,
        'isAvailable': availableCopies > 0,
        'pageCount': pageCount,
      };

      if (bookId != null) {
        body['id'] = bookId;
      }

      final response = bookId == null
          ? await http.post(
              Uri.parse('$baseUrl/Books'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            )
          : await http.put(
              Uri.parse('$baseUrl/Books/$bookId'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(bookId == null ? 'Kitap eklendi' : 'Kitap güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadBooks();
        }
      } else {
        throw Exception('İşlem başarısız: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBooks,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve Ekleme
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Kitap Ara (Başlık, Yazar, Kategori)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchBooks('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _searchBooks,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showBookDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Kitap'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Kitap Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                    ? const Center(child: Text('Kitap bulunamadı'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Başlık')),
                              DataColumn(label: Text('Yazar')),
                              DataColumn(label: Text('ISBN')),
                              DataColumn(label: Text('Kategori')),
                              DataColumn(label: Text('Yayınevi')),
                              DataColumn(label: Text('Toplam')),
                              DataColumn(label: Text('Mevcut')),
                              DataColumn(label: Text('Durum')),
                              DataColumn(label: Text('İşlemler')),
                            ],
                            rows: _filteredBooks.map((book) {
                              final available = book['availableCopies'] ?? 0;
                              final total = book['totalCopies'] ?? 0;
                              return DataRow(
                                cells: [
                                  DataCell(Text(book['id'].toString())),
                                  DataCell(
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        book['title'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(book['author'] ?? '')),
                                  DataCell(Text(book['isbn'] ?? '-')),
                                  DataCell(Text(book['category'] ?? '-')),
                                  DataCell(Text(book['publisher'] ?? '-')),
                                  DataCell(Text(total.toString())),
                                  DataCell(Text(available.toString())),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: available > 0
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        available > 0 ? 'Müsait' : 'Kirada',
                                        style: TextStyle(
                                          color: available > 0 ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showBookDialog(book: book),
                                          tooltip: 'Düzenle',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteBook(
                                            book['id'],
                                            book['title'] ?? '',
                                          ),
                                          tooltip: 'Sil',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
