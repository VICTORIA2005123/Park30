import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSpot {
  final String id;
  final String status;
  final String type;
  final double x;
  final double y;
  final String? bookedBy;
  final DateTime? bookingTimestamp; // NEW

  ParkingSpot({
    required this.id,
    required this.status,
    required this.type,
    required this.x,
    required this.y,
    this.bookedBy,
    this.bookingTimestamp, // NEW
  });

  factory ParkingSpot.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ParkingSpot(
      id: doc.id,
      status: data['status'] ?? 'unknown',
      type: data['type'] ?? 'unknown',
      x: (data['x'] ?? 0.0).toDouble(),
      y: (data['y'] ?? 0.0).toDouble(),
      bookedBy: data['bookedBy'],
      // Handle Firebase Timestamp conversion
      bookingTimestamp: (data['bookingTimestamp'] as Timestamp?)?.toDate(),
    );
  }
}
