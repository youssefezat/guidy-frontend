import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Basic Email Validation
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Check for empty fields
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields"), backgroundColor: Colors.red));
      return;
    }

    // 2. Strict UI Validation
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid email address"), backgroundColor: Colors.orange));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 6 characters"), backgroundColor: Colors.orange));
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Talk to Firebase
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 4. Success! AuthGate will catch this automatically, but we pop to ensure smooth routing.
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
      
    } on FirebaseAuthException catch (e) {
      // Catch specific Firebase errors
      String errorMsg = "Sign up failed";
      if (e.code == 'email-already-in-use') {
        errorMsg = "This email is already registered.";
      } else if (e.code == 'network-request-failed') {
        errorMsg = "Check your internet connection.";
      } else {
        errorMsg = e.message ?? errorMsg;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text("Create Account", style: TextStyle(color: Color(0xFF6DA4C2), fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Join Guidy today", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              
              _buildTextField("Email", "Enter your email", Icons.email_outlined, _emailController),
              const SizedBox(height: 20),
              _buildTextField("Password", "Create a password (min. 6 chars)", Icons.lock_outline, _passwordController, isPassword: true),
              const SizedBox(height: 20),
              _buildTextField("Confirm Password", "Confirm your password", Icons.lock_outline, _confirmPasswordController, isPassword: true),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6DA4C2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Create Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Sign In", style: TextStyle(color: Color(0xFF6DA4C2), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}