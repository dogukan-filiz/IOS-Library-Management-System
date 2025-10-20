import 'package:flutter/material.dart';

class SeatScreen extends StatelessWidget {
  const SeatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oturma Yeri Kiralama'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 20, // Örnek veri
        itemBuilder: (context, index) {
          final bool isOccupied = index % 3 == 0; // Örnek durum

          return InkWell(
            onTap: isOccupied
                ? null
                : () {
                    // Rezervasyon işlevi daha sonra eklenecek
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Koltuk ${index + 1}'),
                        content: const Text('Bu koltuğu rezerve etmek istiyor musunuz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Rezervasyon işlevi daha sonra eklenecek
                              Navigator.pop(context);
                            },
                            child: const Text('Rezerve Et'),
                          ),
                        ],
                      ),
                    );
                  },
            child: Container(
              decoration: BoxDecoration(
                color: isOccupied ? Colors.red.shade200 : Colors.green.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chair,
                    size: 32,
                    color: isOccupied ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Koltuk ${index + 1}',
                    style: TextStyle(
                      color: isOccupied ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
