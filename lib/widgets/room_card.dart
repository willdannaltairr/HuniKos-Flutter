import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/property.dart';
import 'price_text.dart';
import 'status_chip.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.trailing,
    this.showStatus = true,
  });

  final RoomItem room;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showStatus;

  static String statusLabel(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'Tersedia';
      case 'RESERVED':
        return 'Dipesan';
      case 'OCCUPIED':
        return 'Terisi';
      case 'MAINTENANCE':
        return 'Perbaikan';
      case 'INACTIVE':
        return 'Nonaktif';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.blueTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.meeting_room_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Kamar ${room.roomNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        if (showStatus)
                          StatusChip(
                            compact: true,
                            status: room.status,
                            label: statusLabel(room.status),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${room.roomType} • Lantai ${room.floorNumber} • '
                      '${room.maxOccupants} orang • ${room.bathroomLabel}'
                      '${room.dimensions == null ? '' : ' • ${room.dimensions}'}',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    if (room.facilities.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        room.facilities.map((facility) => facility.name).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 6),
                    PriceText(
                      amount: room.monthlyPrice,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 8),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
