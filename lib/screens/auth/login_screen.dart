import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/role_home.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import 'auth_field.dart';
import 'auth_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirectTo});

  /// Halaman yang ingin dibuka pengguna sebelum diarahkan ke login
  /// (misal detail kos yang dibuka lewat tautan).
  final String? redirectTo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _sessionMessage;

  @override
  void initState() {
    super.initState();
    // Pesan "sesi berakhir" hanya ditampilkan sekali saat layar dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = context.read<AuthProvider>().takeSessionMessage();
      if (message != null && mounted) setState(() => _sessionMessage = message);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    if (success) {
      final target = widget.redirectTo;
      if (target != null && target.isNotEmpty) {
        context.go(target);
      } else {
        context.go(homeForRole(auth.user!.role));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthShell(
      title: 'Masuk dan lanjutkan\npencarian kosmu',
      subtitle: 'Satu akun untuk menyewa, membayar, dan melapor.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthTabs(isRegister: false),
            if (_sessionMessage != null) ...[
              const SizedBox(height: 14),
              _InfoBanner(
                message: _sessionMessage!,
                onDismiss: () => setState(() => _sessionMessage = null),
              ),
            ],
            const SizedBox(height: 16),
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
              controller: _password,
              label: 'Password',
              hint: 'Masukkan password',
              icon: Icons.lock_outline,
              obscureText: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Password wajib diisi' : null,
              serverError: auth.fieldErrors['password'],
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
                  : const Text('Masuk'),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Akun demo untuk pengujian',
                style: AppFonts.label(11.5, weight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            const _DemoAccounts(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Belum punya akun?',
                  style: AppFonts.label(13, color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Daftar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Akun uji dari kontrak bagian 10, supaya demo ke penguji tidak perlu
/// menghafal email.
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Penyewa   tenant1@hunikos.test / Tenant123!\n'
        'Pemilik     owner1@hunikos.test / Owner123!\n'
        'Admin       admin@hunikos.test / Admin123!',
        style: AppFonts.label(
          11.5,
          weight: FontWeight.w500,
          color: AppColors.textSecondary,
        ).copyWith(height: 1.7, fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppFonts.label(12.5, weight: FontWeight.w600, color: AppColors.inkSoft),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
