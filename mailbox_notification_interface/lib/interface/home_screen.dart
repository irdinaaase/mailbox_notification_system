import 'package:flutter/material.dart';
import 'package:mailbox_notification_system/config.dart';
import 'package:mailbox_notification_system/model/user_model.dart';
import 'package:mailbox_notification_system/model/box_model.dart';
import 'package:mailbox_notification_system/model/log_model.dart';
import 'package:mailbox_notification_system/interface/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; 
import 'package:flutter_animator/flutter_animator.dart';

class HomeScreen extends StatefulWidget {
  final User userdata;

  const HomeScreen({super.key, required this.userdata});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables
  late Future<List<Box>> _boxesFuture;
  final TextEditingController _searchController = TextEditingController();
  int selectedTabIndex = 0;
  bool _isSearching = false;

  // Super Mario Color Palette
static const marioRed = Color(0xFFE4000F);
static const marioBlue = Color(0xFF049CD8);
static const marioYellow = Color(0xFFFBD000);
static const marioGreen = Color(0xFF43B047);
static const marioWhite = Color(0xFFFFFFFF);
static const marioBlack = Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    _boxesFuture = _fetchBoxes();
  }

Future<List<Box>> _fetchBoxes() async {
  try {
    final response = await http.get(
      Uri.parse('${MyConfig.servername}/flutter_php/get_user_with_boxes.php?user_id=${widget.userdata.userId}'),
    ).timeout(const Duration(seconds: 10));  // Add timeout

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final boxesList = jsonData['boxes'] as List;
      
      // Use compute() for heavy processing if needed
      return boxesList.map((json) => Box.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load boxes: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Network error: $e');
  }
}

  Future<List<Log>> _fetchBoxLogs(String boxId, {DateTime? fromDate, DateTime? toDate}) async {
    String url = '${MyConfig.servername}/flutter_php/get_box_logs.php?box_id=$boxId';
    
    if (fromDate != null) {
      url += '&from_date=${DateFormat('yyyy-MM-dd').format(fromDate)}';
    }
    if (toDate != null) {
      url += '&to_date=${DateFormat('yyyy-MM-dd').format(toDate)}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Log.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load logs');
    }
  }

