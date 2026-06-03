class User {
  String? id;
  String? username;
  String? role;

  User({this.id, this.username, this.role});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['username'] = username;
    data['role'] = role;
    return data;
  }
}
