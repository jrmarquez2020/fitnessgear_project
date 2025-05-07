import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/admin_home.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/forgot_password.dart';
import 'strength_training_screen.dart';
import 'create_account_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(FitnessGearHubApp());
}

class FitnessGearHubApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LoginScreen());
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    if (_usernameController.text == "admin" ||
        _passwordController.text == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => admin_home()),
      );
    } else if (_formKey.currentState!.validate()) {
      try {
        // Attempt login using Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _usernameController.text.trim(),
              password: _passwordController.text.trim(),
            );

        // If login is successful, navigate to StrengthTrainingScreen
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login successful!')));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StrengthTrainingScreen()),
        );
      } on FirebaseAuthException catch (e) {
        // Show error message if login fails
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Incorrect Email or Password ')));
      } catch (e) {
        // Handle other errors
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Something went wrong')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.jpg',
                      width: 35,
                      height: 35,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Fitness Gear Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 50),
                // Email TextField
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.white),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                ),

                SizedBox(height: 20),
                // Password TextField
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(color: Colors.white),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 30),
                // Login Button
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey, // Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 100,
                      vertical: 15,
                    ),
                  ),
                  child: Text('Log In', style: TextStyle(color: Colors.black)),
                ),
                SizedBox(height: 20),
                // Create account text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateAccountScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Create an account',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "forgot password",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
