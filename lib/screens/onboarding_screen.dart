import 'package:clear_scan/screens/scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clear_scan/l10n/app_localizations.dart' as loc;

import '../theme/app_theme.dart';

// The illustrations draw a white "paper" in both themes, so everything that
// sits on the paper uses fixed colors instead of theme-aware ones.
const _paperInk = Color(0xFF12303A);
const _paperPrimary = Color(0xFF14909A);
const _paperLine = Color(0xFFC9D4D9);

// Hero card stays dark navy in both themes.
const _heroBackground = Color(0xFF0F2A33);

/// First-launch onboarding. Shown once, then [ScannerScreen] takes over.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const _seenKey = 'onboarding_seen';

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _index = 0;

  List<_SlideData> _localizedSlides(BuildContext context) {
    final l = loc.AppLocalizations.of(context)!;
    return [
      _SlideData(
        kind: _SlideKind.scan,
        title: l.onboardingSlideScanTitle,
        subtitle: l.onboardingSlideScanSubtitle,
      ),
      _SlideData(
        kind: _SlideKind.organize,
        title: l.onboardingSlideOrganizeTitle,
        subtitle: l.onboardingSlideOrganizeSubtitle,
      ),
      _SlideData(
        kind: _SlideKind.sign,
        title: l.onboardingSlideSignTitle,
        subtitle: l.onboardingSlideSignSubtitle,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingPage.markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    final buttonForeground = isDark ? const Color(0xFF0B1E26) : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      loc.AppLocalizations.of(context)!.onboardingSkip,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textMuted(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _localizedSlides(context).length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) =>
                        _Slide(data: _localizedSlides(context)[i]),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_localizedSlides(context).length, (
                    i,
                  ) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary(context)
                            : AppColors.textHint(context)
                                  .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: buttonForeground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(
                      loc.AppLocalizations.of(context)!.onboardingGetStarted,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  loc.AppLocalizations.of(context)!.onboardingAgreeTerms,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint(context),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _SlideKind { scan, organize, sign }

class _SlideData {
  const _SlideData({
    required this.kind,
    required this.title,
    required this.subtitle,
  });

  final _SlideKind kind;
  final String title;
  final String subtitle;
}

class _Slide extends StatelessWidget {
  const _Slide({required this.data});

  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: _heroBackground,
                  borderRadius: BorderRadius.circular(28),
                  border: isDark
                      ? Border.all(color: AppColors.border(context))
                      : null,
                ),
                child: switch (data.kind) {
                  _SlideKind.scan => const _ScanIllustration(),
                  _SlideKind.organize => const _OrganizeIllustration(),
                  _SlideKind.sign => const _SignIllustration(),
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.ink(context),
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted(context),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Page 1: a document inside scan brackets with an animated scan line.
class _ScanIllustration extends StatefulWidget {
  const _ScanIllustration();

  @override
  State<_ScanIllustration> createState() => _ScanIllustrationState();
}

class _ScanIllustrationState extends State<_ScanIllustration>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF2CC4CF);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final pw = w * 0.45;
        final ph = h * 0.67;
        final paperRect = Rect.fromCenter(
          center: Offset(w / 2, h / 2),
          width: pw,
          height: ph,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BracketsPainter(paperRect.inflate(w * 0.05), _accent),
              ),
            ),
            Positioned.fromRect(
              rect: paperRect,
              child: Container(
                padding: EdgeInsets.all(pw * 0.12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const _PaperLines(),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final top = paperRect.top + (ph - 6) * _controller.value;
                return Positioned(
                  left: paperRect.left - 6,
                  top: top,
                  width: pw + 12,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.55),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _PaperLines extends StatelessWidget {
  const _PaperLines();

  @override
  Widget build(BuildContext context) {
    Widget line(double factor, {Color color = _paperLine, double height = 5}) {
      return FractionallySizedBox(
        widthFactor: factor,
        alignment: Alignment.centerLeft,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(0.5, color: _paperInk, height: 7),
        const SizedBox(height: 16),
        for (var i = 0; i < 7; i++) ...[
          line(i % 3 == 0 ? 0.7 : 1),
          const SizedBox(height: 13),
        ],
      ],
    );
  }
}

class _BracketsPainter extends CustomPainter {
  _BracketsPainter(this.rect, this.color);

  final Rect rect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const len = 28.0;

    Path corner(Offset c, double dx, double dy) => Path()
      ..moveTo(c.dx, c.dy + len * dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(c.dx + len * dx, c.dy);

    canvas.drawPath(corner(rect.topLeft, 1, 1), paint);
    canvas.drawPath(corner(rect.topRight, -1, 1), paint);
    canvas.drawPath(corner(rect.bottomLeft, 1, -1), paint);
    canvas.drawPath(corner(rect.bottomRight, -1, -1), paint);
  }

  @override
  bool shouldRepaint(covariant _BracketsPainter old) =>
      old.rect != rect || old.color != color;
}

/// Page 2: three folder tiles.
class _OrganizeIllustration extends StatelessWidget {
  const _OrganizeIllustration();

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String label) {
      return Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: _paperPrimary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _paperInk,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile(
            Icons.badge_outlined,
            loc.AppLocalizations.of(context)!.onboardingTileIdCards,
          ),
          const SizedBox(width: 12),
          tile(
            Icons.folder_outlined,
            loc.AppLocalizations.of(context)!.onboardingTileContracts,
          ),
          const SizedBox(width: 12),
          tile(
            Icons.receipt_long_outlined,
            loc.AppLocalizations.of(context)!.onboardingTileReceipts,
          ),
        ],
      ),
    );
  }
}

/// Page 3: a document with a signature.
class _SignIllustration extends StatelessWidget {
  const _SignIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final pw = box.maxWidth * 0.5;
        final ph = box.maxHeight * 0.67;
        return Center(
          child: Container(
            width: pw,
            height: ph,
            padding: EdgeInsets.all(pw * 0.12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: _PaperLines()),
                SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: CustomPaint(painter: _SignaturePainter()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.8)
      ..cubicTo(w * 0.1, h * 0.0, w * 0.2, h * 0.1, w * 0.25, h * 0.6)
      ..cubicTo(w * 0.3, h * 1.0, w * 0.4, h * 0.1, w * 0.5, h * 0.4)
      ..cubicTo(w * 0.6, h * 0.8, w * 0.7, h * 0.2, w * 0.85, h * 0.5);

    canvas.drawPath(
      path,
      Paint()
        ..color = _paperInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(0, h - 1),
      Offset(w, h - 1),
      Paint()
        ..color = const Color(0xFF9AA8B0)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
