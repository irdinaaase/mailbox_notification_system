import 'package:flutter/material.dart';
import 'package:mailbox_notification_system/config.dart';
import 'package:mailbox_notification_system/model/user_model.dart';
import 'package:mailbox_notification_system/interface/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  
  bool _isEditing = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.userName);
    _emailController = TextEditingController(text: widget.user.userEmail);
    _phoneController = TextEditingController(text: widget.user.userPhone);
    _addressController = TextEditingController(text: widget.user.userAddress);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateUserInfo() async {
    if (_passwordController.text.isNotEmpty && 
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${MyConfig.servername}/flutter_php/update_user.php'),
        body: {
          'user_id': widget.user.userId,
          'user_name': _nameController.text.trim(),
          'user_email': _emailController.text.trim(),
          'user_phone': _phoneController.text.trim(),
          'user_address': _addressController.text.trim(),
          'user_password': _passwordController.text.isNotEmpty 
              ? _passwordController.text 
              : '',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final updatedUser = User(
            userId: widget.user.userId,
            userName: _nameController.text.trim(),
            userEmail: _emailController.text.trim(),
            userPhone: _phoneController.text.trim(),
            userAddress: _addressController.text.trim(),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message']),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context, updatedUser);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _nameController.text = widget.user.userName ?? '';
      _emailController.text = widget.user.userEmail ?? '';
      _phoneController.text = widget.user.userPhone ?? '';
      _addressController.text = widget.user.userAddress ?? '';
      _passwordController.clear();
      _confirmPasswordController.clear();
      _isEditing = false;
    });
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false, // Remove all routes
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('LOG OUT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false, // Add this line
      title: const Text(
        'User Profile',
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'MarioBros2',
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.red[800],
      elevation: 4,
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => _isEditing = true),
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _confirmLogout,
        ),
      ],
    ),
      body: Stack(
        children: [
          // Static background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('asset/jpg/background.jpg'),
                fit: BoxFit.cover
              ),
            ),
          ),
          // Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[700],
                  child: Text(
                    widget.user.userName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 40, 
                      color: Colors.white,
                      fontFamily: 'MarioBros2',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoField('User ID', widget.user.userId ?? 'N/A', Icons.person_pin),
                const Divider(),
                const SizedBox(height: 20),
                _buildEditableField(_nameController, 'Name', Icons.person),
                _buildEditableField(_emailController, 'Email', Icons.email),
                _buildEditableField(_phoneController, 'Phone', Icons.phone),
                _buildEditableField(_addressController, 'Address', Icons.home),
                const Divider(),
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.centerLeft, // Change to center/right as needed
                      child: const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MarioBros2',
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'New Password',
                    isObscure: !_showPassword,
                    onToggle: () => setState(() => _showPassword = !_showPassword),
                  ),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    isObscure: !_showConfirmPassword,
                    onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _cancelEditing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _updateUserInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('SAVE'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), // Extra space at bottom
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontFamily: 'MarioBros2',
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9), // Added transparency here
          labelStyle: const TextStyle(
            fontFamily: 'MarioBros2',
            color: Colors.black87, // Make label text slightly transparent
          ),
        ),
        enabled: _isEditing,
        keyboardType: label == 'Email' 
            ? TextInputType.emailAddress
            : (label == 'Phone' ? TextInputType.phone : TextInputType.text),
        style: const TextStyle(
          color: Colors.black87, // Make input text slightly transparent
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.lock, color: Colors.blue[700]),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility : Icons.visibility_off,
              color: Colors.blue[700],
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          labelStyle: const TextStyle(
            color: Colors.black87,
          ),
        ),
        style: const TextStyle(
          color: Colors.black87,
        ),
      ),
    );
  }
}