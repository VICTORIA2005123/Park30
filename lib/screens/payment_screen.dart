import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String spotName;

  const PaymentScreen({super.key, required this.amount, required this.spotName});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  int _selectedMethod = 0; // 0: Card, 1: UPI

  void _processPayment() async {
    setState(() => _isLoading = true);
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _isLoading = false);
      // Return true to indicate success
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("Secure Payment", style: TextStyle(color: Colors.white)),
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

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Amount Card
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text("AMOUNT TO PAY", style: TextStyle(color: Colors.white.withOpacity(0.6), letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      Text("₹${widget.amount.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("For ${widget.spotName}", style: const TextStyle(color: Colors.cyanAccent)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                const Text("Select Payment Method", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                _buildMethodOption(0, Icons.credit_card, "Credit / Debit Card"),
                const SizedBox(height: 15),
                _buildMethodOption(1, Icons.qr_code_scanner, "UPI / QR Code"),
                
                const Spacer(),
                
                // Pay Button
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("PAY NOW", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption(int index, IconData icon, String label) {
    final bool isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.transparent, 
            width: 2
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white60),
            const SizedBox(width: 15),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
            const Spacer(),
            if (isSelected) 
              const Icon(Icons.check_circle, color: Colors.cyanAccent)
          ],
        ),
      ),
    );
  }
}
