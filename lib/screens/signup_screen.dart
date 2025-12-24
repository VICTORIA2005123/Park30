import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService(); // Keep instance alive
  bool _otpSent = false;
  bool _obscure = true;

  void _handleAction() async {
    if (!_otpSent) {
      bool sent = await _authService.sendOTP(_emailController.text.trim());
      if (sent) setState(() => _otpSent = true);
    } else {
      try {
        if (_authService.verifyOTP(_otpController.text.trim())) {
          await _authService.signUpWithEmail(_emailController.text.trim(), _passController.text);
          if (mounted) Navigator.pop(context); // Go back to login/home
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid OTP, please try again")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _emailController, style: const TextStyle(color: Color.fromARGB(255, 250, 248, 248)), decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 15),
            if (!_otpSent)  TextField(
              controller: _passController,
              obscureText: _obscure,
              style: const TextStyle(color: Color.fromARGB(255, 248, 244, 244)),
              decoration: InputDecoration(
                labelText: "Create Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), 
                onPressed: () => setState(() => _obscure = !_obscure)),
              ),
            ),
            if (_otpSent) TextField(controller: _otpController, style: const TextStyle(color: Color.fromARGB(255, 241, 235, 235)), decoration: const InputDecoration(labelText: "Enter 6-Digit OTP")),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleAction,
                child: Text(_otpSent ? "VERIFY & CREATE" : "SEND OTP"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}