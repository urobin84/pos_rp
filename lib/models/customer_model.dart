class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final DateTime? dateOfBirth;
  final DateTime registrationDate;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.dateOfBirth,
    required this.registrationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  static Customer fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      dateOfBirth:
          map['dateOfBirth'] != null
              ? DateTime.parse(map['dateOfBirth'])
              : null,
      registrationDate: DateTime.parse(map['registrationDate']),
    );
  }
}
