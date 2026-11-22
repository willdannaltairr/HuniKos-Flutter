import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/role_home.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import 'auth_header.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Buat akun')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Daftar HuniKos',
                      subtitle: 'Pilih peran sesuai kebutuhan kamu.',
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _name,
                      label: 'Nama lengkap',
                      icon: Icons.person_outline,
                      validator: Validators.fullName,
                      serverError: auth.fieldErrors['full_name'],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      serverError: auth.fieldErrors['email'],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _phone,
                      label: 'Nomor telepon (opsional)',
                      hint: 'Contoh: 08123456789',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phoneNumber,
                      serverError: auth.fieldErrors['phone_number'],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _password,
                      label: 'Password',
                      hint: 'Minimal 8 karakter, ada huruf dan angka',
                      icon: Icons.lock_outline,
                      obscureText: _obscure,
                      validator: Validators.password,
                      serverError: auth.fieldErrors['password'],
                      textInputAction: TextInputAction.next,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _confirm,
                      label: 'Ulangi password',
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
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: auth.isSubmitting ? null : _submit,
                      child: auth.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.navy,
                              ),
                            )
                          : const Text('Daftar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sudah punya akun? Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          style: AppFonts.label(13, weight: FontWeight.w700),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.goldSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21, color: selected ? AppColors.navy : AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(label, style: AppFonts.label(13.5, weight: FontWeight.w700)),
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
