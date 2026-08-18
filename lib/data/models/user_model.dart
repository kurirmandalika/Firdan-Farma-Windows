class UserAccount {
  final int? id;
  final String username;
  final String namaTampilan;
  final String role;
  final bool isActive;
  final String createdAt;

  const UserAccount({
    this.id,
    required this.username,
    required this.namaTampilan,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isSuperAdmin => role == 'SUPER_ADMIN';

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] as int?,
      username: map['username'] as String,
      namaTampilan:
          map['nama_tampilan'] as String? ?? map['username'] as String,
      role: (map['role'] as String? ?? 'KARYAWAN').toUpperCase(),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
