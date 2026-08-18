import 'package:flutter/material.dart';
import 'package:firdan_farma_windows/core/theme/app_theme.dart';
import 'package:firdan_farma_windows/data/models/user_model.dart';
import 'package:firdan_farma_windows/data/services/auth_service.dart';
import 'package:firdan_farma_windows/shared/widgets/app_page.dart';
import 'package:firdan_farma_windows/shared/widgets/medical_card.dart';

class PenggunaScreen extends StatefulWidget {
  const PenggunaScreen({super.key});

  @override
  State<PenggunaScreen> createState() => _PenggunaScreenState();
}

class _PenggunaScreenState extends State<PenggunaScreen> {
  final AuthService _service = AuthService();
  Future<List<UserAccount>>? _usersFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _usersFuture = _service.getUsers());
  }

  Future<void> _showUserDialog({UserAccount? user}) async {
    if (!AuthSession.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman ini hanya untuk Super Admin.')),
      );
      return;
    }
    final username = TextEditingController(text: user?.username ?? '');
    final displayName = TextEditingController(text: user?.namaTampilan ?? '');
    final password = TextEditingController();
    var role = user?.role ?? 'KARYAWAN';
    var active = user?.isActive ?? true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Tambah Pengguna' : 'Ubah Pengguna'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: username,
                  enabled: user == null,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: displayName,
                  decoration: const InputDecoration(labelText: 'Nama tampilan'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: user == null ? 'Password *' : 'Password baru',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                      value: 'KARYAWAN',
                      child: Text('Karyawan'),
                    ),
                    DropdownMenuItem(
                      value: 'SUPER_ADMIN',
                      child: Text('Super Admin'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => role = value ?? role),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pengguna aktif'),
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _service.saveUser(
                    id: user?.id,
                    username: username.text,
                    namaTampilan: displayName.text,
                    role: role,
                    password: password.text.isEmpty ? null : password.text,
                    isActive: active,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    username.dispose();
    displayName.dispose();
    password.dispose();
    if (saved == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthSession.isSuperAdmin;
    return AppPage(
      title: 'Pengguna',
      subtitle: 'Atur akun karyawan dan Super Admin',
      icon: Icons.manage_accounts_outlined,
      actions: [
        ElevatedButton.icon(
          onPressed: canEdit ? () => _showUserDialog() : null,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Pengguna'),
        ),
      ],
      child: MedicalCard(
        child: FutureBuilder<List<UserAccount>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!canEdit) {
              return const EmptyState(
                icon: Icons.lock_outline,
                title: 'Akses Super Admin diperlukan',
                subtitle: 'Karyawan tidak dapat mengubah akun pengguna.',
              );
            }
            final users = snapshot.data ?? const <UserAccount>[];
            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.isSuperAdmin
                        ? AppTheme.primaryTealLight
                        : AppTheme.emeraldLight,
                    child: Icon(
                      user.isSuperAdmin
                          ? Icons.shield_outlined
                          : Icons.person_outline,
                      color: user.isSuperAdmin
                          ? AppTheme.primaryTeal
                          : AppTheme.emeraldGreen,
                    ),
                  ),
                  title: Text('${user.username} | ${user.namaTampilan}'),
                  subtitle: Text(
                    '${user.role} | ${user.isActive ? 'Aktif' : 'Nonaktif'}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Ubah pengguna',
                    onPressed: () => _showUserDialog(user: user),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
