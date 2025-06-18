class Box {
  String? boxId;
  String? userId;
  String? location;
  String? status;
  String? userName;
  String? userEmail;

  Box({
    this.boxId,
    this.userId,
    this.location,
    this.status,
    this.userName,
    this.userEmail,
  });

  Box.fromJson(Map<String, dynamic> json) {
      boxId = json['box_id']?.toString();
      userId = json['user_id']?.toString();
      location = json['box_location'];
      status = json['box_status'];
      userName = json['user_name']?.toString();
      userEmail = json['user_email']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'box_id': boxId,
      'user_id': userId,
      'box_location': location,
      'box_status': status,
      'user_name': userName,
      'user_email': userEmail,
    };
  }
}