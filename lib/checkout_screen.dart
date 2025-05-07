// checkout_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/strength_training_screen.dart';
import 'cart_data.dart'; // Import the global cart list

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  double getTotalPrice() {
    double total = 0.0;
    for (var item in cartItems) {
      // Clean the price string to remove non-numeric characters (except the decimal point)
      String cleanedPrice = item.price.replaceAll(RegExp(r'[^\d.]'), '');
      double itemPrice = double.tryParse(cleanedPrice) ?? 0.0;
      total += itemPrice;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    fetchUserCartWithTotal();
  }

  Future<Map<String, dynamic>> fetchUserCartWithTotal() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {'items': [], 'total': 0.0};

    final itemsCollection = FirebaseFirestore.instance.collection('items');
    final allItemsSnapshot = await itemsCollection.get();

    List<Map<String, dynamic>> cartItems = [];
    double grandTotal = 0.0;

    for (var itemDoc in allItemsSnapshot.docs) {
      final itemId = itemDoc.id;
      final price = (itemDoc.data()['price'] ?? 0).toDouble();

      final cartDoc =
          await itemsCollection
              .doc(itemId)
              .collection('addCart')
              .doc(userId)
              .get();

      if (cartDoc.exists) {
        final quantity = (cartDoc.data()?['quantity'] ?? 0).toInt();
        final itemTotal = price * quantity;

        grandTotal += itemTotal;

        cartItems.add({
          'itemId': itemId,
          'name': itemDoc.data()['name'] ?? 'No Name',
          'image': itemDoc.data()['image'] ?? '',
          'price': price,
          'quantity': quantity,
          'total': itemTotal,
        });
      }
    }

    return {'items': cartItems, 'total': grandTotal};
  }

  Future<void> placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final email = user.email ?? 'no-email';

    try {
      // 1. Fetch user's profile data
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userDoc.exists) {
        print('User profile not found.');
        return;
      }

      final userData = userDoc.data()!;
      final address = userData['address'] ?? 'no-address';
      final firstName = userData['firstName'] ?? 'no-first-name';
      final lastName = userData['lastName'] ?? 'no-last-name';
      final contact = userData['contact'] ?? 'no-contact';

      // 2. Fetch cart items and total
      final cartData = await fetchUserCartWithTotal();
      final items = cartData['items'] as List<Map<String, dynamic>>;
      final total = (cartData['total'] as num).toDouble();

      if (items.isEmpty) {
        print('Cart is empty, nothing to order.');
        return;
      }

      // 3. Create order document in "orders" collection
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final orderData = {
        'orderId': orderRef.id,
        'address': address,
        'contact': contact,
        'firstName': firstName,
        'lastName': lastName,
        'userId': userId,
        'email': email,
        'items': items,
        'total': total,
        'orderedAt': Timestamp.now(),
        'status': 'pending',
      };

      // 5. Save order to both collections
      await orderRef.set(orderData);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection("myOrders")
          .doc(orderRef.id)
          .set(orderData);

      print('Order placed successfully!');

      // 4. Clear cart items
      for (var item in items) {
        final itemId = item['itemId'];
        await FirebaseFirestore.instance
            .collection('items')
            .doc(itemId)
            .collection('addCart')
            .doc(userId)
            .delete();
      }

      print('Cart cleared after order.');
    } catch (e) {
      print('Error placing order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total price
    double total = cartItems.fold(
      0,
      (sum, item) =>
          sum +
          double.parse(
            item.price
                .replaceAll('₱', '')
                .replaceAll(',', '')
                .replaceAll(' PHP', ''),
          ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button icon
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Order Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: fetchUserCartWithTotal(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    (snapshot.data?['items'] as List).isEmpty) {
                  return const Center(
                    child: Text(
                      'No items in cart!',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                // ✅ PLACE IT HERE:
                final cartItems =
                    snapshot.data!['items'] as List<Map<String, dynamic>>;
                final total =
                    (snapshot.data!['total'] as num)
                        .toDouble(); // ✅ this line right here

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final product = cartItems[index];
                          return Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading:
                                  product['image'] != null
                                      ? Image.network(
                                        product['image'],
                                        fit: BoxFit.cover,
                                        height: 50,
                                        width: 50,
                                      )
                                      : const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white,
                                      ),
                              title: Text(
                                product['name'] ?? 'No Name',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '₱ ${product['price']?.toStringAsFixed(2) ?? ''} x ${product['quantity']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ✅ Display Total
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          Text(
                            '₱${total.toStringAsFixed(2)}', // this will now work!
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      placeOrder();
                      confirmation_dialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff587ed5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show success dialog after placing order
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Order Successful'),
            content: const Text('Thank you for your purchase!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void confirmation_dialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Text('Are you sure to your order?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Yes
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                cartItems.clear();
                Navigator.of(context).pop(true);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StrengthTrainingScreen(),
                  ),
                  (Route<dynamic> route) => false, // remove all previous routes
                );
                _showSuccessDialog(context);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
