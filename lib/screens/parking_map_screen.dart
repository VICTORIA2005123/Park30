import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/parking_spot_model.dart';
import '../repositories/parking_repository.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import 'payment_screen.dart';

class ParkingMapScreen extends StatelessWidget {
  final String parkingType;

  const ParkingMapScreen({super.key, required this.parkingType});

  String get backgroundImage => parkingType == 'car'
      ? 'assets/car_parking_map.png'
      : 'assets/motorcycle_parking_map.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21), // Deep dark background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: const BackButton(color: Colors.white),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.cyanAccent.withOpacity(0.8),
              child: IconButton(
                icon: const Icon(Icons.directions, color: Colors.black),
                onPressed: () => _launchMaps(context),
                tooltip: "Get Directions",
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Stats Header (Fixed at top)
          Container(
            padding: const EdgeInsets.only(top: 100, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF0A0E21), const Color(0xFF0A0E21).withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parkingType == 'car' ? "CAR ZONE" : "BIKE ZONE",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Live status of all spots",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      // We'll update this count dynamically if needed, or just show label
                      const Text("Available", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ParkingRepository().getSpotsByType(parkingType),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final spots = snapshot.data!.docs
                    .map((doc) => ParkingSpot.fromFirestore(doc))
                    .toList();
                
                // Sort by Number (P1, P2, ... P70)
                spots.sort((a, b) {
                  // ID Format: 'car-P10' or 'bike-P5'
                  // We split by 'P' and try to parse the last part
                  try {
                    int numA = int.parse(a.id.split('P').last);
                    int numB = int.parse(b.id.split('P').last);
                    return numA.compareTo(numB);
                  } catch (e) {
                    return a.id.compareTo(b.id); // Fallback
                  }
                });

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: spots.length,
                  itemBuilder: (context, index) {
                    final spot = spots[index];
                    return _buildGridSpotCard(context, spot);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _findAndOpenNearest(context),
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.near_me_rounded),
        label: const Text("Find Nearest"),
      ),
    );
  }

