import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class AuthService {
  final AuthRepository _repository = AuthRepository();

  Future<bool> sendOTP(String email) => _repository.sendOTP(email);
  
  bool verifyOTP(String otp) => _repository.verifyOTP(otp);

  Future<UserCredential?> signUpWithEmail(String email, String password) => 
      _repository.signUpWithEmail(email, password);

  Future<UserCredential?> signInWithEmail(String email, String password) => 
      _repository.signInWithEmail(email, password);

  Future<void> signOut() => _repository.signOut();

  Future<bool> get isAdmin => _repository.isAdmin;
  
  User? get currentUser => _repository.currentUser;
  
  Stream<User?> get authStateChanges => _repository.authStateChanges;
}