import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const String baseUrl = 'http://localhost:5038/api';
  bool _isLoading = true;
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/Users'));

      if (response.statusCode == 200) {
        final users = json.decode(response.body) as List;
        setState(() {
          _users = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      } else {
        throw Exception('Kullanıcılar yüklenemedi');
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

  void _searchUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    setState(() {
      _filteredUsers = _users.where((user) {
        final fullName = '${user['firstName']} ${user['lastName']}'.toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        return fullName.contains(searchLower) || email.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _deleteUser(int userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text('$userName kullanıcısını silmek istediğinizden emin misiniz?'),
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
        Uri.parse('$baseUrl/Users/$userId'),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcı silindi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Silme işlemi başarısız');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _showUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final firstNameController = TextEditingController(text: user?['firstName'] ?? '');
    final lastNameController = TextEditingController(text: user?['lastName'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final phoneController = TextEditingController(text: user?['phoneNumber'] ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?['role'] ?? 'User';
    bool isActive = user?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Kullanıcıyı Düzenle' : 'Yeni Kullanıcı Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Soyad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon (opsiyonel)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'Yeni Şifre (boş bırakılabilir)' : 'Şifre',
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: ['User', 'Student', 'Admin', 'Librarian'].map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Aktif'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveUser(
                  userId: user?['id'],
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  password: passwordController.text,
                  role: selectedRole,
                  isActive: isActive,
                );
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Güncelle' : 'Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUser({
    int? userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String role,
    required bool isActive,
  }) async {
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad, soyad ve email zorunludur')),
      );
      return;
    }

    if (userId == null && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni kullanıcı için şifre zorunludur')),
      );
      return;
    }

    try {
      final body = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phone.isEmpty ? null : phone,
        'role': role,
        'isActive': isActive,
      };

      if (password.isNotEmpty) {
        body['password'] = password;
      }

      final response = userId == null
          ? await http.post(
              Uri.parse('$baseUrl/Users'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            )
          : await http.put(
              Uri.parse('$baseUrl/Users/$userId'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userId == null ? 'Kullanıcı eklendi' : 'Kullanıcı güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'İşlem başarısız');
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
        title: const Text('Kullanıcı Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve Filtre
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Kullanıcı Ara (Ad, Soyad, Email)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchUsers('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _searchUsers,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showUserDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Kullanıcı'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Kullanıcı Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('Kullanıcı bulunamadı'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Ad Soyad')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Telefon')),
                            DataColumn(label: Text('Rol')),
                            DataColumn(label: Text('Durum')),
                            DataColumn(label: Text('Kayıt Tarihi')),
                            DataColumn(label: Text('İşlemler')),
                          ],
                          rows: _filteredUsers.map((user) {
                            return DataRow(
                              cells: [
                                DataCell(Text(user['id'].toString())),
                                DataCell(Text('${user['firstName']} ${user['lastName']}')),
                                DataCell(Text(user['email'] ?? '')),
                                DataCell(Text(user['phoneNumber'] ?? '-')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: user['role'] == 'Admin'
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user['role'] ?? 'User',
                                      style: TextStyle(
                                        color: user['role'] == 'Admin' ? Colors.red : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Icon(
                                    user['isActive'] ? Icons.check_circle : Icons.cancel,
                                    color: user['isActive'] ? Colors.green : Colors.red,
                                  ),
                                ),
                                DataCell(Text(_formatDate(user['createdAt']))),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showUserDialog(user: user),
                                        tooltip: 'Düzenle',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteUser(
                                          user['id'],
                                          '${user['firstName']} ${user['lastName']}',
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
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
