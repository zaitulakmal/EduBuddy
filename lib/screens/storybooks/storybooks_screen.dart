import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/storybook_model.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/page_theme.dart';
import 'story_reader_screen.dart';

class StorybooksScreen extends StatelessWidget {
  const StorybooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              _buildGrid(context, provider),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return SliverToBoxAdapter(
      child: FunkyHeader(
        palette: PagePalette.storybooks,
        title: provider.t('Storybooks', 'Buku Cerita'),
        subtitle: provider.t('Dive into amazing stories!', 'Selami cerita yang menakjubkan!'),
        onBack: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, AppProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: AnimationLimiter(
        child: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final book = provider.storybooks[i];
              return AnimationConfiguration.staggeredGrid(
                position: i,
                columnCount: 2,
                duration: const Duration(milliseconds: 400),
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _BookCard(
                      book: book,
                      index: i,
                      onTap: () => _openBook(context, provider, book),
                    ),
                  ),
                ),
              );
            },
            childCount: provider.storybooks.length,
          ),
        ),
      ),
    );
  }

  void _openBook(
      BuildContext context, AppProvider provider, StorybookModel book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryReaderScreen(book: book, provider: provider),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final StorybookModel book;
  final int index;
  final VoidCallback onTap;

  const _BookCard({
    required this.book,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.gradients[index % AppColors.gradients.length];

    return BouncyButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.auto_stories_rounded,
                        color: Colors.white, size: 64),
                  ),
                  if (book.isRead)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 2),
                            Text(
                              'Read',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Book spine effect
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.description_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${book.pageCount} pages',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
