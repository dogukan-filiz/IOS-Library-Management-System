import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/statistic_card.dart';
import '../services/user_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserService _userService = UserService();
  UserDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final firstName = prefs.getString('userFirstName') ?? '';
    final lastName = prefs.getString('userLastName') ?? '';
    
    setState(() {
      _userName = '$firstName $lastName';
    });

    if (userId != null) {
      try {
        final data = await _userService.getUserDashboard(userId);
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // İstatistik Kartları
                      _buildStatisticsSection(),
                      const SizedBox(height: 24),
                      
                      // Ana Menü Kartları
                      _buildMainMenuCards(context),
                      const SizedBox(height: 24),
                      
                      // Hızlı Erişim Menüsü
                      _buildQuickAccessMenu(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Alt Navigasyon
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoş Geldin,',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  _userName ?? 'Yükleniyor...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        StatisticCard(
          icon: Icons.book,
          title: 'Kiralık Kitaplar',
          value: '${_dashboardData?.activeRentalCount ?? 0}',
          color: _dashboardData != null && _dashboardData!.activeRentalCount >= 3 
              ? Colors.red 
              : Colors.blue,
        ),
        StatisticCard(
          icon: Icons.chair,
          title: 'Aktif Rezervasyon',
          value: _dashboardData?.activeSeatNumber ?? 'Yok',
          color: _dashboardData?.activeSeatNumber != null 
              ? Colors.green 
              : Colors.red,
        ),
        StatisticCard(
          icon: Icons.auto_stories,
          title: 'Okunan Kitaplar',
          value: '${_dashboardData?.totalBooksRead ?? 0}',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMainMenuCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/books'),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.book, size: 48, color: Colors.blue),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kitap Kiralama',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Kitap ara, kirala veya iade et',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/seats'),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.chair, size: 48, color: Colors.green),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Oturma Yeri Kiralama',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Çalışma alanı rezerve et',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı Erişim',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickAccessCard(
                'Son Okunan',
                'Sefiller',
                Icons.book_online,
                Colors.blue,
              ),
              _buildQuickAccessCard(
                'İade Tarihi',
                '3 gün kaldı',
                Icons.timer,
                Colors.orange,
              ),
              _buildQuickAccessCard(
                'Favori Kitaplar',
                '12 kitap',
                Icons.favorite,
                Colors.red,
              ),
              _buildQuickAccessCard(
                'Rezervasyonlar',
                'Aktif: 1',
                Icons.calendar_today,
                Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
