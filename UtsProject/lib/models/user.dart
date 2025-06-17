class UserModel {
  final int userId;
  final String userName;
  final String userEmail;
  final String? profileUrl;
  final bool isDeleted;

  UserModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.profileUrl,
    required this.isDeleted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      profileUrl: json['profileUrl'],
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'profileUrl': profileUrl,
      'isDeleted': isDeleted,
    };
  }
}

class LoginRequest {
  final String userEmail;
  final String userPassword;

  LoginRequest({
    required this.userEmail,
    required this.userPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'userEmail': userEmail,
      'userPassword': userPassword,
    };
  }
}

class RegisterRequest {
  final String userName;
  final String userEmail;
  final String userPassword;
  final String? userProfile;

  RegisterRequest({
    required this.userName,
    required this.userEmail,
    required this.userPassword,
    this.userProfile,
  });

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userEmail': userEmail,
      'userPassword': userPassword,
      'userProfile': userProfile,
    };
  }
}

class LoginResponse {
  final UserModel user;
  final String token;

  LoginResponse({
    required this.user,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: UserModel.fromJson(json['user']),
      token: json['token'],
    );
  }
}