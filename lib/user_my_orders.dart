import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class myOrder extends StatefulWidget {
  const myOrder({Key? key}) : super(key: key);

  @override
  State<myOrder> createState() => _myOrderState();
}

class _myOrderState extends State<myOrder> {
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final ordersSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('myOrders')
            .get();

    List<Map<String, dynamic>> orders = [];

    for (var orderDoc in ordersSnapshot.docs) {
      final orderData = orderDoc.data();
      orderData['id'] = orderDoc.id; // include the doc ID
      orders.add(orderData);
    }

    print(orders); // For debugging
    return orders;
  }

  Future<void> moveToTransactions(String orderId) async {
    try {
      final orderDoc =
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .get();

      if (!orderDoc.exists) {
        print('Order not found.');
        return;
      }

      final orderData = orderDoc.data()!;
      final transactionRef = FirebaseFirestore.instance
          .collection('transactions')
          .doc(orderId);

      await transactionRef.set(orderData);

      print('Order copied to transactions!');
      deleteOrder(orderId);
    } catch (e) {
      print('Error moving order to transactions: $e');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .delete();

      print('Order $orderId deleted successfully');
    } catch (e) {
      print('Error deleting order: $e');
    }
    setState(() {});
  }

  Future<void> updateOrderStatus(
    String userId,
    String orderId,
    String newStatus,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Update the order status
      await firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
      await firestore
          .collection('users')
          .doc(userId)
          .collection('myOrders')
          .doc(orderId)
          .update({'status': newStatus});

      print('Order status updated to $newStatus');

      // If the new status is 'transit', update item stocks
      if (newStatus == 'transit') {
        final orderSnapshot =
            await firestore.collection('orders').doc(orderId).get();
        final orderData = orderSnapshot.data();

        if (orderData != null && orderData.containsKey('items')) {
          final List<dynamic> items = orderData['items'];

          for (var item in items) {
            final String itemId = item['itemId'];
            final int quantityOrdered = item['quantity'];

            final itemRef = firestore.collection('items').doc(itemId);

            await firestore.runTransaction((transaction) async {
              final itemSnapshot = await transaction.get(itemRef);

              if (itemSnapshot.exists) {
                final int currentStock = itemSnapshot['stocks'] ?? 0;
                final int updatedStock = currentStock - quantityOrdered;

                // Ensure stock doesn't go negative
                final int safeStock = updatedStock < 0 ? 0 : updatedStock;

                transaction.update(itemRef, {'stocks': safeStock});
                print(
                  'Stock for item $itemId updated: $currentStock -> $safeStock',
                );
              } else {
                print('Item with ID $itemId not found.');
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error updating order status or stock: $e');
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button icon
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
        title: const Text('My order', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        automaticallyImplyLeading: true,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No Orders Yet!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final orders = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children:
                orders.expand((order) {
                  final items = List<Map<String, dynamic>>.from(
                    order['items'] ?? [],
                  );
                  final status = (order['status'] ?? '');

                  return items.map((item) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          color: Colors.black38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: SizedBox(
                            height:
                                120, // <-- Change this value to your desired height
                            child: ListTile(
                              leading: Image.network(
                                item['image'] ??
                                    'https://via.placeholder.com/50',
                                fit: BoxFit.cover,
                                height: 50,
                                width: 50,
                              ),
                              title: Text(
                                item['name'] ?? 'No Name',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '₱${item['price']?.toString() ?? '0'} x ${item['quantity']?.toString() ?? '1'}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing:
                                  status == 'transit'
                                      ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: const Text(
                                                        "Are you sure?",
                                                      ),
                                                      content: const Text(
                                                        "Make sure the item was paid and received.",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            updateOrderStatus(
                                                              order['userId'],
                                                              order['orderId'],
                                                              'delivered',
                                                            );
                                                            moveToTransactions(
                                                              order['orderId'],
                                                            );
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          },
                                                          child: const Text(
                                                            'Yes',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                    255,
                                                    238,
                                                    171,
                                                    47,
                                                  ),
                                              minimumSize: const Size(
                                                50,
                                                30,
                                              ), // width, height
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                            ),
                                            child: const Text(
                                              "Order Received",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            order['status'],
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                        ],
                                      ),
                            ),
                          ),
                        ),

                        Text(
                          'Total: ₱${item['total']?.toString() ?? '0'}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Divider(color: Colors.white24, thickness: 1),
                      ],
                    );
                  });
                }).toList(),
          );
        },
      ),
    );
  }
}
