import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  static const String baseUrl = 'http://localhost:5038/api';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<dynamic> _books = [];
  List<dynamic> _filteredBooks = [];
  bool _isLoading = true;
  bool _showAvailableOnly = false;
  String? _selectedCategory;
  List<String> _categories = [];
  int? _userId;
  int _activeRentalsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBooks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
    if (_userId != null) {
      await _loadActiveRentals();
    }
  }

  Future<void> _loadActiveRentals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/BookRentals/user/$_userId'),
      );

      if (response.statusCode == 200) {
        final rentals = json.decode(response.body) as List;
        setState(() {
          _activeRentalsCount = rentals.where((r) => r['returnDate'] == null).length;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/Books'));

      if (response.statusCode == 200) {
        final books = json.decode(response.body) as List;
        
        // Extract unique categories
        final categories = books
            .where((b) => b['category'] != null)
            .map((b) => b['category'] as String)
            .toSet()
            .toList();

        setState(() {
          _books = books;
          _filteredBooks = books;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kitaplar yüklenemedi: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredBooks = _books;
      });
      _applyFilters();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Books/search?query=$query'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _filteredBooks = json.decode(response.body) as List;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama hatası: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      var filtered = _searchController.text.isEmpty ? _books : _filteredBooks;

      if (_showAvailableOnly) {
        filtered = filtered.where((b) => b['isAvailable'] == true).toList();
      }

      if (_selectedCategory != null) {
        filtered = filtered.where((b) => b['category'] == _selectedCategory).toList();
      }

      _filteredBooks = filtered;
    });
  }

  Future<void> _rentBook(dynamic book) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
      );
      return;
    }

    // Check active rentals limit
    if (_activeRentalsCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aynı anda en fazla 3 kitap kiralayabilirsiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/BookRentals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'bookId': book['id'],
          'rentalDays': 14,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${book['title']} başarıyla kiralandı!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadBooks();
          await _loadActiveRentals();
        }
      } else {
        String errorMessage = 'Kitap kiralanamadı';
        try {
          final error = json.decode(response.body);
          errorMessage = error['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = 'Kitap kiralanamadı. Lütfen tekrar deneyin.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kitap kiralanamadı. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Kitap, yazar veya kategori ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Filters Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tümü'),
                        ),
                        ..._categories.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('Sadece Müsait'),
                    selected: _showAvailableOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showAvailableOnly = selected;
                      });
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Books List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredBooks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Kitap bulunamadı',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBooks,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(_filteredBooks[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBookCard(dynamic book) {
    final isAvailable = book['isAvailable'] ?? false;
    final availableCopies = book['availableCopies'] ?? 0;
    final totalCopies = book['totalCopies'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, size: 40, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? 'Bilinmeyen Kitap',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book['author'] ?? 'Bilinmeyen Yazar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (book['category'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple),
                          ),
                          child: Text(
                            book['category'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    '$availableCopies/$totalCopies müsait',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isAvailable ? () => _rentBook(book) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(isAvailable ? 'Kirala' : 'Müsait Değil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
