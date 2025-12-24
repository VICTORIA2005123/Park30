import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/parking_repository.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Pull to refresh support
  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: () => _refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: "Reset Database",
            onPressed: () => _confirmReset(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ParkingRepository().getAnalyticsStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final stats = snapshot.data!;
          final revenue = stats['totalRevenue'];
          final bookings = stats['totalBookings'];
          final occupied = stats['occupied'];
          final totalSpots = stats['totalSpots'];
          final double occupancyRate = totalSpots > 0 ? occupied / totalSpots : 0.0;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("OVERVIEW", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 15),
                  // KPI Grid
                  Row(
                    children: [
                      _kpiCard(
                        "Revenue", 
                        "₹$revenue", 
                        Icons.currency_rupee_rounded, 
                        Colors.green
                      ),
                      const SizedBox(width: 15),
                      _kpiCard(
                        "Total Sessions", 
                        "$bookings", 
                        Icons.directions_car_filled_rounded, 
                        Colors.blue
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Occupancy Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Live Occupancy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("${(occupancyRate * 100).toInt()}% Full", style: TextStyle(color: _getColorForOccupancy(occupancyRate), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        LinearProgressIndicator(
                          value: occupancyRate,
                          backgroundColor: Colors.grey[200],
                          color: _getColorForOccupancy(occupancyRate),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statusPill("${stats['occupiedCars']} Cars", Colors.blue),
                            _statusPill("${stats['occupiedBikes']} Bikes", Colors.orange),
                            _statusPill("${totalSpots - occupied} Free", Colors.green),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text("LIVE OPERATIONS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 15),
                  
                  // Live List (Re-using logic but cleaner UI)
                  Container(
                    height: 400, // Fixed height for list in scroll view
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: ParkingRepository().getAllBookedSpots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                           return const Center(
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.check_circle_outline, size: 40, color: Colors.green),
                                 SizedBox(height: 10),
                                 Text("All inactive. No current parkers."),
                               ],
                             ),
                           );
                        }

                        final docs = snapshot.data!.docs;
                        return ListView.separated(
                          padding: const EdgeInsets.all(10),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                             final spot = docs[index];
                             return ListTile(
                               leading: CircleAvatar(
                                 backgroundColor: spot['type'] == 'car' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                 child: Icon(
                                   spot['type'] == 'car' ? Icons.directions_car : Icons.two_wheeler,
                                   color: spot['type'] == 'car' ? Colors.blue : Colors.orange,
                                   size: 20
                                  ),
                               ),
                               title: Text("Spot ${spot.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                               subtitle: Text("Booked by: ...${spot['bookedBy'].toString().substring(0, 5)}"), // Truncate UID or separate fetch
                               trailing: IconButton(
                                 icon: const Icon(Icons.info_outline, color: Colors.grey),
                                 onPressed: () {}, // Can show details dialog
                               ),
                             );
                          },
                        );
                      },
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

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(20),
           boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Color _getColorForOccupancy(double rate) {
    if (rate < 0.5) return Colors.green;
    if (rate < 0.8) return Colors.orange;
    return Colors.red;
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Database?"),
        content: const Text(
          "This will DELETE all spots and reset to P1-P70 / P1-P30.\nCannot be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            child: const Text("RESET NOW", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resetting database...")));
              
              try {
                await ParkingRepository().regenerateSpots();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Database Reset Complete!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
          ),
        ],
      ),
    );
  }
}