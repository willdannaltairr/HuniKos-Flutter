import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/role_home.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feedback.dart';
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
      title: I18n.t('auth.loginTitle'),
      subtitle: I18n.t('auth.loginSubtitle'),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthTabs(isRegister: false),
            if (_sessionMessage != null) ...[
              const SizedBox(height: 12),
              _InfoBanner(
                message: _sessionMessage!,
                onDismiss: () => setState(() => _sessionMessage = null),
              ),
            ],
            const SizedBox(height: 14),
            AuthField(
              controller: _email,
              label: I18n.t('auth.email'),
              hint: 'nama@email.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              serverError: auth.fieldErrors['email'],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            AuthField(
              controller: _password,
              label: I18n.t('auth.password'),
              hint: I18n.t('auth.passwordHint'),
              icon: Icons.lock_outline,
              obscureText: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              validator: (value) =>
                  (value ?? '').isEmpty ? I18n.t('auth.passwordRequired') : null,
              serverError: auth.fieldErrors['password'],
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
            ),
            if (auth.error != null && auth.fieldErrors.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                auth.error!,
                style: AppFonts.label(12, weight: FontWeight.w600, color: AppColors.dangerText),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: auth.isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: auth.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(I18n.t('auth.login')),
            ),
            const SizedBox(height: 12),
            _DividerLabel(text: I18n.t('auth.orContinue')),
            const SizedBox(height: 12),
            AuthSocialButtons(onPressed: _social),
          ],
        ),
      ),
    );
  }

  /// Backend belum menyediakan OAuth, jadi tombol sosial hanya menjelaskan
  /// bahwa jalurnya belum tersedia alih-alih gagal diam-diam.
  void _social(String provider) {
    showError(
      context,
      I18n.t('auth.socialUnavailable', {'provider': provider}),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: AppFonts.label(11, weight: FontWeight.w500, color: AppColors.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
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
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 17, color: AppColors.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppFonts.label(12, weight: FontWeight.w600, color: AppColors.inkSoft),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 15),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }
}
