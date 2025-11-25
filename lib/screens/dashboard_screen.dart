import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import 'book_screen.dart';
import 'seat_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserService _userService = UserService();
  int _currentIndex = 0;
  String _userName = '';
  int? _userId;
  String? _userRole;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final firstName = prefs.getString('userFirstName') ?? '';
    final lastName = prefs.getString('userLastName') ?? '';
    final role = prefs.getString('userRole') ?? 'User';

    setState(() {
      _userName = '$firstName $lastName';
      _userId = userId;
      _userRole = role;
    });

    if (userId != null) {
      await _loadStats(userId);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats(int userId) async {
    try {
      final stats = await _userService.getUserStats(userId);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İstatistikler yüklenemedi: $e')),
        );
      }
    }
  }

  Widget _buildHomeScreen() {
    return RefreshIndicator(
      onRefresh: () async {
        if (_userId != null) {
          await _loadStats(_userId!);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoş Geldin Mesajı - Gradient Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoş Geldin! 👋',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userRole ?? 'User',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // İstatistikler Başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'İstatistiklerim',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    if (_userId != null) {
                      await _loadStats(_userId!);
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Yenile'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // İstatistik Kartları (2x2 Grid)
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(
                        icon: Icons.book,
                        title: 'Toplam Kitap',
                        value: '${_stats?['totalBooks'] ?? 0}',
                        color: Colors.blue,
                        onTap: () {
                          setState(() => _currentIndex = 1);
                        },
                      ),
                      _buildStatCard(
                        icon: Icons.library_books,
                        title: 'Kiralık Kitaplarım',
                        value: '${_stats?['myRentals'] ?? 0}',
                        color: Colors.orange,
                        onTap: () {
                          setState(() => _currentIndex = 3);
                        },
                      ),
                      _buildStatCard(
                        icon: Icons.event_seat,
                        title: 'Aktif Rezervasyonlarım',
                        value: '${_stats?['myReservations'] ?? 0}',
                        color: Colors.green,
                        onTap: () {
                          setState(() => _currentIndex = 2);
                        },
                      ),
                      _buildStatCard(
                        icon: Icons.person,
                        title: 'Profil Bilgilerim',
                        value: _userName.split(' ')[0],
                        color: Colors.purple,
                        onTap: () {
                          setState(() => _currentIndex = 3);
                        },
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return const BookScreen();
      case 2:
        return const SeatScreen();
      case 3:
        return ProfileScreen(userId: _userId ?? 0);
      default:
        return _buildHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Admin paneli butonu sol tarafta
        leading: _userRole == 'Admin'
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin');
                  },
                  tooltip: 'Admin Paneli',
                ),
              )
            : null,
        title: Text(
          _currentIndex == 0
              ? 'Ana Sayfa'
              : _currentIndex == 1
                  ? 'Kitaplar'
                  : _currentIndex == 2
                      ? 'Oturma Yerleri'
                      : 'Profilim',
        ),
      ),
      body: _getScreen(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Kitaplar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_seat),
            label: 'Oturma Yerleri',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilim',
          ),
        ],
      ),
    );
  }
}
