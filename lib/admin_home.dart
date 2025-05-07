import 'package:flutter/material.dart';
import 'package:flutter_application_1/admin_orders.dart';
import 'package:flutter_application_1/admin_products.dart';
import 'package:flutter_application_1/admin_statistics.dart';
import 'package:flutter_application_1/admin_transaction.dart';
import 'package:flutter_application_1/main.dart';

class admin_home extends StatefulWidget {
  const admin_home({super.key});

  @override
  State<admin_home> createState() => _admin_homeState();
}

class _admin_homeState extends State<admin_home> {
  @override
  final List<String> imageList = [
    'assets/images/transactions.png',
    'assets/images/products.png',
    'assets/images/orders.png',
    'assets/images/statistics.png',
  ];
  final List<String> gridName = [
    'Transaction',
    'Products',
    'Orders',
    'Statics',
  ];
  void changeScreen(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const admin_transactions(),
        ), // Change to CheckoutScreen
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const admin_products(),
        ), // Change to CheckoutScreen
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const admin_orders(),
        ), // Change to CheckoutScreen
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const admin_statistics(),
        ), // Change to CheckoutScreen
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false, // remove all previous routes
              );
            },
            icon: Icon(Icons.logout_outlined, color: Colors.red),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(height: 110),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.jpg', width: 35, height: 35),
              SizedBox(width: 10),
              Text(
                'Fitness Gear Hub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            'Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: imageList.length,
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    changeScreen(index);
                    print(imageList[index]);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[900],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(height: 18),
                              Image.asset(imageList[index], width: 90),
                              Text(
                                gridName[index],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
