import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String baseUrl = 'http://localhost:5038/api';
  bool _isLoading = true;
  Map<String, dynamic>? _userInfo;
  List<dynamic> _rentals = [];
  List<dynamic> _reservations = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      // Kullanıcı bilgileri
      final prefs = await SharedPreferences.getInstance();
      _userInfo = {
        'firstName': prefs.getString('userFirstName') ?? '',
        'lastName': prefs.getString('userLastName') ?? '',
        'email': prefs.getString('userEmail') ?? '',
        'phoneNumber': prefs.getString('userPhone') ?? '',
        'role': prefs.getString('userRole') ?? 'User',
        'isActive': prefs.getBool('userIsActive') ?? true,
      };

      // Kiralanan kitaplar
      final rentalsResponse = await http.get(
        Uri.parse('$baseUrl/BookRentals/user/${widget.userId}'),
      );

      if (rentalsResponse.statusCode == 200) {
        _rentals = json.decode(rentalsResponse.body);
      }

      // Rezervasyonlar
      final reservationsResponse = await http.get(
        Uri.parse('$baseUrl/SeatReservations/user/${widget.userId}'),
      );

      if (reservationsResponse.statusCode == 200) {
        _reservations = json.decode(reservationsResponse.body);
        // Süresi geçmiş rezervasyonları kontrol et ve güncelle
        _checkExpiredReservations();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil verileri yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _returnBook(int rentalId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/BookRentals/$rentalId/return'),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kitap başarıyla iade edildi')),
          );
          _loadProfileData();
        }
      } else {
        throw Exception('İade işlemi başarısız');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İade hatası: $e')),
        );
      }
    }
  }

  Future<void> _cancelReservation(int reservationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/SeatReservations/$reservationId'),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rezervasyon iptal edildi')),
          );
          _loadProfileData();
        }
      } else {
        throw Exception('İptal işlemi başarısız');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İptal hatası: $e')),
        );
      }
    }
  }

  Future<void> _clearReservationHistory() async {
    // Onay diyalogu göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geçmişi Temizle'),
        content: const Text(
          'Aktif olmayan tüm rezervasyonlar silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
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
        Uri.parse('$baseUrl/SeatReservations/user/${widget.userId}/history'),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final count = result['count'] ?? 0;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count rezervasyon silindi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProfileData();
        }
      } else {
        throw Exception('Silme işlemi başarısız');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silme hatası: $e')),
        );
      }
    }
  }

  void _checkExpiredReservations() {
    final now = DateTime.now();
    
    for (var reservation in _reservations) {
      // Sadece aktif rezervasyonları kontrol et
      if (reservation['status'] == 'Aktif') {
        try {
          final endTimeStr = reservation['endTime'];
          if (endTimeStr != null) {
            final endTime = DateTime.parse(endTimeStr);
            
            // Eğer bitiş zamanı geçmişse, statüsü "Süresi Doldu" yap
            if (endTime.isBefore(now)) {
              reservation['status'] = 'Süresi Doldu';
              reservation['_isExpired'] = true;
            }
          }
        } catch (e) {
          // Parse hatası olursa devam et
          continue;
        }
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı Bilgileri Card
            _buildUserInfoCard(),
            const SizedBox(height: 24),

            // Kiralık Kitaplarım
            _buildSectionTitle('Kiralık Kitaplarım'),
            const SizedBox(height: 12),
            _buildRentalsList(),
            const SizedBox(height: 24),

            // Rezervasyon Geçmişim
            _buildSectionTitle('Rezervasyon Geçmişim'),
            const SizedBox(height: 12),
            _buildReservationsList(),
            const SizedBox(height: 12),
            
            // Geçmişi Temizle Butonu (sadece aktif olmayan rezervasyon varsa göster)
            if (_reservations.any((r) => r['status'] != 'Aktif'))
              _buildClearHistoryButton(),
            const SizedBox(height: 24),

            // Çıkış Yap Butonu
            _buildLogoutButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(
                    '${_userInfo?['firstName']?[0] ?? ''}${_userInfo?['lastName']?[0] ?? ''}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_userInfo?['firstName']} ${_userInfo?['lastName']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userInfo?['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone, 'Telefon', _userInfo?['phoneNumber'] ?? 'Belirtilmemiş'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.badge,
              'Rol',
              _userInfo?['role'] ?? 'User',
              badge: true,
              badgeColor: _userInfo?['role'] == 'Admin' ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.check_circle,
              'Hesap Durumu',
              _userInfo?['isActive'] == true ? 'Aktif' : 'Pasif',
              badge: true,
              badgeColor: _userInfo?['isActive'] == true ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool badge = false, Color? badgeColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        if (badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor?.withValues(alpha: 0.1) ?? Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor ?? Colors.grey),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRentalsList() {
    final activeRentals = _rentals.where((r) => r['returnDate'] == null).toList();

    if (activeRentals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Henüz kiralık kitabınız yok'),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeRentals.length,
      itemBuilder: (context, index) {
        final rental = activeRentals[index];
        final dueDate = DateTime.parse(rental['dueDate']);
        final daysRemaining = dueDate.difference(DateTime.now()).inDays;
        final isOverdue = daysRemaining < 0;
        final isDueSoon = daysRemaining <= 3 && daysRemaining >= 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.book, color: Colors.blue),
            title: Text(
              rental['book']?['title'] ?? 'Bilinmeyen Kitap',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Kiralama: ${_formatDate(rental['rentalDate'])}'),
                Text('İade: ${_formatDate(rental['dueDate'])}'),
                if (isDueSoon || isOverdue)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOverdue
                          ? 'GECİKMİŞ (${daysRemaining.abs()} gün)'
                          : 'YAKLAŞIYOR ($daysRemaining gün)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _returnBook(rental['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('İade Et'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReservationsList() {
    if (_reservations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Henüz rezervasyonunuz yok'),
          ),
        ),
      );
    }

    // Rezervasyonları sırala: Önce aktif olanlar, sonra iptal/geçmiş
    final sortedReservations = List<dynamic>.from(_reservations);
    sortedReservations.sort((a, b) {
      final aStatus = a['status'] ?? '';
      final bStatus = b['status'] ?? '';
      
      // Aktif rezervasyonlar en üstte
      if (aStatus == 'Aktif' && bStatus != 'Aktif') return -1;
      if (aStatus != 'Aktif' && bStatus == 'Aktif') return 1;
      
      // Süresi dolmuş olanlar aktiflerden sonra
      if (aStatus == 'Süresi Doldu' && bStatus != 'Süresi Doldu' && bStatus != 'Aktif') return -1;
      if (aStatus != 'Süresi Doldu' && bStatus == 'Süresi Doldu') return 1;
      
      // Aynı statüdeyse tarihe göre sırala (yeni olanlar üstte)
      final aDate = DateTime.tryParse(a['reservationDate'] ?? '') ?? DateTime(2000);
      final bDate = DateTime.tryParse(b['reservationDate'] ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    // 4'ten fazlaysa scrollable yap
    final maxVisibleItems = 4;
    final needsScroll = sortedReservations.length > maxVisibleItems;

    Widget listView = ListView.builder(
      shrinkWrap: true,
      physics: needsScroll ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      itemCount: sortedReservations.length,
      itemBuilder: (context, index) {
        final reservation = sortedReservations[index];
        final status = reservation['status'] ?? 'Bilinmiyor';
        final isActive = status == 'Aktif';
        
        Color statusColor;
        if (status == 'Aktif') {
          statusColor = Colors.green;
        } else if (status == 'Süresi Doldu') {
          statusColor = Colors.orange;
        } else if (status == 'İptal') {
          statusColor = Colors.red;
        } else {
          statusColor = Colors.grey;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(Icons.event_seat, color: statusColor),
            title: Text(
              'Koltuk: ${reservation['seat']?['seatNumber'] ?? 'Bilinmiyor'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Tarih: ${_formatDate(reservation['reservationDate'])}'),
                Text(
                  'Saat: ${_formatTime(reservation['startTime'])} - ${_formatTime(reservation['endTime'])}',
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            trailing: isActive
                ? ElevatedButton(
                    onPressed: () => _cancelReservation(reservation['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('İptal Et'),
                  )
                : null,
          ),
        );
      },
    );

    // 4'ten fazlaysa sabit yükseklikte Container içine al
    if (needsScroll) {
      return Container(
        height: 400, // ~4 kartın yüksekliği
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildClearHistoryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _clearReservationHistory,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.delete_sweep),
        label: const Text(
          'Geçmişi Temizle',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Çıkış Yap',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Bilinmiyor';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return 'Bilinmiyor';
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '--:--';
    try {
      // Parse ISO8601 DateTime string and extract time
      final dateTime = DateTime.parse(timeStr);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }
}
