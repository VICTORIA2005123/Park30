import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/receipt_service.dart';
import '../repositories/parking_repository.dart';

class TimerCard extends StatefulWidget {
  final String spotId;
  final DateTime startTime;

  const TimerCard({super.key, required this.spotId, required this.startTime});

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  Timer? _timer;
  Duration _remainingTime = const Duration(minutes: 30);
  bool _hasNotified = false;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _calculateTime());
  }

  void _calculateTime() {
    final expirationTime = widget.startTime.add(const Duration(minutes: 30));
    final now = DateTime.now();
    final difference = expirationTime.difference(now);

    if (mounted) {
      setState(() {
        _remainingTime = difference;
      });
    }

    // 5-minute warning logic
    if (_remainingTime.inMinutes == 5 && _remainingTime.inSeconds % 60 == 0 && !_hasNotified) {
      _hasNotified = true;
      _showWarningSnackBar("5 MINUTES LEFT", Colors.orange);
    }

    // Time Over Warning
    if (_remainingTime.isNegative && _remainingTime.inSeconds == -1) {
      _showWarningSnackBar("TIME EXPIRED! PLEASE VACATE.", Colors.red);
    }
  }

  void _showWarningSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "EXTEND",
          textColor: Colors.white,
          onPressed: _extendTime,
        ),
      ),
    );
  }

  // FIXED: Moved outside of the build method
  Future<void> _endSession() async {
    final now = DateTime.now();
    
    // 1. Generate the PDF Receipt
    await ReceiptService.generateReceipt(
      spotId: widget.spotId,
      startTime: widget.startTime,
      endTime: now,
      ratePerHour: 10.0, // Adjust your campus rate here
    );

    // 2. Release the spot in the database
    _releaseSpot();
  }

  Future<void> _releaseSpot() async {
    _timer?.cancel();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await ParkingRepository().releaseSpot(widget.spotId, userId);
    } catch (e) {
      debugPrint("Error releasing spot: $e");
    }
  }

  Future<void> _extendTime() async {
    setState(() => _hasNotified = false);
    try {
      await ParkingRepository().extendTime(widget.spotId, 0.5);
    } catch (e) {
      debugPrint("Error extending time: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired = _remainingTime.isNegative;
    final totalSeconds = _remainingTime.inSeconds.abs();
    final displayMinutes = (totalSeconds / 60).floor();
    final displaySeconds = totalSeconds % 60;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isExpired 
                ? Colors.red.withOpacity(0.2) 
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpired 
                  ? Colors.red.withOpacity(0.5) 
                  : Colors.white.withOpacity(0.2), 
              width: 1.5
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                           Icon(
                            Icons.local_parking_rounded, 
                            color: isExpired ? Colors.redAccent : Colors.cyanAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Spot ${widget.spotId.split('-').last}", 
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 18, 
                              color: Colors.white
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isExpired ? "OVERDUE" : "SESSION ACTIVE", 
                        style: TextStyle(
                          color: isExpired ? Colors.redAccent : Colors.white70, 
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500
                        )
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.red : Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${isExpired ? '-' : ''}${displayMinutes.toString().padLeft(2, '0')}:${displaySeconds.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(blurRadius: 10, color: isExpired ? Colors.red : Colors.cyanAccent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _glassButton(
                      label: "EXTEND",
                      icon: Icons.access_time_filled_rounded,
                      color: Colors.blueAccent,
                      onPressed: _extendTime,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _glassButton(
                      label: "FINISH",
                      icon: Icons.check_circle_rounded,
                      color: isExpired ? Colors.red : Colors.green,
                      onPressed: _endSession,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassButton({
    required String label, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onPressed
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}