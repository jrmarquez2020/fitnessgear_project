import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/profile_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'favorite_screen.dart';

class StrengthTrainingScreen extends StatefulWidget {
  const StrengthTrainingScreen({super.key});

  @override
  _StrengthTrainingScreenState createState() => _StrengthTrainingScreenState();
}

class _StrengthTrainingScreenState extends State<StrengthTrainingScreen> {
  List<Map<String, dynamic>> products = [];
  List<String> favoriteIds = [];

  List<bool> favorites = [];

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final itemsSnapshot =
        await FirebaseFirestore.instance.collection('items').get();

    List<Map<String, dynamic>> tempItems = [];
    List<bool> tempFavorites = [];

    for (var itemDoc in itemsSnapshot.docs) {
      final itemData = itemDoc.data();
      itemData['id'] = itemDoc.id; // Include item ID for reference
      tempItems.add(itemData);

      final favoriteDoc =
          await itemDoc.reference.collection('favorite').doc(userId).get();

      tempFavorites.add(favoriteDoc.exists); // true if user favorited
    }

    favorites = tempFavorites;

    print(favorites);
    fetchProductsFromFirestore();
    // Debug print
  }

  Future<void> fetchProductsFromFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('items').get();
      final fetchedProducts =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'name': data['name'],
              'price': '₱${data['price'].toStringAsFixed(2)} PHP',
              'image': data['image'],
              'description': data['description'],
              'stocks': data['stocks'],
              'id': data['id'],
            };
          }).toList();

      setState(() {
        products = fetchedProducts;
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  Future<void> toggleFavorite(String itemId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final favoriteDocRef = FirebaseFirestore.instance
        .collection('items')
        .doc(itemId)
        .collection('favorite')
        .doc(userId); // Use user ID as the doc ID

    final docSnapshot = await favoriteDocRef.get();

    if (docSnapshot.exists) {
      // Already a favorite → remove it
      await favoriteDocRef.delete();
      print('Removed from favorites');
    } else {
      // Not a favorite → add it
      await favoriteDocRef.set({
        'userId': userId,
        'favoritedAt': Timestamp.now(),
      });
      print('Added to favorites');
    }

    setState(() {
      fetchFavorites();
    });
  }

  int _selectedIndex = 0;

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

  // void _toggleFavorite(Map<String, String> product) {
  //   setState(() {
  //     if (favorites.contains(product)) {
  //       favorites.remove(product);
  //     } else {
  //       favorites.add(product);
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Centered Fitness Gear Hub Text
            Center(
              child: Text(
                'Fitness Gear Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ), // Add some spacing between the two texts
            // Strength Training Text
            const Center(
              child: Text(
                'Strength Training',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 20),
            products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                :
                // GridView of Products
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    // final isFavorite = favorites.contains(product);
                    final isFavorites =
                        favorites.length > index && favorites[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProductDetailScreen(
                                  id: product['id'],
                                  productName: product['name'],
                                  productPrice: product['price'],
                                  productImage: product['image'],
                                  productDescription: product['description'],
                                ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // If using asset path stored in Firestore
                            Image.network(
                              product['image'],
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 10),

                            // Product Name
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                product['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Price & Favorite
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    product['price'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isFavorites
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      toggleFavorite(product['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
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
