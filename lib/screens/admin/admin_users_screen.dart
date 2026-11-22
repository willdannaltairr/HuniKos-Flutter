import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Kelola pengguna: cari, filter role/status, aktifkan atau nonaktifkan.
/// Akun admin tidak menampilkan tombol status.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _search = TextEditingController();
  String? _role;
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdminProvider>();
      if (provider.users.isEmpty && !provider.loadingUsers) {
        provider.loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggle(User user) async {
    final suspend = user.accountStatus == 'active';
    final confirmed = await showConfirmDialog(
      context,
      title: suspend ? 'Nonaktifkan akun?' : 'Aktifkan akun?',
      message: suspend
          ? '${user.fullName} tidak akan bisa masuk sampai diaktifkan lagi.'
          : '${user.fullName} bisa masuk kembali ke aplikasi.',
      confirmLabel: suspend ? 'Nonaktifkan' : 'Aktifkan',
      destructive: suspend,
    );
    if (!confirmed || !mounted) return;

    final error = await context
        .read<AdminProvider>()
        .changeUserStatus(user.id, suspend ? 'suspended' : 'active');
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, suspend ? 'Akun dinonaktifkan' : 'Akun diaktifkan');
    } else {
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengguna')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => provider.loadUsers(
                role: _role,
                accountStatus: _status,
                query: value,
              ),
              decoration: InputDecoration(
                hintText: 'Cari nama atau email',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  onPressed: () {
                    _search.clear();
                    provider.loadUsers(role: _role, accountStatus: _status, query: '');
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _roleChip(null, 'Semua'),
                _roleChip('tenant', 'Penyewa'),
                _roleChip('owner', 'Pemilik'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Nonaktif'),
                  selected: _status == 'suspended',
                  onSelected: (selected) {
                    setState(() => _status = selected ? 'suspended' : null);
                    provider.loadUsers(
                      role: _role,
                      accountStatus: _status,
                      query: _search.text,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _roleChip(String? value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _role == value,
        onSelected: (_) {
          setState(() => _role = value);
          context.read<AdminProvider>().loadUsers(
                role: value,
                accountStatus: _status,
                query: _search.text,
              );
        },
      ),
    );
  }

  Widget _buildBody(AdminProvider provider) {
    if (provider.loadingUsers && provider.users.isEmpty) {
      return const LoadingView();
    }
    if (provider.usersError != null) {
      return ErrorState(
        message: provider.usersError!,
        onRetry: () => provider.loadUsers(
          role: _role,
          accountStatus: _status,
          query: _search.text,
        ),
      );
    }
    if (provider.users.isEmpty) {
      return const EmptyState(
        title: 'Pengguna tidak ditemukan',
        description: 'Coba ubah kata kunci atau filter.',
        icon: Icons.people_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadUsers(
        role: _role,
        accountStatus: _status,
        query: _search.text,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: provider.users.length + (provider.hasMoreUsers ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= provider.users.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: OutlinedButton(
                onPressed: provider.loadingUsers
                    ? null
                    : () => provider.loadUsers(
                          role: _role,
                          accountStatus: _status,
                          query: _search.text,
                          reset: false,
                        ),
                child: Text(
                  provider.loadingUsers ? 'Memuat…' : 'Muat lebih banyak',
                ),
              ),
            );
          }

          final user = provider.users[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _Avatar(user),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            StatusChip(
                              compact: true,
                              status: user.accountStatus,
                              label: user.accountStatus == 'active'
                                  ? 'Aktif'
                                  : 'Nonaktif',
                            ),
                          ],
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${user.roleLabel} • bergabung '
                          '${Formatters.shortDate(_date(user.createdAt))}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!user.isAdmin)
                    IconButton(
                      tooltip: user.accountStatus == 'active'
                          ? 'Nonaktifkan akun'
                          : 'Aktifkan akun',
                      onPressed: () => _toggle(user),
                      icon: Icon(
                        user.accountStatus == 'active'
                            ? Icons.block
                            : Icons.check_circle_outline,
                        color: user.accountStatus == 'active'
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF15803D),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _date(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.user);

  final User user;

  @override
  Widget build(BuildContext context) {
    if (user.avatarUrl == null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.gold,
        child: Text(
          user.initials,
          style: AppFonts.label(13, weight: FontWeight.w700, color: AppColors.navy),
        ),
      );
    }
    return ClipOval(
      child: NetworkImageView(
        url: user.avatarUrl,
        width: 40,
        height: 40,
        borderRadius: 20,
      ),
    );
  }
}
