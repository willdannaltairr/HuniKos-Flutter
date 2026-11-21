import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_image_view.dart';

/// Halaman profil dipakai ketiga peran: ubah nama/telepon, ganti foto,
/// dan logout dengan konfirmasi.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});

  /// True saat ditampilkan di dalam shell (tanpa AppBar sendiri).
  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _phone = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: _name.text.trim(),
      phoneNumber: _phone.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      showSuccess(context, 'Profil berhasil diperbarui');
    } else {
      showError(context, auth.error ?? 'Gagal memperbarui profil');
    }
  }

  Future<void> _changeAvatar() async {
    final auth = context.read<AuthProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final length = await picked.length();
    if (length > 2 * 1024 * 1024) {
      if (!mounted) return;
      showError(context, 'Ukuran gambar maksimal 2 MB');
      return;
    }

    final success = await auth.uploadAvatar(picked);
    if (!mounted) return;
    if (success) {
      showSuccess(context, 'Foto profil diperbarui');
    } else {
      showError(context, auth.error ?? 'Gagal mengunggah foto');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Kamu perlu masuk lagi untuk membuka data sewa.',
      confirmLabel: 'Keluar',
    );
    if (!confirmed || !mounted) return;

    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Profil')),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          _Avatar(user.avatarUrl, initials: user.initials),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Material(
                              color: AppColors.primary,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: auth.isSubmitting ? null : _changeAvatar,
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(Icons.camera_alt_outlined,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.blueTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          user.roleLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _name,
                        label: 'Nama lengkap',
                        icon: Icons.person_outline,
                        validator: Validators.fullName,
                        serverError: auth.fieldErrors['full_name'],
                        enabled: !auth.isSubmitting,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _phone,
                        label: 'Nomor telepon',
                        hint: 'Contoh: 08123456789',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phoneNumber,
                        serverError: auth.fieldErrors['phone_number'],
                        enabled: !auth.isSubmitting,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: auth.isSubmitting ? null : _save,
                  child: auth.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan perubahan'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Keluar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dangerText,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.url, {required this.initials});

  final String? url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ClipOval(
      child: NetworkImageView(
        url: url,
        width: 88,
        height: 88,
        borderRadius: 44,
      ),
    );
  }
}
