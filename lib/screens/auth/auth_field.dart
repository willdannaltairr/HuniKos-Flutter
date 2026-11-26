import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Kolom isian halaman auth: ikon di kotak kecil, label tipis di atas nilai,
/// dan seluruhnya dibungkus kotak bergaris.
///
/// Pesan kesalahan sengaja ditulis di LUAR kotak, dan kotaknya berubah merah
/// saat tidak valid, supaya pesan tidak mendorong isi kotak.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.validator,
    this.serverError,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final String? Function(String?)? validator;

  /// Pesan dari server; diprioritaskan di atas validasi lokal.
  final String? serverError;

  final bool obscureText;

  /// Bila diisi, muncul tombol mata di kanan untuk menampilkan sandi.
  final VoidCallback? onToggleObscure;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final bool enabled;
  final int? maxLength;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  @override
  Widget build(BuildContext context) {
    // FormField dipakai (bukan TextFormField) karena pesan errornya perlu
    // digambar di luar kotak; TextFormField selalu menaruhnya di dalam.
    return FormField<String>(
      initialValue: widget.controller.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => widget.validator?.call(value),
      builder: (field) {
        // Error server dibaca langsung dari properti, bukan dari field.errorText,
        // supaya langsung terlihat begitu respons API masuk.
        final error = widget.serverError ?? field.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: error == null ? AppColors.border : AppColors.danger,
                  width: error == null ? 1 : 1.4,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.paperSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, size: 17, color: AppColors.inkSoft),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.label(
                            10.5,
                            weight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        TextField(
                          controller: widget.controller,
                          onChanged: field.didChange,
                          obscureText: widget.obscureText,
                          keyboardType: widget.keyboardType,
                          textInputAction: widget.textInputAction,
                          maxLength: widget.maxLength,
                          onSubmitted: widget.onSubmitted == null
                              ? null
                              : (_) => widget.onSubmitted!(),
                          enabled: widget.enabled,
                          style: AppFonts.label(13.5, weight: FontWeight.w600, color: AppColors.ink),
                          decoration: InputDecoration(
                            // Kotak luar yang menggambar garis dan latar.
                            filled: false,
                            isDense: true,
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(vertical: 2),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: widget.hint,
                            hintStyle: AppFonts.label(13, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onToggleObscure != null)
                    GestureDetector(
                      onTap: widget.onToggleObscure,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          widget.obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, size: 13, color: AppColors.dangerText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        error,
                        style: AppFonts.label(
                          11,
                          weight: FontWeight.w500,
                          color: AppColors.dangerText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
