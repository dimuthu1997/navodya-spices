import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../theme/app_theme.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _hasPermission = false;

  void requestPermission() {
    try {
      web.Notification.requestPermission();
      _hasPermission = true;
    } catch (e) {
      debugPrint("Notification permission note: $e");
    }
  }

  void showPushNotification({required String title, required String body}) {
    try {
      if (_hasPermission) {
        web.Notification(title, web.NotificationOptions(body: body, icon: 'assets/images/logo.png'));
      }
    } catch (e) {
      debugPrint("Native notification note: $e");
    }
  }

  static void showInAppAlert(BuildContext context, {required String title, required String message, required IconData icon, Color color = AppTheme.royalGoldPrimary}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  Text(message, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
