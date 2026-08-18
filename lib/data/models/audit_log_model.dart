class AuditLog {
  final int? id;
  final int? userId;
  final String? username;
  final String? role;
  final String aksi;
  final String entitas;
  final int? entitasId;
  final String? metodePembayaran;
  final double? nominal;
  final String? alasan;
  final String? detail;
  final String createdAt;

  const AuditLog({
    this.id,
    this.userId,
    this.username,
    this.role,
    required this.aksi,
    required this.entitas,
    this.entitasId,
    this.metodePembayaran,
    this.nominal,
    this.alasan,
    this.detail,
    required this.createdAt,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      username: map['username_snapshot'] as String?,
      role: map['role_snapshot'] as String?,
      aksi: map['aksi'] as String? ?? '-',
      entitas: map['entitas'] as String? ?? '-',
      entitasId: map['entitas_id'] as int?,
      metodePembayaran: map['metode_pembayaran'] as String?,
      nominal: (map['nominal'] as num?)?.toDouble(),
      alasan: map['alasan'] as String?,
      detail: map['detail'] as String?,
      createdAt:
          map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
