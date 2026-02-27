class Faculty {
  final String uid;
  final String name;
  final String email;
  final String department;
  final String phone;
  final String idNumber;

  Faculty({
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    required this.phone,
    required this.idNumber,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      uid: (json['uid'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown Faculty').toString(),
      email: (json['email'] ?? 'No email').toString(),
      department: (json['department'] ?? 'Computer Science').toString(),
      phone: (json['phone'] ?? '+91 98765 43210').toString(),
      idNumber: (json['idNumber'] ?? 'CF-PROF-001').toString(),
    );
  }
}
