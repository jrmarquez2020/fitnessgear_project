import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/cart_screen.dart';
import 'package:flutter_application_1/profile_screen.dart';
import 'package:flutter_application_1/strength_training_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  int _selectedIndex = 2;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CartScreen()),
        (Route<dynamic> route) => false, // remove all previous routes
      );
    } else if (index == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => FavoriteScreen()),
        (Route<dynamic> route) => false, // remove all previous routes
      );
    } else if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => StrengthTrainingScreen()),
        (Route<dynamic> route) => false, // remove all previous routes
      );
    } else if (index == 3) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
        (Route<dynamic> route) => false, // remove all previous routes
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final itemsSnapshot =
        await FirebaseFirestore.instance.collection('items').get();
    List<Map<String, dynamic>> favoriteItems = [];

    for (var itemDoc in itemsSnapshot.docs) {
      final favoriteDoc =
          await itemDoc.reference.collection('favorite').doc(userId).get();

      if (favoriteDoc.exists) {
        final itemData = itemDoc.data();
        favoriteItems.add(itemData);
      }
    }

    return favoriteItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No favorites yet!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final favorites = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final product = favorites[index];
              return Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Image.network(
                    product['image'], // Make sure `image` exists in Firestore
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                  ),
                  title: Text(
                    product['name'] ?? 'No Name',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    product['price']?.toString() ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
