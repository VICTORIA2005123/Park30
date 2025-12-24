import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/email_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Store OTP temporarily (In memory for MVP)
  String? _currentOtp;
  String? _otpEmail;

  Future<bool> sendOTP(String email) async {
    // Generate 6 digit OTP
    final otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    _currentOtp = otp;
    _otpEmail = email;

    return await EmailService().sendOTP(email, otp);
  }

  bool verifyOTP(String otp) {
    if (_currentOtp == otp) {
      // Clear after success
      _currentOtp = null;
      return true;
    }
    return false;
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'currentBookings': [],
        'isVerified': true, 
      });
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'ALREADY_EXISTS'; 
      }
      throw e.message ?? 'Signup Error';
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<bool> get isAdmin async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // 1. Hardcoded Super Admin
    if (user.email == "admin@park30.com") return true;

    // 2. Firestore Role Check
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] == 'admin';
      }
    } catch (e) {
      // ignore error
    }
    return false;
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<bool> promoteCurrentUserToAdmin() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set(
        {'role': 'admin'}, 
        SetOptions(merge: true)
      );
      return true;
    }
    return false;
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
