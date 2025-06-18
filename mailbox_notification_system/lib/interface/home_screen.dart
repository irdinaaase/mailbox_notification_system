import 'package:flutter/material.dart';
import 'package:mailbox_notification_system/config.dart';
import 'package:mailbox_notification_system/model/user_model.dart';
import 'package:mailbox_notification_system/model/box_model.dart';
import 'package:mailbox_notification_system/interface/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animator/flutter_animator.dart';

class HomeScreen extends StatefulWidget {
  final User userdata;
  const HomeScreen({super.key, required this.userdata});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Box>> _boxesFuture;
  final TextEditingController _searchController = TextEditingController();
  int selectedTabIndex = 0;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _boxesFuture = _fetchBoxes();
  }

  Future<List<Box>> _fetchBoxes() async {
    final response = await http.get(
      Uri.parse('${MyConfig.servername}/flutter_php/get_user_with_boxes.php?user_id=${widget.userdata.userId}'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> boxesList = jsonData['boxes'];
      return boxesList.map((json) => Box.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load boxes');
    }
  }

  Future<void> _refreshBoxes() async {
    setState(() {
      _boxesFuture = _fetchBoxes();
    });
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTabIndex = index),
        child: BounceIn(
          preferences: const AnimationPreferences(
            offset: Duration(milliseconds: 100),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[700] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue[700]! : Colors.blue,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'MarioBros2',
                    color: isSelected ? Colors.white : Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Box> _filterBoxes(List<Box> boxes) {
    if (selectedTabIndex == 0) { // Vacant
      return boxes.where((box) => box.status == 'VACANT').toList();
    } else { // Occupied
      return boxes.where((box) => box.status == 'OCCUPIED').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: FadeInLeft(
          child: Row(
            children: [
              const Icon(Icons.mail_outline, size: 24),
              const SizedBox(width: 8),
              Text(
                'Hi ${widget.userdata.userName}!',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'MarioBros2',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.red[800],
        elevation: 4,
        actions: [
          FadeIn(
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _refreshBoxes();
                // Add haptic feedback
                Feedback.forTap(context);
              },
            ),
          ),
          FadeIn(
            child: IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () async {
                final updatedUser = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: widget.userdata),
                  ),
                );
                
                if (updatedUser != null) {
                  setState(() {
                    widget.userdata.userName = updatedUser.userName;
                    widget.userdata.userEmail = updatedUser.userEmail;
                    widget.userdata.userPhone = updatedUser.userPhone;
                    widget.userdata.userAddress = updatedUser.userAddress;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'asset/jpg/background.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.1),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildTabButton('Vacant', 0, Icons.inbox_outlined),
                    const SizedBox(width: 10),
                    _buildTabButton('Occupied', 1, Icons.mark_email_read),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SlideInDown(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _isSearching = value.isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true, 
                      fillColor: Colors.white.withOpacity(0.9),
                      hintText: 'Search mailboxes...',
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _isSearching = false;
                                });
                                _refreshBoxes();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Box>>(
                  future: _boxesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: FadeIn(
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading mailboxes...',
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: FadeIn(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}',
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshBoxes,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: FadeIn(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('asset/png/empty.png',
                                  width: 120, height: 120),
                              const SizedBox(height: 16),
                              const Text('No mailboxes found',
                                  style: TextStyle(fontSize: 18)),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add a new mailbox',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final boxes = _filterBoxes(snapshot.data!);
                    if (boxes.isEmpty) {
                      return Center(
                        child: FadeIn(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                selectedTabIndex == 0
                                    ? 'asset/png/vacant.png'
                                    : 'asset/png/occupied.png',
                                width: 120,
                                height: 120,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                selectedTabIndex == 0
                                    ? 'No vacant mailboxes'
                                    : 'No occupied mailboxes',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedTabIndex == 0
                                    ? 'All mailboxes are currently occupied'
                                    : 'No mailboxes have mail right now',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshBoxes,
                      color: Colors.blue,
                      backgroundColor: Colors.white,
                      displacement: 40,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        itemCount: boxes.length,
                        itemBuilder: (context, index) {
                          return FadeInUp(
                            preferences: AnimationPreferences(
                              offset: Duration(milliseconds: 100 * index),
                            ),
                            child: _buildBoxCard(boxes[index]),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FadeIn(
        child: FloatingActionButton(
          onPressed: _addNewBox,
          backgroundColor: Colors.yellow[700],
          elevation: 8,
          tooltip: 'Add New Mailbox',
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(Icons.add, color: Colors.black, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildBoxCard(Box box) {
    final isAlarm = (box.status?.toUpperCase() ?? '') == 'ALARM_TRIGGERED';
    final isVacant = (box.status?.toUpperCase() ?? '') == 'VACANT';
    final boxColor = isAlarm
        ? Colors.red[400]
        : isVacant
            ? Colors.green[400]
            : Colors.blue[400];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: boxColor!.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: boxColor.withOpacity(0.9),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Add box details view or other action
            Feedback.forTap(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isAlarm
                          ? Icons.warning_amber_rounded
                          : isVacant
                              ? Icons.inventory_2_outlined
                              : Icons.inventory,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'BOX #${box.boxId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MarioBros2',
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        box.status ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      box.location ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                if (box.userName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        box.userName!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit,
                      color: Colors.white,
                      onPressed: () => _editBox(box),
                      tooltip: 'Edit',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.copy,
                      color: Colors.white,
                      onPressed: () => _copyBox(box),
                      tooltip: 'Copy',
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete,
                      color: Colors.white,
                      onPressed: () => _deleteBox(box),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  void _addNewBox() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add New Mailbox',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Box ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.info_outline),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        // Add implementation
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New mailbox added successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _refreshBoxes();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CREATE MAILBOX',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editBox(Box box) {
    final TextEditingController locationController = 
        TextEditingController(text: box.location);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Box #${box.boxId}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Box Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final newLocation = locationController.text.trim();
                      if (newLocation.isNotEmpty) {
                        try {
                          final response = await http.post(
                            Uri.parse('${MyConfig.servername}/flutter_php/update_box_location.php'),
                            body: {
                              'box_id': box.boxId,
                              'box_location': newLocation,
                            },
                          );
                          
                          if (response.statusCode == 200) {
                            final responseData = json.decode(response.body);
                            if (responseData['success']) {
                              Navigator.pop(context);
                              _refreshBoxes();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Box #${box.boxId} location updated'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              throw Exception(responseData['error'] ?? 'Failed to update location');
                            }
                          } else {
                            throw Exception('HTTP error ${response.statusCode}');
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('SAVE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyBox(Box box) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Mailbox'),
        content: Text('Create a copy of Box #${box.boxId} at "${box.location}"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('COPY'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.post(
          Uri.parse('${MyConfig.servername}/flutter_php/copy_box.php'),
          body: {
            'box_id': box.boxId,
            'box_location': '${box.location} (Copy)',
          },
        );
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success']) {
            _refreshBoxes();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mailbox copied successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception(responseData['error'] ?? 'Failed to copy box');
          }
        } else {
          throw Exception('HTTP error ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBox(Box box) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mailbox'),
        content: Text('Are you sure you want to delete Box #${box.boxId} at ${box.location}?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.post(
          Uri.parse('${MyConfig.servername}/flutter_php/delete_box.php'),
          body: {'box_id': box.boxId},
        );
        if (response.statusCode == 200) {
          _refreshBoxes();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mailbox deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}