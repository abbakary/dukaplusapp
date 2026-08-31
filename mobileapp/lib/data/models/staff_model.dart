import 'package:flutter/foundation.dart';

@immutable
class StaffMember {
  final String id;
  final String name;
  final String role;
  final String email;
  final String phone;
  final bool active;

  const StaffMember({
    required this.id,
    required this.name,
    this.role = 'Cashier',
    this.email = '',
    this.phone = '',
    this.active = true,
  });

  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    role: j['role']?.toString() ?? 'Cashier',
    email: j['email']?.toString() ?? '',
    phone: j['phone']?.toString() ?? '',
    active: j['active'] != false,
  );
}
