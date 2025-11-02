import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/toy.dart';

class SaleScreen extends StatelessWidget {
  const SaleScreen({Key? key}) : super(key: key);

  // Updated list of sale toys to match the correct Toy model
  List<Toy> getSaleToys() {
    final List<Toy> allToys = [
      // Toy Guns
      Toy(id: 'TG01', name: 'Laser Ray Gun', category: 'Toy Guns', rfidUid: 'TG01_UID', price: 1499.99, imageUrl: 'assets/images/toy_placeholder.png'),
      Toy(id: 'TG02', name: 'Water Blaster 3000', category: 'Toy Guns', rfidUid: 'TG02_UID', price: 999.99, imageUrl: 'assets/images/toy_placeholder.png'),
      // Action Figures
      Toy(id: 'AF01', name: 'Galaxy Commander', category: 'Action Figures', rfidUid: 'AF01_UID', price: 649.99, imageUrl: 'assets/images/toy_placeholder.png'),
      Toy(id: 'AF02', name: 'Jungle Explorer', category: 'Action Figures', rfidUid: 'AF02_UID', price: 599.99, imageUrl: 'assets/images/toy_placeholder.png'),
      // Dolls
      Toy(id: 'DL01', name: 'Princess Star', category: 'Dolls', rfidUid: 'DL01_UID', price: 1149.99, imageUrl: 'assets/images/toy_placeholder.png'),
      Toy(id: 'DL02', name: 'Fashionista Doll', category: 'Dolls', rfidUid: 'DL02_UID', price: 1249.99, imageUrl: 'assets/images/toy_placeholder.png'),
      // Puzzles
      Toy(id: 'PZ01', name: '1000pc World Map', category: 'Puzzles', rfidUid: 'PZ01_UID', price: 799.99, imageUrl: 'assets/images/toy_placeholder.png'),
      Toy(id: 'PZ02', name: '3D Wooden Dinosaur', category: 'Puzzles', rfidUid: 'PZ02_UID', price: 899.99, imageUrl: 'assets/images/toy_placeholder.png'),
    ];

    // Apply a 20% discount to all sale items
    return allToys.map((toy) {
      return Toy(
        id: toy.id,
        name: toy.name,
        category: toy.category,
        rfidUid: toy.rfidUid,
        price: toy.price * 0.8, // Apply 20% discount
        imageUrl: toy.imageUrl,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final saleToys = getSaleToys();
    final currencyFormatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return ListView.builder(
      itemCount: saleToys.length,
      itemBuilder: (context, index) {
        final toy = saleToys[index];
        final originalPrice = toy.price / 0.8; // Calculate original price

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: Image.asset(
              toy.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 40),
            ),
            title: Text(toy.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currencyFormatter.format(originalPrice),
                  style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                ),
                Text(
                  currencyFormatter.format(toy.price),
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // Add to cart functionality can be added here
              },
              child: const Text('Add to Cart'),
            ),
          ),
        );
      },
    );
  }
}
