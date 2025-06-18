import 'package:flutter/material.dart';
import 'package:mailbox_notification_system/config.dart';
import 'package:mailbox_notification_system/model/user_model.dart';
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
  bool _isPasswordSectionExpanded = false;
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
        const SnackBar(content: Text('Passwords do not match')),
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
            SnackBar(content: Text(responseData['message'])),
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
        SnackBar(content: Text('Error: ${e.toString()}')),
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
      _isPasswordSectionExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Text(
                      widget.user.userName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoField('User ID', widget.user.userId ?? 'N/A', Icons.person_pin),
                  const Divider(),
                  _buildEditableField(_nameController, 'Name', Icons.person),
                  _buildEditableField(_emailController, 'Email', Icons.email),
                  _buildEditableField(_phoneController, 'Phone', Icons.phone),
                  _buildEditableField(_addressController, 'Address', Icons.home),
                  
                  if (_isEditing) ...[
                    ExpansionTile(
                      title: const Text('Change Password'),
                      initiallyExpanded: _isPasswordSectionExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() => _isPasswordSectionExpanded = expanded);
                      },
                      children: [
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
                      ],
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
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateUserInfo,
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: !_isEditing,
          fillColor: Colors.grey[100],
        ),
        enabled: _isEditing,
        keyboardType: label == 'Email' 
            ? TextInputType.emailAddress
            : (label == 'Phone' ? TextInputType.phone : TextInputType.text),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off),
            onPressed: onToggle,
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}