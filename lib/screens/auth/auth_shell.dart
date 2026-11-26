import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

/// Kerangka dua halaman auth: kepala gelap dengan judul putih, lalu lembar
/// putih bersudut besar yang menampung form.
///
/// Dipakai bersama oleh login dan register supaya keduanya terasa satu
/// halaman yang berpindah tab, bukan dua layar terpisah.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.backTo,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Bila diisi, kepala menampilkan tombol kembali ke rute tersebut.
  final String? backTo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40, child: _Leading(backTo: backTo)),
                  const SizedBox(height: 26),
                  Text(
                    title,
                    style: AppFonts.title(27, weight: FontWeight.w700, color: Colors.white)
                        .copyWith(height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: AppFonts.label(
                      13,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.66),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    20 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Penanda di kiri atas kepala: tombol kembali, atau lambang aplikasi.
class _Leading extends StatelessWidget {
  const _Leading({this.backTo});

  final String? backTo;

  @override
  Widget build(BuildContext context) {
    final target = backTo;
    if (target != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.go(target),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.arrow_back_rounded, size: 19, color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.home_work_rounded, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text('HuniKos', style: AppFonts.title(16, weight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}

/// Sakelar dua tab di atas form: Masuk dan Daftar.
class AuthTabs extends StatelessWidget {
  const AuthTabs({super.key, required this.isRegister});

  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Masuk',
            active: !isRegister,
            onTap: () => context.go('/login'),
          ),
          _Tab(
            label: 'Daftar',
            active: isRegister,
            onTap: () => context.go('/register'),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.paper : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            style: AppFonts.label(
              13.5,
              weight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.ink : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
