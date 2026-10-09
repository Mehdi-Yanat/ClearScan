import 'package:clear_scan/screens/scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';

// Hero card stays dark navy in both themes, so its text/paper use fixed colors.
const _heroBackground = Color(0xFF0F2A33);
const _heroMutedText = Color(0xFFB7CDD2);

/// Text/icon color that stays readable on the primary color in each theme
/// (bright teal in dark mode needs dark text, deep teal in light mode needs white).
Color _onPrimary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF0B1E26)
    : Colors.white;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Replace with real data from your document repository.
  static const _recentDocs = <_RecentDoc>[
    _RecentDoc('Contract Agreement', 'PDF', '2.4 MB', '10:30 AM'),
    _RecentDoc('Passport – John Doe', 'PDF', '1.1 MB', 'Yesterday'),
    _RecentDoc('Invoice #INV-2387', 'PDF', '1.8 MB', '2 days ago'),
    _RecentDoc('Meeting Notes', 'DOCX', '320 KB', '3 days ago'),
  ];

  void _openScanner() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ScannerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: AppColors.surface(context),
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        floatingActionButton: FloatingActionButton(
          heroTag: 'home_add',
          onPressed: () {
            // TODO: open "add" sheet (new folder / import).
          },
          backgroundColor: AppColors.primary(context),
          foregroundColor: _onPrimary(context),
          elevation: 3,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
        appBar: _HomeHeader(),
        bottomNavigationBar: AppBottomBar(
          selectedIndex: 0,
          onScan: _openScanner,
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
            children: [
              const SizedBox(height: 20),
              _HeroCard(onScan: _openScanner),
              const SizedBox(height: 24),
              const _SectionTitle('Quick Actions'),
              const SizedBox(height: 14),
              _QuickActions(onScan: _openScanner),
              const SizedBox(height: 24),
              const _SectionTitle('Recent Documents', actionLabel: 'See all'),
              const SizedBox(height: 14),
              const _RecentDocuments(docs: _recentDocs),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Header ─────────────────────────────

class _HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // NOTE: if this PNG is dark artwork, it will be hard to see in dark
            // mode. Swap in a dark-variant asset here if you have one.
            Image.asset(
              isDark
                  ? 'assets/03_splash_assets/png/wordmark_dark.png'
                  : 'assets/03_splash_assets/png/wordmark_light.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'Clear',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.ink(context),
              ),
            ),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary(context),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                // TODO: notifications
              },
              icon: Icon(
                Icons.notifications_none_rounded,
                size: 26,
                color: AppColors.ink(context),
              ),
              tooltip: 'Notifications',
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Hero ─────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 170,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: _heroBackground,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: AppColors.border(context)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Anything.\nSave Everything.',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fast, smart and secure\ndocument scanning.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: _heroMutedText,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.photo_camera_outlined, size: 17),
                    label: const Text('Scan Now'),
                    style: ElevatedButton.styleFrom(
                      // The hero is dark in both themes, so use the bright
                      // accent here for contrast and dark text on top of it.
                      backgroundColor: const Color(0xFF2CC4CF),
                      foregroundColor: const Color(0xFF0B1E26),
                      elevation: 0,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _HeroPaper(),
        ],
      ),
    );
  }
}

class _HeroPaper extends StatelessWidget {
  const _HeroPaper();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 118,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 5; i++) ...[
            FractionallySizedBox(
              widthFactor: i.isEven ? 0.75 : 1,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFBCC8CE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── Quick actions ─────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final items = <_QuickAction>[
      _QuickAction(Icons.badge_outlined, 'ID Cards', onScan),
      _QuickAction(Icons.menu_book_outlined, 'Passport', onScan),
      _QuickAction(Icons.qr_code_2_rounded, 'QR Code', onScan),
      _QuickAction(Icons.folder_open_outlined, 'Import', () {
        // TODO: file picker import
      }),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 9),
          Expanded(child: _QuickActionTile(action: items[i])),
        ],
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: SizedBox(
          height: 82,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 28, color: AppColors.primary(context)),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: TextStyle(fontSize: 11, color: AppColors.ink(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Recent documents ─────────────────────────────

class _RecentDoc {
  const _RecentDoc(this.name, this.type, this.size, this.when);

  final String name;
  final String type;
  final String size;
  final String when;
}

class _RecentDocuments extends StatelessWidget {
  const _RecentDocuments({required this.docs});

  final List<_RecentDoc> docs;

  @override
  Widget build(BuildContext context) {
    // Material (not Container) so the InkWell ripples on the rows are visible.
    return Material(
      color: AppColors.surface(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < docs.length; i++) ...[
            _DocRow(doc: docs[i]),
            if (i < docs.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 72,
                endIndent: 16,
                color: AppColors.border(context),
              ),
          ],
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.doc});

  final _RecentDoc doc;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: open document viewer
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        child: Row(
          children: [
            const _DocThumb(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${doc.type}  •  ${doc.size}  •  ${doc.when}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.textMuted(context),
              ),
              onSelected: (_) {
                // TODO: share / rename / delete
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: Text('Share')),
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini paper thumbnail. Stays white in both themes (it represents a sheet of
/// paper), so it uses fixed colors.
class _DocThumb extends StatelessWidget {
  const _DocThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 50,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFE6ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFB9C4CA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 5),
          for (var i = 0; i < 4; i++) ...[
            FractionallySizedBox(
              widthFactor: i == 2 ? 0.7 : 1,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DDE1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── Shared bits ─────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink(context),
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.primary(context),
              ),
            ),
          ),
      ],
    );
  }
}
