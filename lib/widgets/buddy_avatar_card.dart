import 'package:flutter/material.dart';

import 'buddy_mascot.dart';

/// One pickable avatar: which Buddy, and the block colour behind it.
///
/// Card and Buddy are deliberately different values of related or contrasting
/// hues so the mascot separates from its card at thumbnail size.
class BuddyAvatarChoice {
  final BuddyVariant variant;
  final Color card;

  const BuddyAvatarChoice(this.variant, this.card);
}

/// Six choices, laid out 3x2. Colours repeat across the set the way a small
/// palette naturally does; the pairing, not the card colour, is what makes each
/// card distinct.
const List<BuddyAvatarChoice> kBuddyAvatarChoices = [
  BuddyAvatarChoice(BuddyVariant.buddy, Color(0xFFFFD24A)),
  BuddyAvatarChoice(BuddyVariant.lumi, Color(0xFFA8D8F0)),
  BuddyAvatarChoice(BuddyVariant.pip, Color(0xFF7EE0A8)),
  BuddyAvatarChoice(BuddyVariant.zuzu, Color(0xFFC77DE8)),
  BuddyAvatarChoice(BuddyVariant.tako, Color(0xFFFFD24A)),
  BuddyAvatarChoice(BuddyVariant.bub, Color(0xFFA8D8F0)),
];

/// A tall block-colour card with the Buddy bleeding off the bottom edge.
class BuddyAvatarCard extends StatelessWidget {
  final BuddyAvatarChoice choice;
  final bool selected;
  final VoidCallback onTap;

  const BuddyAvatarCard({
    super.key,
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.black87 : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                // Inset by the border so the card colour never bleeds past it.
                borderRadius: BorderRadius.circular(17),
                child: ColoredBox(
                  color: choice.card,
                  child: Stack(
                    children: [
                      // Oversized and pushed down, so the clip crops the body
                      // at the bottom edge instead of floating the whole mascot
                      // inside the card.
                      Positioned.fill(
                        child: Transform.translate(
                          offset: Offset(0, w * 0.30),
                          child: Center(
                            child: BuddyMascot(
                              size: w * 1.25,
                              variant: choice.variant,
                              waving: false,
                              animation: BuddyAnim.idle,
                            ),
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
