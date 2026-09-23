import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/badge_model.dart';
import '../providers/app_provider.dart';
import '../models/progression.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'animated_star_count.dart';
import 'bouncy_button.dart';
import 'buddy_mascot.dart';

/// The celebration shown when something is won: a level cleared, a badge
/// unlocked, a streak extended, a daily challenge claimed.
///
/// One sheet covers all of them so a reward always looks and sounds the same
/// wherever it comes from — a child learns the shape of "I did well" once.
Future<void> showRewardSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  int stars = 0,
  List<BadgeModel> badges = const [],
  StreakResult? streak,
  BuddyVariant buddy = BuddyVariant.buddy,
  BuddyHat hat = BuddyHat.none,
  BuddyAccessory accessory = BuddyAccessory.none,
  String? buttonLabel,
}) {
  final t = context.read<AppProvider>().t;
  SoundService.instance.win();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => _RewardSheet(
      title: title,
      subtitle: subtitle,
      stars: stars,
      badges: badges,
      streak: streak,
      buddy: buddy,
      hat: hat,
      accessory: accessory,
      buttonLabel: buttonLabel ?? t('Nice!', 'Hebat!'),
    ),
    transitionBuilder: (_, anim, _, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(curve), child: child),
      );
    },
  );
}

class _RewardSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final int stars;
  final List<BadgeModel> badges;
  final StreakResult? streak;
  final BuddyVariant buddy;
  final BuddyHat hat;
  final BuddyAccessory accessory;
  final String buttonLabel;

  const _RewardSheet({
    required this.title,
    required this.subtitle,
    required this.stars,
    required this.badges,
    required this.streak,
    required this.buddy,
    required this.hat,
    required this.accessory,
    required this.buttonLabel,
  });

  @override
  State<_RewardSheet> createState() => _RewardSheetState();
}

class _RewardSheetState extends State<_RewardSheet> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BuddyMascot(
                    size: 104,
                    variant: widget.buddy,
                    hat: widget.hat,
                    accessory: widget.accessory,
                    animation: BuddyAnim.cheer,
                    mood: BuddyMood.excited,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  if (widget.streak != null) ...[
                    const SizedBox(height: 16),
                    _StreakBanner(streak: widget.streak!),
                  ],
                  if (widget.stars > 0) ...[
                    const SizedBox(height: 18),
                    _StarPill(stars: widget.stars),
                  ],
                  if (widget.badges.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _BadgeStrip(badges: widget.badges),
                  ],
                  const SizedBox(height: 22),
                  BouncyButton(
                    onTap: () {
                      SoundService.instance.tap();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        widget.buttonLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 24,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [
              AppColors.primary,
              AppColors.punchTeal,
              AppColors.punchPink,
              AppColors.punchViolet,
              AppColors.punchLime,
            ],
          ),
        ),
      ],
    );
  }
}

class _StarPill extends StatelessWidget {
  final int stars;
  const _StarPill({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.primaryDeep, size: 26),
          const SizedBox(width: 6),
          const Text(
            '+',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.onPrimary,
            ),
          ),
          AnimatedStarCount(
            value: stars,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final StreakResult streak;
  const _StreakBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppProvider>().t;
    final rescued = streak.freezeUsed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: rescued ? const Color(0xFFEAF4FF) : const Color(0xFFFFF1E3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            rescued ? '🛡️ ${streak.current}' : '🔥 ${streak.current}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            rescued
                ? t('A freeze saved your streak!',
                    'Perisai selamatkan streak kau!')
                : (streak.isPersonalBest
                    ? t('Your best streak ever!', 'Rekod terbaik kau!')
                    : t('days in a row!', 'hari berturut-turut!')),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  final List<BadgeModel> badges;
  const _BadgeStrip({required this.badges});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return Column(
      children: [
        Text(
          provider.t('NEW BADGE', 'LENCANA BAHARU'),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final badge in badges)
              Container(
                width: 92,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Column(
                  children: [
                    Text(badge.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 4),
                    Text(
                      provider.t(badge.name, badge.nameMs),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
