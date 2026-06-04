import 'package:dart_pos_system/enum/role.dart';

class User {
  String? id;
  String? username;
  Role role = Role.sale;

  User({this.id, this.username});

  User.fromJson(Map<String, dynamic> json) {
    id =
        json['id'] ??
        json['_id']; // Safe fallback if backend returns mongo style _id
    username = json['username'];

    // 🎯 FIX: Extract raw string, trim spaces, and make it lowercase
    final String backendRole = (json['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    // 🎯 FIX: Match against your Enum by converting the enum value to lowercase too!
    role = Role.values.firstWhere(
      (r) =>
          r.name.toLowerCase() == backendRole ||
          r.toString().split('.').last.toLowerCase() == backendRole,
      orElse: () => Role.sale,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['username'] = username;
    data['role'] = role;
    return data;
  }
}
