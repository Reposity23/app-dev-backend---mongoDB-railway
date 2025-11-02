import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String? token;

  @HiveField(4)
  final String department;

  @HiveField(5)
  final String? address; // New field

  User({
    required this.id,
    required this.username,
    required this.email,
    this.token,
    required this.department,
    this.address, // New field
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
      department: json['department'] ?? '',
      address: json['address'], // New field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'token': token,
      'department': department,
      'address': address, // New field
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? token,
    String? department,
    String? address, // New field
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      token: token ?? this.token,
      department: department ?? this.department,
      address: address ?? this.address, // New field
    );
  }
}
