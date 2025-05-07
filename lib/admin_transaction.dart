import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class admin_transactions extends StatefulWidget {
  const admin_transactions({super.key});

  @override
  State<admin_transactions> createState() => _admin_transactionsState();
}

class _admin_transactionsState extends State<admin_transactions> {
  Future<List<Map<String, dynamic>>> fetchTransaction() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('transactions').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Transactions", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTransaction(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          final transactions = snapshot.data!;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final items = List<Map<String, dynamic>>.from(
                transaction['items'],
              );

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
                            "Name: ${transaction['firstName']} ${transaction['lastName']}",
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
                                      "${transaction['address']}",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      "${transaction['contact']}",
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
                        "Total: ₱${transaction['total']}",
                        style: TextStyle(color: Colors.white),
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
