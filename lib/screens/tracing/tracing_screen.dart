import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/buddy_mascot.dart';
import '../../widgets/page_theme.dart';
import 'tracing_canvas_screen.dart';

class TracingScreen extends StatefulWidget {
  const TracingScreen({super.key});

  @override
  State<TracingScreen> createState() => _TracingScreenState();
}

class _TracingScreenState extends State<TracingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];
  static const numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: PagePalette.tracing.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BuddyMascot(size: 38, variant: PagePalette.tracing.buddy, animation: PagePalette.tracing.anim),
            const SizedBox(width: 8),
            // Same guard as the other mascot titles: a longer string or a
            // narrower phone would otherwise overflow the app bar.
            const Flexible(
              child: Text('Writing Practice', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Letters A-Z'),
            Tab(text: 'Numbers 0-9'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrid(letters),
          _buildGrid(numbers),
        ],
      ),
    );
  }

  Widget _buildGrid(List<String> chars) {
    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: chars.length,
        itemBuilder: (context, index) {
          final gradientIndex = index % AppColors.gradients.length;
          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 4,
            duration: const Duration(milliseconds: 350),
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: BouncyButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TracingCanvasScreen(
                          character: chars[index],
                          allCharacters: chars,
                          currentIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.gradients[gradientIndex],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gradients[gradientIndex][0]
                              .withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        chars[index],
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
