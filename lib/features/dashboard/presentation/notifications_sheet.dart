import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/app_theme.dart';
import '../../../dashboard_provider.dart';
import '../data/broadcast_repository.dart';

/// Opens notifications: in-app broadcasts + compose (role-based).
Future<void> showNotificationsSheet(BuildContext context, WidgetRef _) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _NotificationsSheetBody(),
  );
}

class _NotificationsSheetBody extends ConsumerStatefulWidget {
  const _NotificationsSheetBody();

  @override
  ConsumerState<_NotificationsSheetBody> createState() => _NotificationsSheetBodyState();
}

class _NotificationsSheetBodyState extends ConsumerState<_NotificationsSheetBody> {
  List<InboxItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ref.read(broadcastRepositoryProvider).fetchInbox();
      if (mounted) setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      try {
        final fallback = await ref.read(broadcastRepositoryProvider).fetchRecent();
        if (mounted) {
          setState(() {
            _items = fallback.map(InboxItem.fromBroadcast).toList();
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  String _roleLabel(WidgetRef ref) {
    return ref.watch(profileProvider).maybeWhen(
          data: (p) => p?.role.toLowerCase() ?? '',
          orElse: () => '',
        );
  }

  bool _canSend(String r) {
    return r == 'admin' || r == 'manager' || r == 'client';
  }

  Future<void> _openComposer() async {
    final r = _roleLabel(ref);
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final selected = <String>{};

    final opts = <MapEntry<String, List<String>>>[];
    if (r == 'admin') {
      opts.addAll([
        const MapEntry('Everyone', ['all']),
        const MapEntry('Admins', ['admin']),
        const MapEntry('Managers', ['manager']),
        const MapEntry('Cashiers', ['cashier']),
        const MapEntry('Clients', ['client']),
      ]);
    } else if (r == 'manager') {
      opts.addAll([
        const MapEntry('Managers', ['manager']),
        const MapEntry('Cashiers', ['cashier']),
        const MapEntry('Clients', ['client']),
      ]);
    } else if (r == 'client') {
      opts.addAll([
        const MapEntry('Admin', ['admin']),
        const MapEntry('Managers', ['manager']),
      ]);
    }

    await showDialog<void>(
      context: context,
      builder: (dCtx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            List<String> mergeTargets() {
              if (selected.isEmpty) return ['all'];
              final roles = <String>{};
              for (final e in opts) {
                if (selected.contains(e.key)) roles.addAll(e.value);
              }
              if (roles.contains('all')) return ['all'];
              return roles.toList();
            }

            return AlertDialog(
              title: const Text('Send notification'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Send to:', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in opts)
                          FilterChip(
                            label: Text(e.key),
                            selected: selected.contains(e.key),
                            onSelected: (v) {
                              setLocal(() {
                                if (v) {
                                  selected.add(e.key);
                                } else {
                                  selected.remove(e.key);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    final t = titleCtrl.text.trim();
                    final b = bodyCtrl.text.trim();
                    if (t.isEmpty || b.isEmpty) return;
                    final targets = mergeTargets();
                    try {
                      await ref.read(broadcastRepositoryProvider).send(
                            title: t,
                            body: b,
                            targetRoles: targets,
                          );
                      if (dCtx.mounted) Navigator.pop(dCtx);
                      if (mounted) {
                        await _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notification sent'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    } catch (e) {
                      if (dCtx.mounted) {
                        ScaffoldMessenger.of(dCtx).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = _roleLabel(ref);
    final df = DateFormat('MMM d, HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: cs.shadow.withAlpha(30), blurRadius: 24, offset: const Offset(0, -4))],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withAlpha(120),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface),
                  ),
                  const Spacer(),
                  if (_canSend(r))
                    TextButton.icon(
                      onPressed: _openComposer,
                      icon: const Icon(Icons.campaign_rounded, size: 20),
                      label: const Text('Send'),
                    ),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: cs.primary))
                  : _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No announcements yet. ${_canSend(r) ? 'Tap Send to broadcast to your team.' : ''}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final entry = _items[i];
                            if (entry.isPersonal) {
                              final n = entry.personal!;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: cs.surfaceContainerHighest.withAlpha(90),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.person_pin_rounded, color: cs.primary, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  color: cs.onSurface,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              df.format(n.createdAt),
                                              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          n.body,
                                          style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.35),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Only you',
                                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            final n = entry.broadcast!;
                            final aud = n.targetRoles.contains('all')
                                ? 'Everyone'
                                : n.targetRoles.join(', ');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: cs.surfaceContainerHighest.withAlpha(90),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.campaign_rounded, color: kPrimary, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              n.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            df.format(n.createdAt),
                                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        n.body,
                                        style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.35),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'To: $aud',
                                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
