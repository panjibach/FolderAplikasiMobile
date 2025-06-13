import 'package:utsproject/models/category.dart';
import 'package:intl/intl.dart';

class User {
  String? id; // Menggunakan String untuk ID karena di Flutter lebih fleksibel
  String? nama;
  String? email;
  String? password;
  String? profile;
  bool deleted;

  // Constructor
  User({
    this.id,
    this.nama,
    this.email,
    this.password,
    this.profile,
    this.deleted = false,
  });

  // Factory constructor untuk membuat objek dari JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // Debug log untuk melihat data yang diterima
    print('Parsing user JSON: $json');

    try {
      return User(
        id: json['id']?.toString(),
        nama: json['nama'],
        email: json['email'],
        profile: json['profile'] ?? 'default.jpg',
        deleted: json['deleted'] ?? false,
      );
    } catch (e) {
      print('Error membuat User dari JSON: $e');
      throw e; // Re-throw untuk debugging
    }
  }

  // Method untuk mengkonversi objek ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'password': password, // Perhatian: password dikirim ke server
      'profile': profile ?? 'default.jpg',
      'deleted': deleted,
    };
  }

  // Method untuk mengkonversi objek ke JSON untuk update (tanpa password)
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'profile': profile ?? 'default.jpg',
    };
  }

  @override
  String toString() {
    return 'User{id: $id, nama: $nama, email: $email, profile: $profile}';
  }
}