  Future<void> _launchMaps(BuildContext context) async {
    try {
      const double lat = AppConstants.parkingLatitude;
      const double lng = AppConstants.parkingLongitude;
      
      final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
      final Uri webUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(webUrl)) {
         await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch maps")),
          );
        }
      }
    } catch (e) {
      debugPrint("Map Launch Error: $e");
    }
  }

  Future<void> _findAndOpenNearest(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Locating nearest free spot..."), duration: Duration(milliseconds: 800)),
    );

    try {
      // FIX: Query all available spots and sort client-side to avoid missing Index error
      final query = await FirebaseFirestore.instance
          .collection('parking_spots')
          .where('type', isEqualTo: parkingType)
          .where('status', isEqualTo: 'available')
          .get();

      if (query.docs.isNotEmpty) {
        final spots = query.docs.map((doc) => ParkingSpot.fromFirestore(doc)).toList();
        
        // Sort by Number (P1, P2 ... P70)
        spots.sort((a, b) {
           try {
             int numA = int.parse(a.id.split('P').last);
             int numB = int.parse(b.id.split('P').last);
             return numA.compareTo(numB);
           } catch (e) {
             return a.id.compareTo(b.id);
           }
        });

        final bestSpot = spots.first;
        
        if (context.mounted) {
          _showSpotDetailsSheet(context, bestSpot, isMySpot: false);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No available spots found right now.")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error finding nearest: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error locating spot: $e")),
        );
      }
    }
  }

  void _handleSpotTap(BuildContext context, ParkingSpot spot) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final List currentBookings = userDoc.data()?['currentBookings'] ?? [];

    if (spot.bookedBy == user.uid) {
      // Show "My Spot" details
       _showSpotDetailsSheet(context, spot, isMySpot: true);
    } else if (spot.status == 'available' && currentBookings.length < 3) {
      // Show Booking details
       _showSpotDetailsSheet(context, spot, isMySpot: false);
    } else if (spot.status != 'available') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spot is currently occupied')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 3 spots allowed')),
      );
    }
  }
  void _showSpotDetailsSheet(BuildContext context, ParkingSpot spot, {required bool isMySpot}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _SpotSheetContent(spot: spot, isMySpot: isMySpot);
      },
    );
  }

  Widget _buildGridSpotCard(BuildContext context, ParkingSpot spot) {
    final user = AuthService().currentUser;
    final bool isMine = spot.bookedBy == user?.uid;
    final bool isAvailable = spot.status == 'available';

    Color baseColor;
    IconData icon;

    if (isMine) {
      baseColor = Colors.amber;
      icon = Icons.star_rounded;
    } else if (isAvailable) {
      baseColor = Colors.greenAccent;
      icon = Icons.local_parking;
    } else {
      baseColor = Colors.redAccent;
      icon = parkingType == 'car' ? Icons.directions_car : Icons.two_wheeler;
    }

    return GestureDetector(
      onTap: () {
        // Reuse the logic (BottomSheet)
        if (isMine) {
           _showSpotDetailsSheet(context, spot, isMySpot: true);
        } else if (isAvailable) {
           _showSpotDetailsSheet(context, spot, isMySpot: false);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Spot occupied")));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: baseColor.withOpacity(isMine || isAvailable ? 0.5 : 0.2), 
            width: isMine ? 2 : 1
          ),
          boxShadow: [
            if (isMine || isAvailable)
              BoxShadow(
                color: baseColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4)
              )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: baseColor.withOpacity(0.9), size: 32),
            const SizedBox(height: 8),
            Text(
              spot.id.split('-').last,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotSheetContent extends StatefulWidget {
  final ParkingSpot spot;
  final bool isMySpot;

  const _SpotSheetContent({required this.spot, required this.isMySpot});

  @override
  State<_SpotSheetContent> createState() => _SpotSheetContentState();
}

class _SpotSheetContentState extends State<_SpotSheetContent> {
  double _selectedHours = 1.0;
  static const int pricePerHour = 40;

  @override
  Widget build(BuildContext context) {
    final price = (_selectedHours * pricePerHour).round();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Spot ${widget.spot.id.split('-').last}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: widget.isMySpot ? Colors.amber : (widget.spot.status == 'available' ? Colors.greenAccent : Colors.redAccent),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: (widget.isMySpot ? Colors.amber : (widget.spot.status == 'available' ? Colors.greenAccent : Colors.redAccent)).withOpacity(0.5), blurRadius: 5)],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isMySpot ? "YOUR BOOKING" : (widget.spot.status == 'available' ? "AVAILABLE NOW" : "OCCUPIED"),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      widget.spot.type == 'car' ? Icons.directions_car_filled : Icons.two_wheeler,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (!widget.isMySpot) ...[
                // Duration Slider
                Text("Select Duration", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _selectedHours,
                        min: 1,
                        max: 12,
                        divisions: 11,
                        activeColor: Colors.cyanAccent,
                        inactiveColor: Colors.white10,
                        label: "${_selectedHours.round()} hrs",
                        onChanged: (val) => setState(() => _selectedHours = val),
                      ),
                    ),
                    Text(
                      "${_selectedHours.round()} hrs",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Info Grid
              Row(
                children: [
                   _infoTile("Price", "₹$price"), // Live Price
                   _infoTile("Rate", "₹40/hr"),
                   _infoTile("Floor", "G-01"),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                     Navigator.pop(context); // Close sheet
                     if (widget.isMySpot) {
                       _releaseSpot(widget.spot.id);
                     } else {
                       _bookSpot(widget.spot.id, _selectedHours);
                     }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isMySpot ? Colors.redAccent : Colors.cyanAccent,
                    foregroundColor: widget.isMySpot ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.isMySpot ? "RELEASE SPOT" : "BOOK FOR ₹$price",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _bookSpot(String spotId, double duration) async {
    final user = AuthService().currentUser;
    // 1. Calculate Price
    final price = (duration * pricePerHour).toDouble();

    // 2. Navigate to Payment Screen
    final bool? paymentSuccess = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => PaymentScreen(
        amount: price, 
        spotName: "Spot ${spotId.split('-').last}" // Extract P-number
      ))
    );

    if (paymentSuccess == true) {
       // 3. If Paid, Proceed to Book
       try {
         await ParkingRepository().bookSpot(spotId, user!.uid, duration);
         
         // Trigger Confirmation Notification
         await NotificationService().showNotification(
           id: DateTime.now().millisecondsSinceEpoch ~/ 1000, 
           title: "Payment Successful! ✅", 
           body: "Booking confirmed for Spot ${spotId.split('-').last}. Total: ₹${price.toInt()}"
         );

         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Booking Successful!"), backgroundColor: Colors.green)
            );
         }
       } catch (e) {
         debugPrint(e.toString());
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Failed"), backgroundColor: Colors.red));
         }
       }
    } else {
      // Payment Cancelled
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Cancelled")));
       }
    }
  }

  Future<void> _releaseSpot(String spotId) async {
      final user = AuthService().currentUser;
      try {
        await ParkingRepository().releaseSpot(spotId, user!.uid);
      } catch (e) {
        debugPrint(e.toString());
      }
  }
}