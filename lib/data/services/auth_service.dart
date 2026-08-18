import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firdan_farma_windows/data/database/database_helper.dart';
import 'package:firdan_farma_windows/data/models/user_model.dart';

class AuthSession {
  static UserAccount? currentUser;

  static int? get userId => currentUser?.id;
  static String? get username => currentUser?.username;
  static String? get role => currentUser?.role;
  static bool get isSuperAdmin => currentUser?.isSuperAdmin == true;

  static void clear() => currentUser = null;
}

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> ensureDefaultUsers() async {
    final db = await _dbHelper.database;
    final count = await db.rawQuery('SELECT COUNT(*) AS count FROM pengguna');
    if ((count.first['count'] as int? ?? 0) > 0) return;

    final now = DateTime.now().toIso8601String();
    await db.insert('pengguna', {
      'username': 'admin1',
      'password_hash': hashPassword('admin123'),
      'nama_tampilan': 'Admin Utama',
      'role': 'SUPER_ADMIN',
      'is_active': 1,
      'created_at': now,
    });
    await db.insert('pengguna', {
      'username': 'karyawan',
      'password_hash': hashPassword('karyawan123'),
      'nama_tampilan': 'Karyawan Apotek',
      'role': 'KARYAWAN',
      'is_active': 1,
      'created_at': now,
    });
  }

  Future<UserAccount?> login(String username, String password) async {
    await ensureDefaultUsers();
    final db = await _dbHelper.database;
    final maps = await db.query(
      'pengguna',
      where: 'LOWER(username) = LOWER(?) AND is_active = 1',
      whereArgs: [username.trim()],
      limit: 1,
    );
    if (maps.isEmpty || maps.first['password_hash'] != hashPassword(password)) {
      return null;
    }

    final user = UserAccount.fromMap(maps.first);
    AuthSession.currentUser = user;
    await db.insert('audit_log', {
      'user_id': user.id,
      'username_snapshot': user.username,
      'role_snapshot': user.role,
      'aksi': 'LOGIN',
      'entitas': 'APLIKASI',
      'detail': 'Login berhasil',
      'created_at': DateTime.now().toIso8601String(),
    });
    return user;
  }

  Future<void> logout() async {
    final user = AuthSession.currentUser;
    if (user != null) {
      final db = await _dbHelper.database;
      await db.insert('audit_log', {
        'user_id': user.id,
        'username_snapshot': user.username,
        'role_snapshot': user.role,
        'aksi': 'LOGOUT',
        'entitas': 'APLIKASI',
        'detail': 'Logout',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    AuthSession.clear();
  }

  Future<List<UserAccount>> getUsers() async {
    final db = await _dbHelper.database;
    final maps = await db.query('pengguna', orderBy: 'username ASC');
    return maps.map(UserAccount.fromMap).toList();
  }

  Future<int> saveUser({
    int? id,
    required String username,
    required String namaTampilan,
    required String role,
    String? password,
    bool isActive = true,
  }) async {
    if (!AuthSession.isSuperAdmin) {
      throw Exception('Hanya Super Admin yang dapat mengubah pengguna.');
    }
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty || namaTampilan.trim().isEmpty) {
      throw Exception('Username dan nama pengguna wajib diisi.');
    }
    if (!{'KARYAWAN', 'SUPER_ADMIN'}.contains(role)) {
      throw Exception('Role pengguna tidak valid.');
    }
    if (id == null && (password == null || password.length < 6)) {
      throw Exception('Password pengguna baru minimal 6 karakter.');
    }
    if (id != null &&
        id == AuthSession.userId &&
        (role != 'SUPER_ADMIN' || !isActive)) {
      throw Exception(
        'Akun Super Admin yang sedang dipakai tidak boleh dinonaktifkan atau diturunkan rolenya.',
      );
    }

    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    if (id == null) {
      final createdId = await db.insert('pengguna', {
        'username': cleanUsername,
        'password_hash': hashPassword(password!),
        'nama_tampilan': namaTampilan.trim(),
        'role': role,
        'is_active': isActive ? 1 : 0,
        'created_at': now,
      });
      await db.insert('audit_log', {
        'user_id': AuthSession.userId,
        'username_snapshot': AuthSession.username ?? 'SISTEM',
        'role_snapshot': AuthSession.role ?? 'SISTEM',
        'aksi': 'PENGGUNA_TAMBAH',
        'entitas': 'PENGGUNA',
        'entitas_id': createdId,
        'detail': cleanUsername,
        'created_at': now,
      });
      return createdId;
    }

    final values = <String, dynamic>{
      'username': cleanUsername,
      'nama_tampilan': namaTampilan.trim(),
      'role': role,
      'is_active': isActive ? 1 : 0,
      'updated_at': now,
      if (password?.isNotEmpty == true)
        'password_hash': hashPassword(password!),
    };
    final changed = await db.update(
      'pengguna',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed > 0) {
      await db.insert('audit_log', {
        'user_id': AuthSession.userId,
        'username_snapshot': AuthSession.username ?? 'SISTEM',
        'role_snapshot': AuthSession.role ?? 'SISTEM',
        'aksi': 'PENGGUNA_UBAH',
        'entitas': 'PENGGUNA',
        'entitas_id': id,
        'detail': cleanUsername,
        'created_at': now,
      });
    }
    return changed;
  }
}
