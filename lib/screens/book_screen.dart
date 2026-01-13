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
        // Compact Search and Filters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Kitap veya yazar ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              // Compact Filters
              Row(
                children: [
                  // Category Dropdown (Smaller)
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text('Kategori', style: TextStyle(fontSize: 14)),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tümü')),
                            ..._categories.map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat, style: const TextStyle(fontSize: 14)),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                            _applyFilters();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Available Only Chip
                  Expanded(
                    flex: 2,
                    child: FilterChip(
                      label: const Text('Müsait', style: TextStyle(fontSize: 13)),
                      selected: _showAvailableOnly,
                      onSelected: (selected) {
                        setState(() => _showAvailableOnly = selected);
                        _applyFilters();
                      },
                      checkmarkColor: Colors.white,
                      selectedColor: Colors.green,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isAvailable ? () => _rentBook(book) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Book Icon/Cover
              Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.book, size: 30, color: Colors.white),
              ),
              const SizedBox(width: 12),
              
              // Book Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'] ?? 'Bilinmeyen Kitap',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book['author'] ?? 'Bilinmeyen Yazar',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (book['category'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              book['category'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAvailable ? Icons.check_circle : Icons.cancel,
                                size: 12,
                                color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$availableCopies/$totalCopies',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Rent Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.blue : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAvailable ? Icons.add_shopping_cart : Icons.block,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
