import '../core/json_utils.dart';

class OwnerDashboard {
  const OwnerDashboard({
    required this.totalProperties,
    required this.approvedProperties,
    required this.totalRooms,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.pendingBookings,
    required this.pendingPayments,
    required this.openMaintenance,
    required this.revenueThisMonth,
    required this.occupancyRate,
    this.grossRentalThisMonth = 0,
    this.platformFeeThisMonth = 0,
    this.netPayoutThisMonth = 0,
  });

  final int totalProperties;
  final int approvedProperties;
  final int totalRooms;
  final int availableRooms;
  final int occupiedRooms;
  final int pendingBookings;
  final int pendingPayments;
  final int openMaintenance;
  final double revenueThisMonth;
  final double occupancyRate;
  final double grossRentalThisMonth;
  final double platformFeeThisMonth;
  final double netPayoutThisMonth;

  factory OwnerDashboard.fromJson(Map<String, dynamic> json) {
    return OwnerDashboard(
      totalProperties: asInt(json['total_properties']) ?? 0,
      approvedProperties: asInt(json['approved_properties']) ?? 0,
      totalRooms: asInt(json['total_rooms']) ?? 0,
      availableRooms: asInt(json['available_rooms']) ?? 0,
      occupiedRooms: asInt(json['occupied_rooms']) ?? 0,
      pendingBookings: asInt(json['pending_bookings']) ?? 0,
      pendingPayments: asInt(json['pending_payments']) ?? 0,
      openMaintenance: asInt(json['open_maintenance']) ?? 0,
      revenueThisMonth: asDouble(json['revenue_this_month']) ?? 0,
      occupancyRate: asDouble(json['occupancy_rate']) ?? 0,
      grossRentalThisMonth: asDouble(json['gross_rental_this_month']) ?? 0,
      platformFeeThisMonth: asDouble(json['platform_fee_this_month']) ?? 0,
      netPayoutThisMonth: asDouble(json['net_payout_this_month']) ?? 0,
    );
  }
}

class AdminDashboard {
  const AdminDashboard({
    required this.totalUsers,
    required this.totalTenants,
    required this.totalOwners,
    required this.totalProperties,
    required this.pendingProperties,
    required this.activeBookings,
    this.platformGrossRevenue = 0,
  });

  final int totalUsers;
  final int totalTenants;
  final int totalOwners;
  final int totalProperties;
  final int pendingProperties;
  final int activeBookings;
  final double platformGrossRevenue;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      totalUsers: asInt(json['total_users']) ?? 0,
      totalTenants: asInt(json['total_tenants']) ?? 0,
      totalOwners: asInt(json['total_owners']) ?? 0,
      totalProperties: asInt(json['total_properties']) ?? 0,
      pendingProperties: asInt(json['pending_properties']) ?? 0,
      activeBookings: asInt(json['active_bookings']) ?? 0,
      platformGrossRevenue: asDouble(json['platform_gross_revenue']) ?? 0,
    );
  }
}
