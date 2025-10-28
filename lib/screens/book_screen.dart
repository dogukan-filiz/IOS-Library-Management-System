import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<BookProvider>().fetchBooks(),
    );
  }

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
            Consumer<BookProvider>(
              builder: (context, bookProvider, child) {
                if (bookProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (bookProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Hata: ${bookProvider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => bookProvider.fetchBooks(),
                          child: const Text('Yeniden Dene'),
                        ),
                      ],
                    ),
                  );
                }
                if (bookProvider.books.isEmpty) {
                  return const Center(child: Text('Hiç kitap bulunamadı.'));
                }
                return RefreshIndicator(
                  onRefresh: () => bookProvider.fetchBooks(),
                  child: ListView.builder(
                    itemCount: bookProvider.books.length,
                    itemBuilder: (context, index) {
                      final book = bookProvider.books[index];
                      return ListTile(
                        leading: const Icon(Icons.book),
                        title: Text(book.title),
                        subtitle: Text('${book.author} - ${book.isbn}'),
                        trailing: ElevatedButton(
                          onPressed: book.isAvailable
                              ? () {
                                  // Kiralama işlevi daha sonra eklenecek
                                }
                              : null,
                          child: Text(book.isAvailable ? 'Kirala' : 'Mevcut Değil'),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(book.title),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Yazar: ${book.author}'),
                                  Text('ISBN: ${book.isbn}'),
                                  if (book.publishDate != null)
                                    Text('Yayın Tarihi: ${book.publishDate!.toLocal().toString().split(' ')[0]}'),
                                  if (book.description != null)
                                    Text('Açıklama: ${book.description}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Kapat'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
            // Kiraladığım Kitaplar Sekmesi
            Consumer<BookProvider>(
              builder: (context, bookProvider, child) {
                final rentedBooks = bookProvider.books.where((book) => !book.isAvailable).toList();
                return ListView.builder(
                  itemCount: rentedBooks.length,
                  itemBuilder: (context, index) {
                    final book = rentedBooks[index];
                    return ListTile(
                      leading: const Icon(Icons.book),
                      title: Text(book.title),
                      subtitle: const Text('İade Tarihi: Yakında Eklenecek'),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
