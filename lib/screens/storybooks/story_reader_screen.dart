import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../models/story_library.dart';
import '../../models/story_sounds.dart';
import '../../models/storybook_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/buddy_mascot.dart';
import '../../widgets/reward_overlay.dart';
import '../../widgets/story_scene.dart';
import '../../services/sound_service.dart';

class StoryReaderScreen extends StatefulWidget {
  final StorybookModel book;
  final AppProvider provider;

  const StoryReaderScreen({
    super.key,
    required this.book,
    required this.provider,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  List<StorybookPage> _pages = [];
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    final pages =
        await widget.provider.loadStorybookPages(widget.book.id!);
    if (!mounted) return;
    setState(() => _pages = pages);
    _syncAmbient();
  }

  /// Library books play a looping scene sound that follows the page.
  void _syncAmbient() {
    final seed = storySeedFor(widget.book.storyKey);
    if (seed == null || seed.pages.isEmpty) return;
    final shot = seed.pages[_currentPage.clamp(0, seed.pages.length - 1)].shot;
    SoundService.instance.playAmbient(storyAmbientFor(shot), rain: shot.rain);
  }

  @override
  void dispose() {
    if (widget.book.storyKey != null) SoundService.instance.stopAmbient();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      if (mounted) {
        setState(() => _currentPage++);
      }
    } else if (!_finished) {
      setState(() => _finished = true);
      _recordRead();
      _showCompletionDialog();
    }
  }

  /// Records the finished book, then celebrates any badge it earned. The
  /// completion dialog is its own celebration, so only a badge interrupts it.
  Future<void> _recordRead() async {
    final provider = widget.provider;
    try {
      await provider.markStorybookRead(widget.book.id!);
    } catch (_) {
      return;
    }
    final badges = List.of(provider.newlyEarnedBadges);
    if (!mounted || badges.isEmpty) return;
    await showRewardSheet(
      context,
      title: provider.t('New badge!', 'Lencana baharu!'),
      badges: badges,
      buddy: buddyVariantFromId(provider.userAvatar),
      hat: provider.buddyHat,
      accessory: provider.buddyAccessory,
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      if (mounted) {
        setState(() => _currentPage--);
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration_rounded, color: AppColors.primary, size: 64),
              const SizedBox(height: 12),
              const Text(
                'Story Complete!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You earned 2 stars!\nWell done, little reader!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Back to Stories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
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

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  BouncyButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.book.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${_currentPage + 1}/${_pages.length}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  _syncAmbient();
                },
                itemCount: _pages.length,
                itemBuilder: (_, i) => _StoryPage(
                  page: _pages[i],
                  storybookId: widget.book.id!,
                  storyKey: widget.book.storyKey,
                ),
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SmoothPageIndicator(
                controller: _pageCtrl,
                count: _pages.length,
                effect: WormEffect(
                  dotColor: Colors.white30,
                  activeDotColor: AppColors.primary,
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: BouncyButton(
                        onTap: _previousPage,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              '← Previous',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentPage > 0 ? 1 : 1,
                    child: BouncyButton(
                      onTap: _nextPage,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFFFF9F43)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Finish!'
                                : 'Next →',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  final StorybookPage page;
  final int storybookId;
  final String? storyKey;

  const _StoryPage({required this.page, required this.storybookId, this.storyKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Custom illustrated background
            Positioned.fill(
              child: StorySceneWidget(
                storybookId: storybookId,
                pageNumber: page.pageNumber,
                storyKey: storyKey,
              ),
            ),
            // Story text overlay at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Text(
                  page.text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
