import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/audit_log_model.dart';
import 'package:firdan_farma_windows/data/services/auth_service.dart';

class AuditService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> log({
    required String aksi,
    required String entitas,
    int? entitasId,
    String? metodePembayaran,
    double? nominal,
    String? alasan,
    String? detail,
  }) async {
    final user = AuthSession.currentUser;
    final db = await _dbHelper.database;
    return db.insert('audit_log', {
      'user_id': user?.id,
      'username_snapshot': user?.username ?? 'SISTEM',
      'role_snapshot': user?.role ?? 'SISTEM',
      'aksi': aksi,
      'entitas': entitas,
      'entitas_id': entitasId,
      'metode_pembayaran': metodePembayaran,
      'nominal': nominal,
      'alasan': alasan,
      'detail': detail,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AuditLog>> getAll({int limit = 300}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'audit_log',
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
    );
    return maps.map(AuditLog.fromMap).toList();
  }
}
