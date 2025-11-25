import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SeatScreen extends StatefulWidget {
  const SeatScreen({super.key});

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  static const String baseUrl = 'http://localhost:5038/api';
  
  List<dynamic> _seats = [];
  List<dynamic> _reservations = [];
  bool _isLoading = true;
  int? _userId;

  final List<Map<String, dynamic>> _floors = [
    {'number': 1, 'name': 'Zemin Kat'},
    {'number': 2, 'name': '1. Kat'},
    {'number': 3, 'name': '2. Kat'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSeats();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
    if (_userId != null) {
      await _loadUserReservations();
    }
  }

  Future<void> _loadSeats() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/Seats'));

      if (response.statusCode == 200) {
        setState(() {
          _seats = json.decode(response.body) as List;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Koltuklar yüklenemedi: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Koltuklar yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _loadUserReservations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/SeatReservations/user/$_userId'),
      );

      if (response.statusCode == 200) {
        final reservations = json.decode(response.body) as List;
        
        // Süresi geçmiş rezervasyonları kontrol et
        final now = DateTime.now();
        for (var reservation in reservations) {
          if (reservation['status'] == 'Aktif') {
            try {
              final endTimeStr = reservation['endTime'];
              if (endTimeStr != null) {
                final endTime = DateTime.parse(endTimeStr);
                if (endTime.isBefore(now)) {
                  reservation['status'] = 'Süresi Doldu';
                }
              }
            } catch (e) {
              continue;
            }
          }
        }
        
        setState(() {
          _reservations = reservations;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  List<dynamic> _getSeatsForFloor(int floorNumber) {
    return _seats.where((s) => s['floor'] == floorNumber).toList();
  }

  int _getAvailableSeatsCount(int floorNumber) {
    final floorSeats = _getSeatsForFloor(floorNumber);
    return floorSeats.where((s) => _isSeatAvailable(s)).length;
  }

  bool _isSeatAvailable(dynamic seat) {
    // Check if seat has any active reservation
    final seatId = seat['id'];
    final now = DateTime.now();
    
    return !_reservations.any((r) => 
      r['seatId'] == seatId &&
      r['status'] == 'Aktif' &&
      DateTime.parse(r['reservationDate']).isAfter(now.subtract(const Duration(days: 1)))
    );
  }

  bool _isMyReservation(dynamic seat) {
    final seatId = seat['id'];
    final now = DateTime.now();
    
    return _reservations.any((r) => 
      r['seatId'] == seatId &&
      r['userId'] == _userId &&
      r['status'] == 'Aktif' &&
      DateTime.parse(r['reservationDate']).isAfter(now.subtract(const Duration(days: 1)))
    );
  }

  Future<void> _showReservationDialog(dynamic seat) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: 0);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_seat, color: Colors.blue, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Koltuk ${seat['seatNumber']} - Rezervasyon',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              // Date Picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Tarih'),
                subtitle: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setModalState(() {
                      selectedDate = date;
                    });
                  }
                },
              ),
              
              // Start Time Picker
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Başlangıç Saati'),
                subtitle: Text(startTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (time != null) {
                    setModalState(() {
                      startTime = time;
                    });
                  }
                },
              ),
              
              // End Time Picker
              ListTile(
                leading: const Icon(Icons.access_time_filled),
                title: const Text('Bitiş Saati'),
                subtitle: Text(endTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (time != null) {
                    setModalState(() {
                      endTime = time;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Reserve Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _makeReservation(
                      seat,
                      selectedDate,
                      startTime,
                      endTime,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text(
                    'Rezerve Et',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makeReservation(
    dynamic seat,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')),
      );
      return;
    }

    try {
      final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';

      final response = await http.post(
        Uri.parse('$baseUrl/SeatReservations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'seatId': seat['id'],
          'reservationDate': date.toIso8601String(),
          'startTime': startTimeStr,
          'endTime': endTimeStr,
          'status': 'Aktif',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Koltuk ${seat['seatNumber']} başarıyla rezerve edildi!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadSeats();
          await _loadUserReservations();
        }
      } else {
        String errorMessage = 'Rezervasyon yapılamadı';
        try {
          final error = json.decode(response.body);
          errorMessage = error['message'] ?? errorMessage;
        } catch (_) {
          // If response is not JSON, use a generic message
          errorMessage = 'Rezervasyon yapılamadı. Lütfen tekrar deneyin.';
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
            content: Text('Rezervasyon yapılamadı. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
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
            const SnackBar(
              content: Text('Rezervasyon iptal edildi'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadSeats();
          await _loadUserReservations();
        }
      } else {
        throw Exception('İptal işlemi başarısız');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İptal hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadSeats();
        await _loadUserReservations();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legend (Gösterge)
            _buildLegend(),
            const SizedBox(height: 16),
            
            // Floor Accordions
            ..._floors.map((floor) => _buildFloorAccordion(floor)),
            
            const SizedBox(height: 24),
            
            // My Reservations Section
            _buildMyReservationsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(Colors.green, 'Müsait'),
            _buildLegendItem(Colors.orange, 'İleri Tarihte'),
            _buildLegendItem(Colors.red, 'Dolu'),
            _buildLegendItem(Colors.blue, 'Rezervasyonum'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildFloorAccordion(Map<String, dynamic> floor) {
    final floorNumber = floor['number'] as int;
    final floorName = floor['name'] as String;
    final floorSeats = _getSeatsForFloor(floorNumber);
    final availableCount = _getAvailableSeatsCount(floorNumber);
    final totalCount = floorSeats.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          Icons.layers,
          color: Colors.blue,
        ),
        title: Text(
          floorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$availableCount/$totalCount Müsait'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: floorSeats.isEmpty
                ? const Center(child: Text('Bu katta koltuk bulunmuyor'))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: floorSeats.length,
                    itemBuilder: (context, index) {
                      return _buildSeatTile(floorSeats[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatTile(dynamic seat) {
    final seatStatus = seat['status'] ?? 'available';
    final isMyReservation = _isMyReservation(seat);

    Color color;
    bool canReserve;

    if (isMyReservation) {
      color = Colors.blue;
      canReserve = false;
    } else if (seatStatus == 'available') {
      color = Colors.green;
      canReserve = true;
    } else if (seatStatus == 'reserved') {
      color = Colors.orange;
      canReserve = true;
    } else {
      color = Colors.red;
      canReserve = false;
    }

    return InkWell(
      onTap: canReserve ? () => _showReservationDialog(seat) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              seat['seatNumber'] ?? '',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyReservationsSection() {
    final activeReservations = _reservations
        .where((r) => r['status'] == 'Aktif' || r['status'] == 'Süresi Doldu')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rezervasyonlarım',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (activeReservations.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Aktif rezervasyonunuz yok')),
            ),
          )
        else
          ...activeReservations.map((reservation) {
            final date = DateTime.parse(reservation['reservationDate']);
            final status = reservation['status'] ?? 'Aktif';
            final isExpired = status == 'Süresi Doldu';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  Icons.event_seat, 
                  color: isExpired ? Colors.orange : Colors.blue,
                ),
                title: Text(
                  'Koltuk: ${reservation['seat']?['seatNumber'] ?? 'Bilinmiyor'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Tarih: ${DateFormat('dd.MM.yyyy').format(date)}'),
                    Text(
                      'Saat: ${_formatTime(reservation['startTime'])} - ${_formatTime(reservation['endTime'])}',
                    ),
                    if (isExpired)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Text(
                          'Süresi Doldu',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: isExpired ? null : ElevatedButton(
                  onPressed: () => _cancelReservation(reservation['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('İptal Et'),
                ),
              ),
            );
          }),
      ],
    );
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
