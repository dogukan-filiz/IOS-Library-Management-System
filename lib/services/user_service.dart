import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl = 'http://localhost:5038/api';

  Future<UserDashboardData> getUserDashboard(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/dashboard'),
    );

    if (response.statusCode == 200) {
      return UserDashboardData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Dashboard verileri yüklenemedi');
    }
  }

  Future<Map<String, dynamic>> getUserStats(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Admin/users/$userId/stats'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Kullanıcı istatistikleri yüklenemedi');
    }
  }
}

class UserDashboardData {
  final String firstName;
  final String lastName;
  final String email;
  final int activeRentalCount;
  final List<RentalInfo> activeRentals;
  final String? activeSeatNumber;
  final int totalBooksRead;

  UserDashboardData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.activeRentalCount,
    required this.activeRentals,
    this.activeSeatNumber,
    required this.totalBooksRead,
  });

  factory UserDashboardData.fromJson(Map<String, dynamic> json) {
    return UserDashboardData(
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      activeRentalCount: json['activeRentalCount'],
      activeRentals: (json['activeRentals'] as List)
          .map((r) => RentalInfo.fromJson(r))
          .toList(),
      activeSeatNumber: json['activeSeatNumber'],
      totalBooksRead: json['totalBooksRead'],
    );
  }
}

class RentalInfo {
  final String bookTitle;
  final DateTime rentalDate;
  final DateTime dueDate;
  final int daysRemaining;

  RentalInfo({
    required this.bookTitle,
    required this.rentalDate,
    required this.dueDate,
    required this.daysRemaining,
  });

  factory RentalInfo.fromJson(Map<String, dynamic> json) {
    return RentalInfo(
      bookTitle: json['bookTitle'],
      rentalDate: DateTime.parse(json['rentalDate']),
      dueDate: DateTime.parse(json['dueDate']),
      daysRemaining: json['daysRemaining'],
    );
  }
}
