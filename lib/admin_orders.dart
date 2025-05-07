import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class admin_orders extends StatefulWidget {
  const admin_orders({super.key});

  @override
  State<admin_orders> createState() => _admin_ordersState();
}

class _admin_ordersState extends State<admin_orders> {
  @override
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('orders').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;

      return data;
    }).toList();
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

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = List<Map<String, dynamic>>.from(order['items']);

              return Card(
                color: Colors.grey[900],
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            "Name: ${order['firstName']} ${order['lastName']}",
                            style: TextStyle(color: Colors.white),
                          ),

                          Text(
                            "${order['status']}",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Container(
                        width: 400,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white, // You can change the color
                            width: 0.5, // Border thickness
                          ),
                          borderRadius: BorderRadius.circular(
                            5,
                          ), // Optional: rounded corners
                        ),
                        padding: EdgeInsets.all(12), // Optional: inner spacing
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Column(
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      color: Colors.blue,
                                    ),
                                    Icon(
                                      Icons.phone_callback_rounded,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${order['address']}",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      "${order['contact']}",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                    ],
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Image.network(
                                item['image'],
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                  );
                                },
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "₱${item['price']} x ${item['quantity']}",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 8),

                      Text(
                        "Total: ₱${order['total']}",
                        style: TextStyle(color: Colors.white),
                      ),
                      order['status'] == "pending"
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text("Are you sure?"),
                                          content: Text(
                                            'Do you really want to deny (delete) this order?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  context,
                                                ).pop(); // Close dialog
                                              },
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                updateOrderStatus(
                                                  order['userId'],
                                                  order['orderId'],
                                                  'declined',
                                                );
                                                deleteOrder(order['orderId']);

                                                Navigator.of(context).pop();
                                              },

                                              child: Text('Yes'),
                                            ),
                                          ],
                                        ),
                                  );
                                  // Ensure `orderId` is available
                                },
                                child: Text(
                                  "Deny",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                        Colors.red,
                                      ),
                                ),
                              ),

                              SizedBox(width: 5),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text("Are you sure?"),
                                          content: Text(
                                            'Accepted or will change the status in transit.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  context,
                                                ).pop(); // Close dialog
                                              },
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                updateOrderStatus(
                                                  order['userId'],
                                                  order['id'],
                                                  'transit',
                                                );
                                                Navigator.of(context).pop();
                                              },

                                              child: Text('Yes'),
                                            ),
                                          ],
                                        ),
                                  );

                                  // make sure orderId exists in `order`
                                },
                                child: Text(
                                  "Accept",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                        Colors.green,
                                      ),
                                ),
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(width: 5),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text("Are you sure?"),
                                          content: Text(
                                            'Make sure the item was paid and recieved by the client',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(
                                                  context,
                                                ).pop(); // Close dialog
                                              },
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                updateOrderStatus(
                                                  order['userId'],
                                                  order['id'],
                                                  'delivered',
                                                );
                                                moveToTransactions(
                                                  order['orderId'],
                                                );

                                                Navigator.of(context).pop();
                                              },

                                              child: Text('Yes'),
                                            ),
                                          ],
                                        ),
                                  );
                                  // Make sure `orderId` exists in `order`
                                },
                                child: Text(
                                  "Order Received",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                        const Color.fromARGB(255, 238, 171, 47),
                                      ),
                                ),
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
