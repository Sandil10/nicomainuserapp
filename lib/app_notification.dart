import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

/// Types of notifications you can show
enum NotificationType { success, error, warning, info }

/// Show an in-app notification (top of screen)
void showAppNotification({
  required String title,
  required String message,
  NotificationType type = NotificationType.info,
}) {
  late Color background;
  late IconData icon;

  // Choose color + icon based on notification type
  switch (type) {
    case NotificationType.success:
      background = Color(0xFF4A22A8);
      icon = Icons.check_circle;
      break;
    case NotificationType.error:
      background = Colors.red;
      icon = Icons.error;
      break;
    case NotificationType.warning:
      background = Color(0xFF4A22A8);
      icon = Icons.warning;
      break;
    case NotificationType.info:
    default:
      background = Color(0xFF4A22A8);
      icon = Icons.info;
  }

  // Show notification at the top
  showSimpleNotification(
    Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    background: background,
    autoDismiss: true,
    duration: const Duration(seconds: 3),
    slideDismiss: true,
  );
}
