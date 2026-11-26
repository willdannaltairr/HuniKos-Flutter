import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/token_storage.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/owner_provider.dart';
import 'providers/tenant_provider.dart';
import 'services/admin_service.dart';
import 'services/catalog_service.dart';
import 'services/owner_service.dart';
import 'services/tenant_service.dart';

class HuniKosApp extends StatefulWidget {
  const HuniKosApp({super.key});

  @override
  State<HuniKosApp> createState() => _HuniKosAppState();
}

class _HuniKosAppState extends State<HuniKosApp> {
  late final TokenStorage _tokens;
  late final ApiClient _api;
  late final AuthProvider _auth;
  late final CatalogProvider _catalog;
  late final TenantProvider _tenant;
  late final OwnerProvider _owner;
  late final AdminProvider _admin;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _tokens = TokenStorage();
    _api = ApiClient(_tokens);
    _auth = AuthProvider(api: _api, tokenStore: _tokens);
    _catalog = CatalogProvider(CatalogService(_api));
    _tenant = TenantProvider(TenantService(_api));
    _owner = OwnerProvider(OwnerService(_api));
    _admin = AdminProvider(AdminService(_api));
    _router = buildRouter(_auth);

    // Provider di bawah hidup selama aplikasi terbuka. Begitu sesi berakhir,
    // isinya dikosongkan supaya akun berikutnya tidak melihat data akun lama.
    _auth.addListener(_kosongkanStateAkunSaatLogout);

    // Auto-login: token tersimpan langsung dipakai saat aplikasi dibuka.
    _auth.bootstrap();
  }

  bool _sebelumnyaLogin = false;

  void _kosongkanStateAkunSaatLogout() {
    final login = _auth.isLoggedIn;
    if (_sebelumnyaLogin && !login) {
      _tenant.reset();
      _owner.reset();
      _admin.reset();
    }
    _sebelumnyaLogin = login;
  }

  @override
  void dispose() {
    _auth.removeListener(_kosongkanStateAkunSaatLogout);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _catalog),
        ChangeNotifierProvider.value(value: _tenant),
        ChangeNotifierProvider.value(value: _owner),
        ChangeNotifierProvider.value(value: _admin),
      ],
      child: MaterialApp.router(
        title: 'HuniKos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        routerConfig: _router,
        // Kanvas putih dipasang sekali di sini agar semua layar konsisten.
        builder: (context, child) => AppTheme.backdrop(child: child!),
      ),
    );
  }
}
