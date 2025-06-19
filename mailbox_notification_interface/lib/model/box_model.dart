class Box {
  String? boxId;
  String? userId;
  String? userBoxNumber; 
  String? location;
  String? status;
  String? userName;
  String? userEmail;
  String? lastUpdated;
  String? lockStatus;

  Box({
    this.boxId,
    this.userId,
    this.userBoxNumber,
    this.location,
    this.status,
    this.userName,
    this.userEmail,
    this.lastUpdated,
    this.lockStatus,
  });

  Box.fromJson(Map<String, dynamic> json) {
      boxId = json['box_id']?.toString();
      userId = json['user_id']?.toString();
      userBoxNumber = json['user_box_number']?.toString();
      location = json['box_location'];
      status = json['box_status'];
      userName = json['user_name']?.toString();
      userEmail = json['user_email']?.toString();
      lastUpdated = json['box_last_updated']?.toString();
      lockStatus = json['box_lock']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'box_id': boxId,
      'user_id': userId,
      'user_box_number': userBoxNumber,
      'box_location': location,
      'box_status': status,
      'user_name': userName,
      'user_email': userEmail,
      'box_last_updated': lastUpdated,
      'box_lock': lockStatus,
    };
  }
}