Future<void> _refreshBoxes() async {
  // Show immediate feedback by clearing old data
  setState(() {
    _boxesFuture = Future.value([]); // Clear existing data
  });
  
  // Then load new data
  setState(() {
    _boxesFuture = _fetchBoxes();
  });
}

  // UI Components
  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTabIndex = index),
        child: BounceIn(
          preferences: const AnimationPreferences(offset: Duration(milliseconds: 100)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.blue[700],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white! : Colors.white,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected) BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: isSelected ? Colors.blue[700] : Colors.white),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'MarioBros2',
                    color: isSelected ? Colors.blue[700] : Colors.white,
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

  Widget _buildBoxCard(Box box) {
    final isAlarm = (box.status?.toUpperCase() ?? '') == 'ALARM_TRIGGERED';
    final isVacant = (box.status?.toUpperCase() ?? '') == 'VACANT';
    final isLocked = (box.lockStatus?.toUpperCase() ?? '') == 'LOCKED';
    final boxColor = isAlarm ? Colors.yellow : isVacant ? Colors.green[400] : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: boxColor!.withOpacity(0.2),
          blurRadius: 8,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        )],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: boxColor.withOpacity(0.9),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBoxLogs(box),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBoxHeader(box, isAlarm, isVacant),
                _buildBoxInfoRow(Icons.location_on_outlined, box.location ?? ''),
                if (box.userName != null) _buildBoxInfoRow(Icons.person_outline, box.userName!),
                _buildLockStatusRow(box, isLocked),
                _buildActionButtons(box, isLocked),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoxHeader(Box box, bool isAlarm, bool isVacant) {
    return Row(
      children: [
        Icon(
          isAlarm ? Icons.warning_amber_rounded : isVacant ? Icons.inventory_2_outlined : Icons.inventory,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'BOX #${box.userBoxNumber}', // Always use the sequential number
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'MarioBros2',
              color: Colors.white,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildBoxInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildLockStatusRow(Box box, bool isLocked) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(isLocked ? Icons.lock : Icons.lock_open, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          Text(isLocked ? 'Locked' : 'Unlocked', style: const TextStyle(color: Colors.white)),
          const Spacer(),
          if (box.lastUpdated != null) ...[
            const Icon(Icons.access_time, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              _formatTimestamp(box.lastUpdated),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(Box box, bool isLocked) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButton(
            icon: isLocked ? Icons.lock_open : Icons.lock,
            onPressed: () => _toggleLock(box, !isLocked),
            tooltip: isLocked ? 'Unlock' : 'Lock',
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.edit,
            onPressed: () => _editBox(box),
            tooltip: 'Edit',
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.delete,
            onPressed: () => _deleteBox(box),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
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
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // Helper methods
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  List<Box> _filterBoxes(List<Box> boxes) {
    return selectedTabIndex == 0 
        ? boxes.where((box) => box.status == 'VACANT').toList()
        : boxes.where((box) => box.status == 'OCCUPIED').toList();
  }

  // Dialog methods
void _showBoxLogs(Box box) async {
  DateTime? selectedFromDate;
  DateTime? selectedToDate = DateTime.now();
  List<Log> allLogs = [];

  Future<List<Log>> _fetchAndFilterLogs() async {
    try {
      final logs = await _fetchBoxLogs(box.boxId!);
      allLogs = logs;
      
      List<Log> filteredLogs = allLogs.where((log) {
        final logDate = DateTime.parse(log.timestamp);
        
        bool afterFrom = selectedFromDate == null || 
            logDate.isAfter(selectedFromDate!.subtract(const Duration(days: 1)));
        bool beforeTo = selectedToDate == null || 
            logDate.isBefore(selectedToDate!.add(const Duration(days: 1)));
        
        return afterFrom && beforeTo;
      }).toList();

      return filteredLogs;
    } catch (e) {
      throw Exception('Failed to load logs');
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: marioWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: marioRed, width: 3),
              ),
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HISTORY - BOX #${box.boxId}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: marioRed,
                      fontFamily: 'MarioBros2',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date filter row - Mario themed
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: marioBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedFromDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: marioRed,
                                        onPrimary: marioWhite,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() => selectedFromDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: marioWhite,
                                border: Border.all(color: marioBlue),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 10, color: marioBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedFromDate != null 
                                        ? 'From: ${DateFormat('dd/MM/yyyy').format(selectedFromDate!)}'
                                        : 'From Date',
                                    style: const TextStyle(color: marioBlack, fontSize: 5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedToDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: marioRed,
                                        onPrimary: marioWhite,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() => selectedToDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: marioWhite,
                                border: Border.all(color: marioBlue),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 10, color: marioBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedToDate != null 
                                        ? 'To: ${DateFormat('dd/MM/yyyy').format(selectedToDate!)}'
                                        : 'To Date',
                                    style: TextStyle(color: marioBlack, fontSize: 5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter button - Mario styled
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: marioRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'APPLY FILTER',
                      style: TextStyle(
                        color: marioWhite,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MarioBros2',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Logs list with Mario theme
                  Expanded(
                    child: FutureBuilder<List<Log>>(
                      future: _fetchAndFilterLogs(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: marioRed),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(color: marioRed),
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              'No logs found',
                              style: TextStyle(color: marioBlue),
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final log = snapshot.data![index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: index % 2 == 0 ? marioBlue.withOpacity(0.1) : marioRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.history,
                                  color: marioRed,
                                ),
                                title: Text(
                                  log.action,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: marioBlack,
                                  ),
                                ),
                                subtitle: Text(
                                  _formatTimestamp(log.timestamp),
                                  style: TextStyle(color: marioBlue),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: marioYellow,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: marioBlack,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        color: marioRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _addNewBox() async {
  final nextBoxNumber = await _getNextBoxNumber();
  final boxIdController = TextEditingController(text: nextBoxNumber.toString());
  final locationController = TextEditingController();
  final statusController = TextEditingController(text: 'VACANT');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: marioWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: marioRed, width: 3),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: marioRed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ADD NEW MAILBOX',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: marioRed,
              fontFamily: 'MarioBros2',
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: boxIdController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Box Number',
                      labelStyle: TextStyle(color: marioBlue),
                      prefixIcon: Icon(Icons.numbers, color: marioRed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: marioBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: marioRed, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: TextStyle(color: marioBlue),
                      prefixIcon: Icon(Icons.location_on, color: marioRed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: marioBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: marioRed, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: statusController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: TextStyle(color: marioBlue),
                      prefixIcon: Icon(Icons.info_outline, color: marioRed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: marioBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      final boxId = boxIdController.text.trim();
                      final location = locationController.text.trim();
                      final status = statusController.text.trim();

                      if (location.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Location is required'),
                            backgroundColor: marioRed,
                          ),
                        );
                        return;
                      }

                      try {
                        final response = await http.post(
                          Uri.parse('${MyConfig.servername}/flutter_php/add_box.php'),
                          body: {
                            'user_id': widget.userdata.userId,
                            'box_id': boxId,
                            'box_location': location,
                            'box_status': status,
                            'lock_status': 'UNLOCKED'
                          },
                        );

                        if (response.statusCode == 200) {
                          Navigator.pop(context);
                          _refreshBoxes();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('New mailbox added!'),
                              backgroundColor: marioGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: marioRed,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: marioRed,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'CREATE MAILBOX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: marioWhite,
                        fontFamily: 'MarioBros2',
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
  final locationController = TextEditingController(text: box.location);
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: marioWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: marioRed, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EDIT BOX #${box.boxId}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: marioRed,
                fontFamily: 'MarioBros2',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'Box Location',
                labelStyle: TextStyle(color: marioBlue),
                prefixIcon: Icon(Icons.location_on, color: marioRed),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: marioBlue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: marioRed, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      color: marioBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final newLocation = locationController.text.trim();
                    if (newLocation.isNotEmpty) {
                      try {
                        final response = await http.post(
                          Uri.parse('${MyConfig.servername}/flutter_php/update_box_location.php'),
                          body: {'box_id': box.boxId, 'box_location': newLocation},
                        );
                        
                        if (response.statusCode == 200) {
                          Navigator.pop(context);
                          _refreshBoxes();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Box location updated!'),
                              backgroundColor: marioGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: marioRed,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: marioRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      color: marioWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _toggleLock(Box box, bool newLockStatus) async {
    try {
      final response = await http.post(
        Uri.parse('${MyConfig.servername}/flutter_php/update_box_lock.php'),
        body: {'box_id': box.boxId, 'box_lock': newLockStatus ? 'LOCKED' : 'UNLOCKED'},
      );
      
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lock ${newLockStatus ? 'engaged' : 'released'}')),
        );
      } else {
        throw Exception(jsonResponse['error']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<int> _getNextBoxNumber() async {
    final response = await http.get(
      Uri.parse('${MyConfig.servername}/flutter_php/get_next_box_number.php?user_id=${widget.userdata.userId}'),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['next_box_number'] ?? 1;
    } else {
      throw Exception('Failed to get next box number');
    }
  }

  Future<void> _deleteBox(Box box) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mailbox'),
        content: Text('Are you sure you want to delete Box #${box.boxId} at ${box.location}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            const SnackBar(content: Text('Mailbox deleted'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                _refreshBoxes();
                Feedback.forTap(context);
              },
            ),
          ),
          FadeIn(
            child: IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.black),
              onPressed: () async {
                final updatedUser = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.userdata)),
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
                    onChanged: (value) => setState(() => _isSearching = value.isNotEmpty),
                    decoration: InputDecoration(
                      filled: true, 
                      fillColor: Colors.white.withOpacity(0.9),
                      hintText: 'Search mailboxes...',
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _isSearching = false);
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
                              Text('Loading mailboxes...', style: TextStyle(fontSize: 16)),
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
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _refreshBoxes, child: const Text('Retry')),
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
                              Image.asset('asset/png/empty.png', width: 120, height: 120),
                              const SizedBox(height: 16),
                              const Text('No mailboxes found', style: TextStyle(fontSize: 18)),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add a new mailbox',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                              const SizedBox(height: 16),
                              Text(
                                selectedTabIndex == 0 ? 'No vacant mailboxes' : 'No occupied mailboxes',
                                style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 8),
                              Text(
                                selectedTabIndex == 0 
                                    ? 'All mailboxes are currently occupied' 
                                    : 'No mailboxes have mail right now',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: boxes.length,
                        itemBuilder: (context, index) {
                          return FadeInUp(
                            preferences: AnimationPreferences(offset: Duration(milliseconds: 100 * index)),
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
}