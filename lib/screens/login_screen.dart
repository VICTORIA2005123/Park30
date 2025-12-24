import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart'; // Import the new signup page

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("PARK30", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            const Text("Welcome Back"),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Color.fromARGB(255, 241, 238, 238)),
              decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: _obscure,
              style: const TextStyle(color: Color.fromARGB(255, 248, 244, 244)),
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), 
                onPressed: () => setState(() => _obscure = !_obscure)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => AuthService().signInWithEmail(_emailController.text, _passController.text),
                child: const Text("LOGIN"),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpScreen())),
              child: const Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}