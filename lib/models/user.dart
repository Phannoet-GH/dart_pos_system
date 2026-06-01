class User {
  String? id;
  String? username;
  String? password;
  String? role;

  User({this.id, this.username, this.password, this.role});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    password = json['password'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['username'] = username;
    data['password'] = password;
    data['role'] = role;
    return data;
  }
}
