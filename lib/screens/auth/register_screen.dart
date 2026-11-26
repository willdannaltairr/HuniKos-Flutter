import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/role_home.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import 'auth_field.dart';
import 'auth_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  String _role = 'tenant';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: _role,
      phoneNumber: _phone.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      context.go(homeForRole(auth.user!.role));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthShell(
      title: 'Ayo siapkan\nakunmu',
      subtitle: 'Daftar untuk mulai mencari atau mengelola kos.',
      backTo: '/login',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthTabs(isRegister: true),
            const SizedBox(height: 16),
            _RoleSelector(
              value: _role,
              onChanged: (value) => setState(() => _role = value),
            ),
            if (auth.fieldErrors['role'] != null) ...[
              const SizedBox(height: 6),
              Text(
                auth.fieldErrors['role']!,
                style: AppFonts.label(12, weight: FontWeight.w600, color: AppColors.dangerText),
              ),
            ],
            const SizedBox(height: 12),
            AuthField(
              controller: _name,
              label: 'Nama lengkap',
              hint: 'Sesuai KTP',
              icon: Icons.person_outline,
              validator: Validators.fullName,
              serverError: auth.fieldErrors['full_name'],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            AuthField(
              controller: _email,
              label: 'Alamat email',
              hint: 'nama@email.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              serverError: auth.fieldErrors['email'],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            AuthField(
              controller: _phone,
              label: 'Nomor telepon (opsional)',
              hint: '08123456789',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.phoneNumber,
              serverError: auth.fieldErrors['phone_number'],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            AuthField(
              controller: _password,
              label: 'Password',
              hint: 'Minimal 8 karakter, ada huruf dan angka',
              icon: Icons.lock_outline,
              obscureText: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              validator: Validators.password,
              serverError: auth.fieldErrors['password'],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            AuthField(
              controller: _confirm,
              label: 'Ulangi password',
              hint: 'Ketik ulang password',
              icon: Icons.lock_outline,
              obscureText: _obscure,
              validator: (value) =>
                  Validators.passwordConfirmation(value, _password.text),
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
            ),
            if (auth.error != null && auth.fieldErrors.isEmpty) ...[
              const SizedBox(height: 10),
              Text(
                auth.error!,
                style: AppFonts.label(12.5, weight: FontWeight.w600, color: AppColors.dangerText),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: auth.isSubmitting ? null : _submit,
              child: auth.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Daftar'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sudah punya akun?',
                  style: AppFonts.label(13, color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Masuk'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saya mendaftar sebagai',
          style: AppFonts.label(11.5, weight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _RoleOption(
                label: 'Penyewa',
                description: 'Mencari dan menyewa kos',
                icon: Icons.person_outline,
                selected: value == 'tenant',
                onTap: () => onChanged('tenant'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RoleOption(
                label: 'Pemilik',
                description: 'Mengelola kos sendiri',
                icon: Icons.storefront_outlined,
                selected: value == 'owner',
                onTap: () => onChanged('owner'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.paperSoft : AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          // Kartu terpilih ditandai garis hitam tebal, bukan warna aksen,
          // supaya tetap tenang seperti sisa aplikasi.
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.ink : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppFonts.label(
                13.5,
                weight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: AppFonts.label(11, weight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
