import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/buddy_mascot.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'main_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5)),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(_textCtrl);

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textCtrl.forward();

    await context.read<AppProvider>().loadAll();
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const MainNav(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    // Kept within the screen width on purpose. Sizing him wider and letting
    // the side edges crop him gets the layer clipped part-way across his face,
    // so he is cropped by the bottom edge only.
    final markSize = width * 0.95;

    return Scaffold(
      // Exactly the native launch window colour (and Android's
      // splash_background), so the hand-off is invisible rather than a visible
      // change of screen.
      backgroundColor: const Color(0xFFFFC93C),
      body: Stack(
        // Without this the Stack has loose constraints and shrink-wraps to its
        // only non-positioned child - the text column - which clipped every
        // Positioned child at the width of the word "EduBuddy".
        fit: StackFit.expand,
        children: [
          // Pushed past the bottom edge so the screen crops him the way the
          // reference crops its characters by the card edge.
          Positioned(
            left: (width - markSize) / 2,
            width: markSize,
            height: markSize,
            bottom: -markSize * 0.26,
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: BuddyMascot(
                  size: markSize,
                  // BuddyAnim.wave is what actually swings the arm; the widget's
                  // `waving` flag is declared but never read.
                  animation: BuddyAnim.wave,
                  // bodyColor/cheekColor are only honoured by the default
                  // BuddyVariant.buddy; the other variants carry fixed colours.
                  bodyColor: const Color(0xFFE8453C),
                  cheekColor: const Color(0xFFFFB3AD),
                  // The default antenna ball is the same yellow as this
                  // background, which made it vanish.
                  antennaColor: const Color(0xFF23348C),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(32, height * 0.16, 32, 0),
              child: SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EduBuddy',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          // Dark, not white: white on this yellow is barely
                          // legible.
                          color: AppColors.textDark,
                          letterSpacing: -1.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Learning is fun!',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Small and quiet: the splash is brief, but a slow
                      // loadAll() should still show something is happening.
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textDark.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
