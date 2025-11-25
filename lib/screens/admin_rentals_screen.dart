import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminRentalsScreen extends StatefulWidget {
  const AdminRentalsScreen({super.key});

  @override
  State<AdminRentalsScreen> createState() => _AdminRentalsScreenState();
}

class _AdminRentalsScreenState extends State<AdminRentalsScreen> {
  static const String baseUrl = 'http://localhost:5038/api';
  bool _isLoading = true;
  List<dynamic> _rentals = [];
  List<dynamic> _filteredRentals = [];
  String _filterStatus = 'Tümü'; // Tümü, Aktif, Tamamlandı, Gecikmiş

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/BookRentals'));

      if (response.statusCode == 200) {
        final rentals = json.decode(response.body) as List;
        setState(() {
          _rentals = rentals;
          _applyFilter();
          _isLoading = false;
        });
      } else {
        throw Exception('Kiralamalar yüklenemedi');
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

  void _applyFilter() {
    final now = DateTime.now();
    
    setState(() {
      if (_filterStatus == 'Tümü') {
        _filteredRentals = _rentals;
      } else if (_filterStatus == 'Aktif') {
        _filteredRentals = _rentals.where((rental) {
          return rental['returnDate'] == null;
        }).toList();
      } else if (_filterStatus == 'Tamamlandı') {
        _filteredRentals = _rentals.where((rental) {
          return rental['returnDate'] != null;
        }).toList();
      } else if (_filterStatus == 'Gecikmiş') {
        _filteredRentals = _rentals.where((rental) {
          if (rental['returnDate'] != null) return false;
          try {
            final dueDate = DateTime.parse(rental['dueDate']);
            return dueDate.isBefore(now);
          } catch (e) {
            return false;
          }
        }).toList();
      }
    });
  }

  Future<void> _returnBook(int rentalId, String bookTitle, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kitabı İade Et'),
        content: Text('$userName kullanıcısının "$bookTitle" kitabını iade etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('İade Et'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/BookRentals/$rentalId/return'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kitap iade edildi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRentals();
        }
      } else {
        throw Exception('İade işlemi başarısız');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  String _getRentalStatus(Map<String, dynamic> rental) {
    if (rental['returnDate'] != null) {
      return 'Tamamlandı';
    }
    
    try {
      final dueDate = DateTime.parse(rental['dueDate']);
      final now = DateTime.now();
      
      if (dueDate.isBefore(now)) {
        return 'Gecikmiş';
      } else {
        return 'Aktif';
      }
    } catch (e) {
      return 'Aktif';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aktif':
        return Colors.green;
      case 'Gecikmiş':
        return Colors.red;
      case 'Tamamlandı':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  int _getDaysRemaining(Map<String, dynamic> rental) {
    if (rental['returnDate'] != null) return 0;
    
    try {
      final dueDate = DateTime.parse(rental['dueDate']);
      final now = DateTime.now();
      return dueDate.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiralama Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRentals,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtreler
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Filtre: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Tümü'),
                  selected: _filterStatus == 'Tümü',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filterStatus = 'Tümü');
                      _applyFilter();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Aktif'),
                  selected: _filterStatus == 'Aktif',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filterStatus = 'Aktif');
                      _applyFilter();
                    }
                  },
                  selectedColor: Colors.green.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Gecikmiş'),
                  selected: _filterStatus == 'Gecikmiş',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filterStatus = 'Gecikmiş');
                      _applyFilter();
                    }
                  },
                  selectedColor: Colors.red.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Tamamlandı'),
                  selected: _filterStatus == 'Tamamlandı',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filterStatus = 'Tamamlandı');
                      _applyFilter();
                    }
                  },
                  selectedColor: Colors.grey.withValues(alpha: 0.3),
                ),
                const Spacer(),
                Text(
                  'Toplam: ${_filteredRentals.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Kiralama Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRentals.isEmpty
                    ? const Center(child: Text('Kiralama bulunamadı'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Kullanıcı')),
                              DataColumn(label: Text('Kitap')),
                              DataColumn(label: Text('Kiralama Tarihi')),
                              DataColumn(label: Text('İade Tarihi')),
                              DataColumn(label: Text('İade Edildi')),
                              DataColumn(label: Text('Durum')),
                              DataColumn(label: Text('Kalan Gün')),
                              DataColumn(label: Text('İşlemler')),
                            ],
                            rows: _filteredRentals.map((rental) {
                              final status = _getRentalStatus(rental);
                              final daysRemaining = _getDaysRemaining(rental);
                              final userName = '${rental['user']?['firstName'] ?? ''} ${rental['user']?['lastName'] ?? ''}';
                              final bookTitle = rental['book']?['title'] ?? '';

                              return DataRow(
                                cells: [
                                  DataCell(Text(rental['id'].toString())),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          rental['user']?['email'] ?? '',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 200,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            bookTitle,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            rental['book']?['author'] ?? '',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(_formatDate(rental['rentalDate']))),
                                  DataCell(Text(_formatDate(rental['dueDate']))),
                                  DataCell(Text(
                                    rental['returnDate'] != null 
                                        ? _formatDate(rental['returnDate'])
                                        : '-'
                                  )),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      status == 'Tamamlandı' 
                                          ? '-' 
                                          : daysRemaining >= 0 
                                              ? '$daysRemaining gün'
                                              : '${daysRemaining.abs()} gün gecikmiş',
                                      style: TextStyle(
                                        color: daysRemaining < 0 ? Colors.red : Colors.black,
                                        fontWeight: daysRemaining < 0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    rental['returnDate'] == null
                                        ? ElevatedButton.icon(
                                            onPressed: () => _returnBook(
                                              rental['id'],
                                              bookTitle,
                                              userName,
                                            ),
                                            icon: const Icon(Icons.check, size: 16),
                                            label: const Text('İade Et'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                          )
                                        : const Text('İade edildi', style: TextStyle(color: Colors.grey)),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
