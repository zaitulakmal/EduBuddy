import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/buddy_avatar_card.dart';
import '../../widgets/buddy_mascot.dart';
import '../../widgets/motion.dart';
import '../../widgets/page_theme.dart';
import '../../services/sound_service.dart';
import '../privacy_policy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildHeader(context, provider),
              _buildStarProgress(context, provider),
              _buildBadges(context, provider),
              _buildStats(context, provider),
              _buildLanguageToggle(context, provider),
              const SliverToBoxAdapter(child: _SoundSettingsCard()),
              _buildPrivacyLink(context, provider),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {

    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -24,
            child: GradientBlob(
              colors: [PagePalette.profile.accentSoft, Colors.white],
              size: 150,
              opacity: 0.25,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: PagePalette.profile.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    BouncyButton(
                      onTap: () => _showAvatarPicker(context, provider),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              // The Buddy the user picked, not the page's own
                              // one, so the avatar picker actually shows up.
                              child: BuddyMascot(
                                size: 76,
                                variant:
                                    buddyVariantFromId(provider.userAvatar),
                                animation: PagePalette.profile.anim,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: AppColors.primary, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _editName(context, provider),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider.userName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_rounded,
                              color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            provider.t('${provider.totalStars} Stars Collected',
                                '${provider.totalStars} Bintang Dikumpul'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarProgress(BuildContext context, AppProvider provider) {
    final total = provider.quizzes.length +
        provider.storybooks.length;
    final done = provider.quizzesCompleted +
        provider.storiesRead;
    final percent = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 54.0,
                lineWidth: 10.0,
                percent: percent,
                center: Text(
                  '${(percent * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                progressColor: AppColors.primary,
                backgroundColor: Colors.grey.shade100,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.t('Overall Progress', 'Kemajuan Keseluruhan'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.t('$done of $total activities done', '$done daripada $total aktiviti selesai'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _progressItem(Icons.psychology_rounded, provider.t('Quizzes', 'Kuiz'), provider.quizzesCompleted,
                        provider.quizzes.length, AppColors.purple),
                    _progressItem(Icons.menu_book_rounded, provider.t('Stories', 'Cerita'), provider.storiesRead,
                        provider.storybooks.length, AppColors.teal),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressItem(
      IconData icon, String label, int done, int total, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label: $done/$total',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(BuildContext context, AppProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.t('Badges', 'Lencana'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.badges.length,
                itemBuilder: (_, i) {
                  final badge = provider.badges[i];
                  return Container(
                    width: 88,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badge.isEarned
                          ? AppColors.secondary.withValues(alpha: 0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: badge.isEarned
                            ? AppColors.secondary
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 38,
                          child: Center(
                            child: badge.isEarned
                                ? Text(
                                    badge.emoji,
                                    style: const TextStyle(fontSize: 30),
                                  )
                                : const Icon(Icons.lock_rounded,
                                    color: Colors.grey, size: 30),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          badge.name,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: badge.isEarned
                                ? AppColors.textDark
                                : AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildStats(BuildContext context, AppProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.t('My Stats', 'Statistik Saya'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatTile(Icons.star_rounded, '${provider.totalStars}', 'Total Stars',
                    AppColors.secondary),
                _StatTile(Icons.psychology_rounded, '${provider.quizzesCompleted}',
                    provider.t('Quizzes Done', 'Kuiz Selesai'), AppColors.purple),
                _StatTile(Icons.menu_book_rounded, '${provider.storiesRead}', provider.t('Stories Read', 'Cerita Dibaca'),
                    AppColors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(BuildContext context, AppProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.language_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.t('Language', 'Bahasa'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      provider.selectedLanguage == 'en' ? 'English' : 'Bahasa Malaysia',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.selectedLanguage == 'ms',
                onChanged: (_) => provider.toggleLanguage(),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyLink(BuildContext context, AppProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: TextButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          child: Text(
            provider.t('Privacy Policy', 'Dasar Privasi'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, AppProvider provider) {
    final selected = buddyVariantFromId(provider.userAvatar);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.t('Select an avatar', 'Pilih avatar anda'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.t(
                'You can change this later',
                'Anda boleh tukar kemudian',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3 / 4,
              children: kBuddyAvatarChoices
                  .map((choice) => BuddyAvatarCard(
                        choice: choice,
                        selected: choice.variant == selected,
                        onTap: () {
                          SoundService.instance.tap();
                          provider.updateProfile(
                            provider.userName,
                            buddyVariantId(choice.variant),
                          );
                          Navigator.pop(sheetContext);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _editName(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController(text: provider.userName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          provider.t('Change Your Name', 'Tukar Nama Anda'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: provider.t('Enter your name...', 'Masukkan nama anda...'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(provider.t('Cancel', 'Batal')),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.updateProfile(ctrl.text.trim(), provider.userAvatar);
              }
              Navigator.pop(context);
            },
            child: Text(provider.t('Save', 'Simpan')),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Sound settings card ──────────────────────────────────────────────────────

class _SoundSettingsCard extends StatefulWidget {
  const _SoundSettingsCard();

  @override
  State<_SoundSettingsCard> createState() => _SoundSettingsCardState();
}

class _SoundSettingsCardState extends State<_SoundSettingsCard> {
  final _sound = SoundService.instance;

  Widget _row({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _row(
              icon: Icons.music_note_rounded,
              title: provider.t('Music', 'Muzik'),
              subtitle: _sound.musicEnabled ? provider.t('On', 'Hidup') : provider.t('Off', 'Mati'),
              value: _sound.musicEnabled,
              onChanged: (v) async {
                await _sound.setMusicEnabled(v);
                if (!mounted) return;
                setState(() {});
              },
            ),
            const Divider(height: 24),
            _row(
              icon: Icons.notifications_rounded,
              title: provider.t('Sound Effects', 'Kesan Bunyi'),
              subtitle: _sound.sfxEnabled ? provider.t('On', 'Hidup') : provider.t('Off', 'Mati'),
              value: _sound.sfxEnabled,
              onChanged: (v) async {
                await _sound.setSfxEnabled(v);
                if (v) _sound.correct();
                if (!mounted) return;
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
