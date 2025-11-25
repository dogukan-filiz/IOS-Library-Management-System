import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() => _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  static const String baseUrl = 'http://localhost:5038/api';
  bool _isLoading = true;
  List<dynamic> _reservations = [];
  List<dynamic> _filteredReservations = [];
  String _filterStatus = 'Tümü'; // Tümü, Aktif, İptal, Tamamlandı

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/SeatReservations'));

      if (response.statusCode == 200) {
        final reservations = json.decode(response.body) as List;
        setState(() {
          _reservations = reservations;
          _applyFilter();
          _isLoading = false;
        });
      } else {
        throw Exception('Rezervasyonlar yüklenemedi');
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
    setState(() {
      if (_filterStatus == 'Tümü') {
        _filteredReservations = _reservations;
      } else {
        _filteredReservations = _reservations.where((reservation) {
          return reservation['status'] == _filterStatus;
        }).toList();
      }
    });
  }

  Future<void> _cancelReservation(int reservationId, String userName, String seatNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rezervasyonu İptal Et'),
        content: Text('$userName kullanıcısının $seatNumber koltuğundaki rezervasyonunu iptal etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/SeatReservations/$reservationId'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervasyon iptal edildi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadReservations();
        }
      } else {
        throw Exception('İptal işlemi başarısız');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Aktif':
        return Colors.green;
      case 'İptal':
        return Colors.red;
      case 'Tamamlandı':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervasyon Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
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
                  label: const Text('İptal'),
                  selected: _filterStatus == 'İptal',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filterStatus = 'İptal');
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
                  'Toplam: ${_filteredReservations.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Rezervasyon Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReservations.isEmpty
                    ? const Center(child: Text('Rezervasyon bulunamadı'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('ID')),
                              DataColumn(label: Text('Kullanıcı')),
                              DataColumn(label: Text('Koltuk')),
                              DataColumn(label: Text('Kat')),
                              DataColumn(label: Text('Rezervasyon Tarihi')),
                              DataColumn(label: Text('Başlangıç Saati')),
                              DataColumn(label: Text('Bitiş Saati')),
                              DataColumn(label: Text('Durum')),
                              DataColumn(label: Text('Oluşturulma')),
                              DataColumn(label: Text('İşlemler')),
                            ],
                            rows: _filteredReservations.map((reservation) {
                              final status = reservation['status'] ?? 'Bilinmiyor';
                              final userName = '${reservation['user']?['firstName'] ?? ''} ${reservation['user']?['lastName'] ?? ''}';
                              final seatNumber = reservation['seat']?['seatNumber'] ?? '';
                              final floor = reservation['seat']?['floor'] ?? '';

                              return DataRow(
                                cells: [
                                  DataCell(Text(reservation['id'].toString())),
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
                                          reservation['user']?['email'] ?? '',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(seatNumber)),
                                  DataCell(Text('$floor. Kat')),
                                  DataCell(Text(_formatDate(reservation['reservationDate']))),
                                  DataCell(Text(_formatTime(reservation['startTime']))),
                                  DataCell(Text(_formatTime(reservation['endTime']))),
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
                                  DataCell(Text(_formatDateTime(reservation['createdAt']))),
                                  DataCell(
                                    status == 'Aktif'
                                        ? ElevatedButton.icon(
                                            onPressed: () => _cancelReservation(
                                              reservation['id'],
                                              userName,
                                              seatNumber,
                                            ),
                                            icon: const Icon(Icons.cancel, size: 16),
                                            label: const Text('İptal Et'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            status == 'İptal' ? 'İptal edildi' : 'Tamamlandı',
                                            style: const TextStyle(color: Colors.grey),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
