import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/property.dart';
import '../providers/auth_provider.dart';
import '../providers/owner_provider.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_properties_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/owner/owner_bookings_screen.dart';
import '../screens/owner/owner_dashboard_screen.dart';
import '../screens/owner/owner_maintenance_screen.dart';
import '../screens/owner/owner_payments_screen.dart';
import '../screens/owner/owner_properties_screen.dart';
import '../screens/owner/owner_property_detail_screen.dart';
import '../screens/owner/owner_rooms_screen.dart';
import '../screens/owner/owner_shell.dart';
import '../screens/owner/property_form_screen.dart';
import '../screens/owner/room_form_screen.dart';
import '../screens/shared/admin_property_detail_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../screens/tenant/booking_detail_screen.dart';
import '../screens/tenant/booking_form_screen.dart';
import '../screens/tenant/explore_screen.dart';
import '../screens/tenant/maintenance_form_screen.dart';
import '../screens/tenant/maintenance_list_screen.dart';
import '../screens/tenant/my_bookings_screen.dart';
import '../screens/tenant/property_detail_screen.dart';
import '../screens/tenant/room_detail_screen.dart';
import '../screens/tenant/tenant_shell.dart';
import 'role_home.dart';

/// Halaman yang boleh dibuka tanpa login, termasuk detail kos dan kamar.
const _publicPrefixes = ['/explore', '/login', '/register', '/properties/', '/rooms/'];

bool _isPublic(String location) {
  final path = Uri.parse(location).path;
  return _publicPrefixes.any((prefix) => path == prefix || path.startsWith(prefix));
}

/// Penjaga akses: satu tempat untuk login, peran, dan sesi kedaluwarsa.
String? _guard(BuildContext context, GoRouterState state) {
  final auth = context.read<AuthProvider>();
  final location = state.matchedLocation;

  if (auth.status == AuthStatus.checking) return null;

  if (!auth.isLoggedIn) {
    if (_isPublic(location)) return null;
    final target = Uri.encodeComponent(state.uri.toString());
    return '/login?redirect=$target';
  }

  final role = auth.user!.role;

  if (location == '/login' || location == '/register') {
    return homeForRole(role);
  }

  // Peran lain tidak boleh masuk ke area milik peran ini.
  if (location.startsWith('/owner') && role != 'owner') return homeForRole(role);
  if (location.startsWith('/admin') && role != 'admin') return homeForRole(role);
  if (location.startsWith('/tenant') && role != 'tenant') return homeForRole(role);
  if (location.startsWith('/bookings') && role != 'tenant') return homeForRole(role);
  if (location.startsWith('/maintenance') && role != 'tenant') return homeForRole(role);

  return null;
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/explore',
    redirect: (context, state) => _guard(context, state),
    routes: [
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/properties/:id',
        builder: (context, state) => PropertyDetailScreen(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/rooms/:id',
        builder: (context, state) => RoomDetailScreen(
          roomId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/rooms/:id/book',
        builder: (context, state) => BookingFormScreen(
          roomId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/bookings/:id',
        builder: (context, state) => BookingDetailScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/maintenance/new',
        builder: (context, state) => MaintenanceFormScreen(
          initialBookingId: state.uri.queryParameters['bookingId'],
        ),
      ),

      // --- Penyewa ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TenantShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tenant',
                builder: (context, state) =>
                    const ExploreScreen(embedded: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tenant/bookings',
                builder: (context, state) =>
                    const MyBookingsScreen(embedded: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tenant/maintenance',
                builder: (context, state) =>
                    const MaintenanceListScreen(embedded: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tenant/profile',
                builder: (context, state) =>
                    const ProfileScreen(embedded: true),
              ),
            ],
          ),
        ],
      ),

      // --- Pemilik ---
      GoRoute(
        path: '/owner/maintenance',
        builder: (context, state) => const OwnerMaintenanceScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            OwnerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner',
                builder: (context, state) => const OwnerDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/properties',
                builder: (context, state) => const OwnerPropertiesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/bookings',
                builder: (context, state) => const OwnerBookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/payments',
                builder: (context, state) => const OwnerPaymentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/profile',
                builder: (context, state) => const ProfileScreen(embedded: true),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/owner/properties/new',
        builder: (context, state) => const PropertyFormScreen(),
      ),
      GoRoute(
        path: '/owner/properties/:id',
        builder: (context, state) => OwnerPropertyDetailScreen(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/owner/properties/:id/edit',
        builder: (context, state) => PropertyFormScreen(
          propertyId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/owner/properties/:id/rooms',
        builder: (context, state) => OwnerRoomsScreen(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/owner/properties/:id/rooms/new',
        builder: (context, state) => RoomFormScreen(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/owner/properties/:id/rooms/:roomId/edit',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'];
          // Data kamar diambil dari state owner yang sudah dimuat daftarnya,
          // sehingga halaman edit tetap bekerja walau dibuka lewat URL.
          final rooms = context.read<OwnerProvider>().rooms;
          RoomItem? room;
          for (final item in rooms) {
            if (item.id == roomId) {
              room = item;
              break;
            }
          }
          return RoomFormScreen(
            propertyId: state.pathParameters['id']!,
            room: room,
          );
        },
      ),

      // --- Admin ---
      GoRoute(
        path: '/admin/properties/:id',
        builder: (context, state) => AdminPropertyDetailScreen(
          propertyId: state.pathParameters['id']!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/properties',
                builder: (context, state) => const AdminPropertiesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                builder: (context, state) => const AdminUsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder: (context, state) => const ProfileScreen(embedded: true),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
