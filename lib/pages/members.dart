class Members {
  final int userId;
  final String userName;
  final String userEmail;
  final String userPassword;
  final String userLevel;
  final String createdDateTime;
  final String userPhone;

  Members({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPassword,
    required this.userLevel,
    required this.createdDateTime,
    required this.userPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPassword': userPassword,
      'userLevel': userLevel,
      'createdDateTime': createdDateTime,
      'userPhone': userPhone,
    };
  }

  factory Members.fromMap(Map<String, dynamic> map) {
    return Members(
      userId: map['userId'],
      userName: map['userName'],
      userEmail: map['userEmail'],
      userPassword: map['userPassword'],
      userLevel: map['userLevel'],
      createdDateTime: map['createdDateTime'],
      userPhone: map['userPhone'],
    );
  }
}
