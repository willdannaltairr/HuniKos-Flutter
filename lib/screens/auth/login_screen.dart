import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/role_home.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import 'auth_header.dart';

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

    return Scaffold(
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
                      title: 'Masuk ke HuniKos',
                      subtitle: 'Cari kos dan kelola sewa dalam satu tempat.',
                    ),
                    if (_sessionMessage != null) ...[
                      const SizedBox(height: 16),
                      _InfoBanner(
                        message: _sessionMessage!,
                        onDismiss: () => setState(() => _sessionMessage = null),
                      ),
                    ],
                    const SizedBox(height: 20),
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
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscure,
                      validator: (value) =>
                          (value ?? '').isEmpty ? 'Password wajib diisi' : null,
                      serverError: auth.fieldErrors['password'],
                      textInputAction: TextInputAction.done,
                      onSubmitted: _submit,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                      ),
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
                                color: Colors.white,
                              ),
                            )
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Belum punya akun? Daftar'),
                    ),
                    const SizedBox(height: 4),
                    const _DemoAccounts(),
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

/// Akun uji dari kontrak bagian 10, supaya demo ke penguji tidak perlu
/// menghafal email.
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Akun uji', style: AppFonts.label(12, weight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(
            'Penyewa: tenant1@hunikos.test / Tenant123!\n'
            'Pemilik: owner1@hunikos.test / Owner123!\n'
            'Admin: admin@hunikos.test / Admin123!',
            style: AppFonts.label(
              11.5,
              weight: FontWeight.w500,
              color: AppColors.textSecondary,
            ).copyWith(height: 1.6),
          ),
        ],
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
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.goldDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppFonts.label(12.5, weight: FontWeight.w600, color: AppColors.goldDeep),
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


