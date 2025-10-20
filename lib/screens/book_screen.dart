import 'package:flutter/material.dart';

class BookScreen extends StatelessWidget {
  const BookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kitap Kiralama'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mevcut Kitaplar'),
              Tab(text: 'Kiraladığım Kitaplar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Mevcut Kitaplar Sekmesi
            ListView.builder(
              itemCount: 10, // Örnek veri
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.book),
                  title: Text('Kitap ${index + 1}'),
                  subtitle: const Text('Yazar Adı'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Kiralama işlevi daha sonra eklenecek
                    },
                    child: const Text('Kirala'),
                  ),
                );
              },
            ),
            // Kiraladığım Kitaplar Sekmesi
            ListView.builder(
              itemCount: 5, // Örnek veri
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.book),
                  title: Text('Kiralanan Kitap ${index + 1}'),
                  subtitle: const Text('İade Tarihi: 01.11.2025'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // İade işlevi daha sonra eklenecek
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('İade Et'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
