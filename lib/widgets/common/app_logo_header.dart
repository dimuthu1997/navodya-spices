import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppLogoHeader extends StatelessWidget {
  final double size;
  final bool showSubtitle;

  const AppLogoHeader({super.key, this.size = 44.0, this.showSubtitle = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.dry_cleaning,
              size: size * 0.7,
              color: AppTheme.royalGoldPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NAVODYA SPICES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.1,
                color: isDark ? Colors.white : AppTheme.textDark,
              ),
            ),
            if (showSubtitle)
              const Text(
                'නාවෝද්‍යා කුළුබඩු',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.royalGoldPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
