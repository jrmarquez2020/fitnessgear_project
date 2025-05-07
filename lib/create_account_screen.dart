import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart'; // Assuming this has LoginScreen

class CreateAccountScreen extends StatefulWidget {
  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();

  void _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create user account
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        User? user = userCredential.user;

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A verification email has been sent. Please check your inbox.',
              ),
            ),
          );

          _showEmailVerificationDialog(user);
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
      }
    }
  }

  void _showEmailVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Verify Your Email"),
          content: const Text("Please check your inbox and verify your email."),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await user.reload();
                  User? refreshedUser = FirebaseAuth.instance.currentUser;

                  if (refreshedUser != null && refreshedUser.emailVerified) {
                    if (!mounted) return;

                    Navigator.of(
                      dialogContext,
                    ).pop(); // ✅ Use dialogContext here, not context

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(refreshedUser.uid)
                        .set({
                          'firstName': _firstNameController.text.trim(),
                          'lastName': _lastNameController.text.trim(),
                          'address': _addressController.text.trim(),
                          'email': _emailController.text.trim(),
                          'contact': _contactController.text.trim(),
                          'createdAt': Timestamp.now(),
                        });

                    if (!mounted) return;

                    _firstNameController.clear();
                    _lastNameController.clear();
                    _addressController.clear();
                    _emailController.clear();
                    _passwordController.clear();
                    _contactController.clear();

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email verified! Registration complete.'),
                      ),
                    );
                  } else {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email not verified yet.')),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Something went wrong: $e')),
                  );
                }
              },
              child: const Text("I've Verified"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Create a new account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                _buildTextField(_firstNameController, 'First Name'),
                const SizedBox(height: 20),
                _buildTextField(_lastNameController, 'Last Name'),
                const SizedBox(height: 20),
                _buildTextField(_addressController, 'Address'),
                const SizedBox(height: 20),
                _buildTextField(_emailController, 'Email'),
                const SizedBox(height: 20),
                _buildTextField(
                  _passwordController,
                  'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                _buildTextField(_contactController, 'Contact No.'),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 100,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText, {
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $hintText';
          }
          return null;
        },
      ),
    );
  }
}
