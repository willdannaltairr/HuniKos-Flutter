import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/profile_finance_card.dart';

/// Halaman profil dengan dua bagian utama: pengaturan tampilan dan bahasa,
/// lalu ringkasan keuangan yang berbeda tiap peran.
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
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _phone = TextEditingController(text: user?.phoneNumber ?? '');

    // Angka keuangan dimuat sekali saat halaman dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (user?.isTenant ?? false) {
        final tenant = context.read<TenantProvider>();
        tenant.loadBookings();
        tenant.loadPayments();
        tenant.loadMaintenance();
      } else if (user?.isOwner ?? false) {
        context.read<OwnerProvider>().loadDashboard();
      } else if (user?.isAdmin ?? false) {
        context.read<AdminProvider>().loadDashboard();
      }
    });
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
      setState(() => _editing = false);
      showSuccess(context, I18n.t('profile.saved'));
    } else {
      showError(context, auth.error ?? I18n.t('profile.saveFailed'));
    }
  }

  Future<void> _changeAvatar() async {
    final auth = context.read<AuthProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    if (await picked.length() > 2 * 1024 * 1024) {
      if (!mounted) return;
      showError(context, I18n.t('profile.imageTooLarge'));
      return;
    }

    final success = await auth.uploadAvatar(picked);
    if (!mounted) return;
    if (success) {
      showSuccess(context, I18n.t('profile.photoUpdated'));
    } else {
      showError(context, auth.error ?? I18n.t('profile.uploadFailed'));
    }
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: I18n.t('profile.logoutTitle'),
      message: I18n.t('profile.logoutMessage'),
      confirmLabel: I18n.t('profile.logout'),
    );
    if (!confirmed || !mounted) return;

    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<AppSettings>();
    final user = auth.user;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: Text(I18n.t('profile.title'))),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _ProfileHeader(
                  user: user,
                  onChangePhoto: auth.isSubmitting ? null : _changeAvatar,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileFinanceCard(role: user.role),
                      const SizedBox(height: 18),
                      _SectionTitle(title: I18n.t('profile.settings')),
                      const SizedBox(height: 8),
                      _SettingsCard(settings: settings),
                      const SizedBox(height: 18),
                      _SectionTitle(title: I18n.t('profile.account')),
                      const SizedBox(height: 8),
                      _AccountCard(
                        editing: _editing,
                        onEdit: () => setState(() => _editing = !_editing),
                        onLogout: _logout,
                      ),
                      if (_editing) ...[
                        const SizedBox(height: 12),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _name,
                                label: I18n.t('profile.name'),
                                icon: Icons.person_outline,
                                validator: Validators.fullName,
                                serverError: auth.fieldErrors['full_name'],
                                enabled: !auth.isSubmitting,
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _phone,
                                label: I18n.t('profile.phone'),
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: Validators.phoneNumber,
                                serverError: auth.fieldErrors['phone_number'],
                                enabled: !auth.isSubmitting,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: auth.isSubmitting ? null : _save,
                          child: auth.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(I18n.t('profile.save')),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppFonts.title(17, weight: FontWeight.w700));
  }
}

/// Kepala ungu dengan foto profil, nama, peran, dan tiga angka ringkas.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onChangePhoto});

  final User user;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final roleCounts = _counts(context, user.role);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4527A0), Color(0xFF7B3FE4)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.canPop() ? context.pop() : context.go('/tenant'),
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  Text(
                    I18n.t('profile.title'),
                    style: AppFonts.title(16, weight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
              const SizedBox(height: 18),
              Stack(
                children: [
                  _Avatar(url: user.avatarUrl, initials: user.initials),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onChangePhoto,
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(Icons.edit_outlined, size: 15, color: Color(0xFF4527A0)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                user.fullName,
                style: AppFonts.title(20, weight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                user.roleLabel,
                style: AppFonts.label(12, color: Colors.white.withValues(alpha: 0.78)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (final item in roleCounts) Expanded(child: _StatBox(item: item)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tiga angka ringkas yang berbeda tiap peran.
  static List<({String label, String value})> _counts(BuildContext context, String role) {
    if (role == 'tenant') {
      final tenant = context.read<TenantProvider>();
      return [
        (label: 'Booking', value: '${tenant.bookings.length}'),
        (label: 'Laporan', value: '${tenant.maintenance.length}'),
        (label: 'Bayar', value: '${tenant.payments.length}'),
      ];
    }
    if (role == 'owner') {
      final owner = context.read<OwnerProvider>();
      return [
        (label: 'Properti', value: '${owner.properties.length}'),
        (label: 'Kamar', value: '${owner.rooms.length}'),
        (label: 'Booking', value: '${owner.bookings.length}'),
      ];
    }
    final admin = context.read<AdminProvider>();
    return [
      (label: 'Pengguna', value: '${admin.usersMeta.total}'),
      (label: 'Properti', value: '${admin.dashboard?.totalProperties ?? 0}'),
      (label: 'Verifikasi', value: '${admin.dashboard?.pendingProperties ?? 0}'),
    ];
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.item});

  final ({String label, String value}) item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            item.value,
            style: AppFonts.title(19, weight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: AppFonts.label(10.5, color: Colors.white.withValues(alpha: 0.72)),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              settings.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: AppColors.textPrimary,
            ),
            title: Text(I18n.t('profile.darkMode')),
            value: settings.isDark,
            onChanged: (_) => settings.toggleTheme(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(I18n.t('profile.language')),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.paperSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                settings.language == AppLanguage.id ? 'ID' : 'EN',
                style: AppFonts.label(12, weight: FontWeight.w700),
              ),
            ),
            onTap: () => settings.toggleLanguage(),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.editing,
    required this.onEdit,
    required this.onLogout,
  });

  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            title: Text(I18n.t('profile.edit')),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: onEdit,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout_outlined, color: AppColors.dangerText),
            title: Text(
              I18n.t('profile.logout'),
              style: AppFonts.label(14, color: AppColors.dangerText),
            ),
            trailing: Icon(Icons.chevron_right, size: 18, color: AppColors.dangerText),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.initials});

  final String? url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: AppFonts.title(26, weight: FontWeight.w700, color: Color(0xFF4527A0)),
        ),
      );
    }
    return ClipOval(
      child: NetworkImageView(url: url, width: 80, height: 80, borderRadius: 40),
    );
  }
}
