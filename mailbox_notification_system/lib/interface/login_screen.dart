// login_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;  // Add this import
import 'dart:convert';
import 'package:mailbox_notification_system/config.dart'; 
import 'package:mailbox_notification_system/model/user_model.dart';
import 'package:mailbox_notification_system/interface/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${MyConfig.servername}/flutter_php/login_user.php'),
        body: {
          'user_email': _emailController.text.trim(),
          'user_password': _passwordController.text.trim(),
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success']) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userdata: User.fromJson(responseData['user']),  // Changed to userdata
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = responseData['message'];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error occurred';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('asset/jpg/background.jpg'),
            fit: BoxFit.cover
          ),
        ),
        
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 0,
          bottom: 150,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              
                  Image.asset(
                    'asset/gif/keyturning.gif',
                    width: 470,
                    height: 190,
                  ),
                  
                  const Center(
                    child: Text(
                      'Welcome Back',
                      textAlign: TextAlign.center, // centers each line relative to the whole block
                      style: TextStyle(
                        fontSize: 45,
                        fontFamily: 'Mario64'
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  TextFormField(
                  controller: _emailController,
                  style: const TextStyle( 
                    fontSize: 12                  ),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      fontFamily: 'MarioBros2'                    ),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email, color: Colors.black54), // darker icon
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                  
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(
                      fontSize: 12
                    ),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                        fontFamily: 'MarioBros2'
                      ),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock, color: Colors.black54),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple, // custom background color
                        foregroundColor: Colors.white,      // text/icon color
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: Colors.black45,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 10,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'MarioBros2',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}