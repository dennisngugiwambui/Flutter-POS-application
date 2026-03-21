import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

/// Simple in-app notification list (placeholder until backend feed exists).
Future<void> showNotificationsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Color(0x180A2018), blurRadius: 24, offset: Offset(0, -4))],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: const [
                  _NotifTile(
                    icon: Icons.inventory_2_rounded,
                    iconBg: Color(0xFFE8F5E9),
                    iconColor: Color(0xFF1B8B5A),
                    title: 'Low stock reminder',
                    body: 'Review items below minimum in Inventory when you open Products.',
                    time: 'Today',
                  ),
                  SizedBox(height: 10),
                  _NotifTile(
                    icon: Icons.receipt_long_rounded,
                    iconBg: Color(0xFFE3F2FD),
                    iconColor: Color(0xFF1565C0),
                    title: 'Sales activity',
                    body: 'Completed sales appear under Profile → Sales History.',
                    time: 'Tips',
                  ),
                  SizedBox(height: 10),
                  _NotifTile(
                    icon: Icons.notifications_active_rounded,
                    iconBg: Color(0xFFFFF3E0),
                    iconColor: Color(0xFFE65100),
                    title: 'Push alerts',
                    body: 'Connect Supabase Realtime or FCM later to show live store alerts here.',
                    time: 'Coming soon',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String body;
  final String time;

  const _NotifTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 0.9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
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
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText),
                      ),
                    ),
                    Text(time, style: const TextStyle(fontSize: 11, color: kTextMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12, color: kTextSub, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
