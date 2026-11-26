import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

/// Kerangka dua halaman auth: foto kamar di kepala, lalu lembar putih
/// bersudut besar yang menampung form.
///
/// Form sengaja tidak bisa digeser. Bila layar terlalu pendek, isinya
/// diperkecil seperlunya supaya tetap utuh tanpa scroll.
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = (screenHeight * 0.30).clamp(170.0, 250.0);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/auth_header.jpg',
                  fit: BoxFit.cover,
                ),
                // Lapisan gelap supaya judul putih tetap terbaca di foto apa pun.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xCC1A1A1A), Color(0x991A1A1A)],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Leading(backTo: backTo),
                        const Spacer(),
                        Text(
                          title,
                          style: AppFonts.title(25, weight: FontWeight.w700, color: Colors.white)
                              .copyWith(height: 1.2),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: AppFonts.label(
                            12.5,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
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
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  12 + MediaQuery.of(context).viewPadding.bottom,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: constraints.maxWidth.clamp(0, 420).toDouble(),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lambang aplikasi di kiri atas kepala, atau tombol kembali bila diminta.
class _Leading extends StatelessWidget {
  const _Leading({this.backTo});

  final String? backTo;

  @override
  Widget build(BuildContext context) {
    final target = backTo;
    if (target != null) {
      return Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.go(target),
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
          ),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.home_work_rounded, size: 17, color: Colors.white),
        ),
        const SizedBox(width: 9),
        Text('HuniKos', style: AppFonts.title(15, weight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}

/// Sakelar dua tab: Masuk dan Daftar.
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
          _Tab(label: 'Masuk', active: !isRegister, onTap: () => context.go('/login')),
          _Tab(label: 'Daftar', active: isRegister, onTap: () => context.go('/register')),
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
        child: Container(
          height: 38,
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
              13,
              weight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.ink : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dua tombol masuk lewat penyedia pihak ketiga.
///
/// Backend HuniKos belum punya endpoint OAuth, jadi tombol ini belum bisa
/// menyelesaikan login; pemanggil yang menentukan pesan yang ditampilkan.
class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({super.key, required this.onPressed});

  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Apple',
            icon: Icons.apple,
            background: AppColors.ink,
            foreground: Colors.white,
            onTap: () => onPressed('Apple'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SocialButton(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            background: AppColors.paper,
            foreground: AppColors.ink,
            bordered: true,
            onTap: () => onPressed('Google'),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.bordered = false,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: bordered ? Border.all(color: AppColors.border) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppFonts.label(13.5, weight: FontWeight.w600, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
