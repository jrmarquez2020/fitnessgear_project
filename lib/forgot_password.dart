import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset email sent."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back after successful send
      } on FirebaseAuthException catch (e) {
        String errorMsg;
        if (e.code == 'user-not-found') {
          errorMsg = "No user found for that email.";
        } else {
          errorMsg = "Failed to send reset email. Try again.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: Icon(Icons.arrow_back, color: Colors.white),
        title: const Text(
          "Forgot Password",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter your email to receive a password reset link.",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black), // text color
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(
                    255,
                    217,
                    217,
                    217,
                  ), // background color
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.black), // label color
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your email.";
                  }
                  if (!value.contains('@')) {
                    return "Please enter a valid email.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "Send Reset Email",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
