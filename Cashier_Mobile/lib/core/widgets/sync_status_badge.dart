import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SyncStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const SyncStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'synced':
        bg = AppColors.synced.withOpacity(0.15);
        fg = AppColors.synced;
        label = "تمت المزامنة";
        icon = Icons.check_circle_rounded;
        break;
      case 'syncfailed':
      case 'failed':
        bg = AppColors.syncFailed.withOpacity(0.15);
        fg = AppColors.syncFailed;
        label = "فشلت المزامنة";
        icon = Icons.error_rounded;
        break;
      case 'pendingsync':
      case 'pending':
      default:
        bg = AppColors.pendingSync.withOpacity(0.15);
        fg = AppColors.pendingSync;
        label = "قيد المزامنة";
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
