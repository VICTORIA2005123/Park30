import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_spot_model.dart';
import '../services/notification_service.dart';

class ParkingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getBookedSpotsForUser(String userId) {
    return _firestore
          .collection('parkingSpots')
          .where('bookedBy', isEqualTo: userId)
          .snapshots();
  }

  Stream<QuerySnapshot> getSpotsByType(String type) {
    return _firestore
          .collection('parkingSpots')
          .where('type', isEqualTo: type)
          .snapshots();
  }

  Stream<QuerySnapshot> getAllBookedSpots() {
    return _firestore
          .collection('parkingSpots')
          .where('status', isEqualTo: 'booked')
          .snapshots();
  }

  Future<DocumentSnapshot> getUser(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  // Business Rule: 20 Rs per 30 mins = 40 Rs per hour
  static const int pricePerHour = 40;

  Future<void> bookSpot(String spotId, String userId, double durationInHours) async {
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(minutes: (durationInHours * 60).toInt()));
    final cost = (durationInHours * pricePerHour).round();

    WriteBatch batch = _firestore.batch();
    DocumentReference spotRef = _firestore.collection('parkingSpots').doc(spotId);
    DocumentReference userRef = _firestore.collection('users').doc(userId);
    DocumentReference historyRef = _firestore.collection('booking_history').doc();

    // 1. Update Spot Status
    batch.set(spotRef, {
      'status': 'booked',
      'bookedBy': userId,
      'bookingStartTime': Timestamp.fromDate(startTime),
      'bookingEndTime': Timestamp.fromDate(endTime),
    }, SetOptions(merge: true));

    // 2. Update User's Active List
    batch.set(userRef, {
      'currentBookings': FieldValue.arrayUnion([spotId]),
    }, SetOptions(merge: true));

    // 3. Create History Record
    batch.set(historyRef, {
      'userId': userId,
      'spotId': spotId,
      'startTime': Timestamp.fromDate(startTime),
      'expectedEndTime': Timestamp.fromDate(endTime),
      'durationHours': durationInHours,
      'cost': cost,
      'status': 'active', // active, completed, cancelled
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Schedule Notification
    await NotificationService().scheduleBookingNotifications(
      bookingId: spotId, 
      endTime: endTime,
    );
  }

  Future<void> releaseSpot(String spotId, String userId) async {
      WriteBatch batch = _firestore.batch();
      
      // 1. Clear Spot
      batch.update(_firestore.collection('parkingSpots').doc(spotId), {
        'status': 'available',
        'bookedBy': null,
        'bookingStartTime': null,
        'bookingEndTime': null,
      });

      // 2. Remove from User Active List
      batch.update(_firestore.collection('users').doc(userId), {
        'currentBookings': FieldValue.arrayRemove([spotId]),
      });

      // 3. Close History Record
      final historyQuery = await _firestore.collection('booking_history')
          .where('spotId', isEqualTo: spotId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (historyQuery.docs.isNotEmpty) {
        batch.update(historyQuery.docs.first.reference, {
          'status': 'completed',
          'actualEndTime': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Cancel Notification
      await NotificationService().cancelNotifications(spotId);
  }

  Future<void> extendTime(String spotId, double additionalHours) async {
     // 1. Get current spot data to find current end time
     final spotDoc = await _firestore.collection('parkingSpots').doc(spotId).get();
     if (!spotDoc.exists) return;

     Timestamp? currentEnd = spotDoc['bookingEndTime'];
     if (currentEnd == null) return; // Should not happen

     final newEndTime = currentEnd.toDate().add(Duration(minutes: (additionalHours * 60).toInt()));
     final additionalCost = (additionalHours * pricePerHour).round();

     // 2. Update Spot
     await _firestore.collection('parkingSpots').doc(spotId).update({
        'bookingEndTime': Timestamp.fromDate(newEndTime),
      });

     // 3. Update History (Find active record)
     final historyQuery = await _firestore.collection('booking_history')
          .where('spotId', isEqualTo: spotId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
    
    if (historyQuery.docs.isNotEmpty) {
       await historyQuery.docs.first.reference.update({
         'expectedEndTime': Timestamp.fromDate(newEndTime),
         'durationHours': FieldValue.increment(additionalHours),
         'cost': FieldValue.increment(additionalCost),
       });
    }

    // 4. Update Notification
    await NotificationService().scheduleBookingNotifications(
      bookingId: spotId, 
      endTime: newEndTime,
    );
  }

  Future<void> clearGhostBooking(String spotId) async {
    await _firestore.collection('parkingSpots').doc(spotId).update({
      'status': 'available',
      'bookedBy': null,
      'bookingStartTime': null,
      'bookingEndTime': null,
    });
  }
  Future<void> regenerateSpots() async {
    final batch = _firestore.batch();
    
    // 1. Delete ALL existing spots
    final snapshot = await _firestore.collection('parkingSpots').get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit(); // Commit deletions first to avoid batch limit if many docs

    // 2. Create Car Spots (P1 - P70)
    final createBatch = _firestore.batch();
    for (int i = 1; i <= 70; i++) {
      final id = 'car-P$i';
      final docRef = _firestore.collection('parkingSpots').doc(id);
      createBatch.set(docRef, {
        'status': 'available',
        'type': 'car',
        'x': 0, // No longer used in Grid
        'y': 0, // No longer used in Grid
        'bookedBy': null,
      });
    }

    // 3. Create Bike Spots (P1 - P30)
    for (int i = 1; i <= 30; i++) {
      final id = 'bike-P$i';
      final docRef = _firestore.collection('parkingSpots').doc(id);
      createBatch.set(docRef, {
        'status': 'available',
        'type': 'motorcycle',
        'x': 0,
        'y': 0,
        'bookedBy': null,
      });
    }

    await createBatch.commit();
    await createBatch.commit();
  }

  Future<Map<String, dynamic>> getAnalyticsStats() async {
    // 1. Total Revenue & Bookings from History
    // Note: For production, use Aggregation Queries. For MVP, we fetch all.
    final historySnap = await _firestore.collection('booking_history').get();
    double totalRevenue = 0;
    int totalBookings = historySnap.size;
    
    for (var doc in historySnap.docs) {
      final data = doc.data();
      totalRevenue += (data['cost'] ?? 0) as int; 
    }

    // 2. Current Occupancy
    final spotsSnap = await _firestore.collection('parkingSpots').get();
    int occupied = 0;
    int cars = 0;
    int bikes = 0;
    
    for (var doc in spotsSnap.docs) {
      if (doc['status'] == 'booked') {
        occupied++;
        if (doc['type'] == 'car') cars++;
        else bikes++;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalBookings': totalBookings,
      'occupied': occupied,
      'totalSpots': spotsSnap.size,
      'occupiedCars': cars,
      'occupiedBikes': bikes,
    };
  }
}
