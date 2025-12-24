import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/parking_spot_model.dart';
import '../repositories/parking_repository.dart';
import '../widgets/timer_card.dart';
import 'parking_map_screen.dart';
import 'admin_screen.dart'; 
import 'profile_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService().currentUser;

    // Safety check for unauthenticated access
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Session Expired. Please login again.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'PARK30', 
          style: TextStyle(
            color: Color(0xFF1565C0), 
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.account_circle_rounded, color: Colors.cyanAccent),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const ProfileScreen())
            ),
          ),
          FutureBuilder<bool>(
            future: AuthService().isAdmin,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return IconButton(
                  tooltip: 'Admin Dashboard',
                  icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF1565C0)),
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const AdminScreen())
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(context),
      extendBody: true, // Required for transparent BottomNav
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color(0xFF0F2027),
              Color(0xFF203A43), 
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 60), // Space for status bar
                // Branding Header
                Hero(
                  tag: 'app_logo',
                  child: Image.asset('assets/images/30 minute timer.png', height: 100),
                ),
                const SizedBox(height: 15),
                const Text(
                  'PARK IT, SECURE IT!', 
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'Campus Smart Management', 
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 40),

                // Active Bookings Header
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "MY ACTIVE SESSIONS", 
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(color: Colors.white10, thickness: 1),
                ),
                
                // Real-time Booking Stream
                StreamBuilder<QuerySnapshot>(
                  stream: ParkingRepository().getBookedSpotsForUser(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blue));
                    }
                    
                    final bookedSpots = snapshot.data?.docs ?? [];
                    
                    if (bookedSpots.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Column(
                      children: bookedSpots.map((doc) {
                        final spot = ParkingSpot.fromFirestore(doc);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TimerCard(
                            spotId: spot.id,
                            startTime: spot.bookingTimestamp ?? DateTime.now(),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF192233),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to exit PARK30?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              AuthService().signOut();
              Navigator.pop(context);
            }, 
            child: const Text("Logout", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Icon(Icons.directions_run_rounded, color: Colors.cyanAccent, size: 40),
          SizedBox(height: 15),
          Text(
            "No active bookings.\nYour spot is waiting!", 
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBottomNav(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 15, 24, 30),
          child: Row(
            children: [
              Expanded(child: _navBtn(context, 'CAR', Icons.directions_car_filled_rounded, 'car')),
              const SizedBox(width: 15),
              Expanded(child: _navBtn(context, 'BIKE', Icons.two_wheeler_rounded, 'motorcycle')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(BuildContext context, String label, IconData icon, String type) {
    return SizedBox(
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
             BoxShadow(
              color: const Color(0xFF1976D2).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => ParkingMapScreen(parkingType: type)),
          ),
          icon: Icon(icon, size: 22),
          label: Text(
            label, 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.1),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2), 
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0, // Shadow handled by container
          ),
        ),
      ),
    );
  }
}