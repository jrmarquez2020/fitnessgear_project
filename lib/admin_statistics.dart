import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class admin_statistics extends StatefulWidget {
  const admin_statistics({super.key});

  @override
  State<admin_statistics> createState() => _admin_statisticsState();
}

class _admin_statisticsState extends State<admin_statistics> {
  Map<String, double> totalSalesPerMonth = {};
  Map<String, int> totalOrdersPerMonth = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTransactionData();
  }

  Future<void> fetchTransactionData() async {
    final transactions =
        await FirebaseFirestore.instance.collection('transactions').get();

    for (var doc in transactions.docs) {
      final data = doc.data();
      final Timestamp orderedAt = data['orderedAt'];
      final double total = (data['total'] ?? 0).toDouble();

      final String month = DateFormat('MMM').format(orderedAt.toDate());

      totalSalesPerMonth[month] = (totalSalesPerMonth[month] ?? 0) + total;
      totalOrdersPerMonth[month] = (totalOrdersPerMonth[month] ?? 0) + 1;
    }

    setState(() {
      isLoading = false;
    });
  }

  double _calculateOverallAverage() {
    final totalSales = totalSalesPerMonth.values.fold(0.0, (a, b) => a + b);

    final totalOrders = totalOrdersPerMonth.values.fold(0, (a, b) => a + b);
    return totalOrders > 0 ? totalSales / totalOrders : 0;
  }

  Widget _buildStatCard({required String title, required String value}) {
    return Container(
      width: 110,
      height: 60,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 52, 52, 52),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months =
        totalSalesPerMonth.keys.toList()..sort(
          (a, b) => DateFormat(
            'MMM',
          ).parse(a).month.compareTo(DateFormat('MMM').parse(b).month),
        );

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        title: const Text("Statistics", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                          title: "Sales Total",
                          value: totalSalesPerMonth.values
                              .fold(0.0, (a, b) => a + b)
                              .toStringAsFixed(2),
                        ),
                        _buildStatCard(
                          title: "Avg Order Value",
                          value: _calculateOverallAverage().toStringAsFixed(2),
                        ),
                        _buildStatCard(
                          title: "Total Orders",
                          value:
                              totalOrdersPerMonth.values
                                  .fold(0, (a, b) => a + b)
                                  .toString(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment:
                              BarChartAlignment.spaceAround, // More spacing
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (value, _) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      months[value.toInt()],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget:
                                    (value, _) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barGroups: List.generate(months.length, (index) {
                            final month = months[index];
                            final total = totalSalesPerMonth[month] ?? 0;
                            final orders = totalOrdersPerMonth[month] ?? 0;
                            final avg = orders > 0 ? total / orders : 0;

                            return BarChartGroupData(
                              x: index,
                              barsSpace:
                                  6, // 👈 spacing between bars in the same group
                              barRods: [
                                BarChartRodData(
                                  toY: total,
                                  color: Colors.blue,
                                  width: 6, // 👈 thinner bars
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                BarChartRodData(
                                  toY: avg.toDouble(),
                                  color: Colors.orange,
                                  width: 6,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                BarChartRodData(
                                  toY: orders.toDouble(),
                                  color: Colors.green,
                                  width: 6,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(enabled: true),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
