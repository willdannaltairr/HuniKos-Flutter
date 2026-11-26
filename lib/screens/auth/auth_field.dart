import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Kolom isian halaman auth: ikon di kotak kecil, label tipis di atas nilai,
/// dan seluruhnya dibungkus kartu bergaris tipis.
///
/// Dipisah dari [AppTextField] karena bentuk ini hanya dipakai di login dan
/// register; form lain tetap memakai kolom biasa.
class AuthField extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.paperSoft,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 18, color: AppColors.inkSoft),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.label(
                    11.5,
                    weight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                TextFormField(
                  controller: controller,
                  validator: validator ?? (_) => serverError,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
                  enabled: enabled,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: AppFonts.label(14, weight: FontWeight.w600, color: AppColors.ink),
                  decoration: InputDecoration(
                    // Kotak luar sudah menggambar garis dan latar, jadi
                    // dekorasi bawaan dimatikan seluruhnya.
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(bottom: 4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: AppFonts.label(13.5, color: AppColors.textSecondary),
                    errorStyle: AppFonts.label(
                      11.5,
                      weight: FontWeight.w500,
                      color: AppColors.dangerText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onToggleObscure != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: GestureDetector(
                onTap: onToggleObscure,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
