class User {
  String? userId;
  String? userName;
  String? userPhone;
  String? userAddress;
  String? userEmail;
  String? userPassword;

  User({
    this.userId,
    this.userName,
    this.userPhone,
    this.userAddress,
    this.userEmail,
    this.userPassword,
  });

  User.fromJson(Map<String, dynamic> json) {
    userId = json['user_id']?.toString();
    userName = json['user_name'];
    userPhone = json['user_phone'];
    userAddress = json['user_address'];
    userEmail = json['user_email'];
    userPassword = json['user_password'];
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'user_address': userAddress,
      'user_email': userEmail,
      'user_password': userPassword,
    };
  }
}
