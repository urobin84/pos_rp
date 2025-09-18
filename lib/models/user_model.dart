class User {
  final String id;
  final String name;
  final String email;
  final String password; // Should be hashed in a real app
  final String? phone;
  final String? imagePath;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'imagePath': imagePath,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      phone: map['phone'],
      imagePath: map['imagePath'],
    );
  }
}
