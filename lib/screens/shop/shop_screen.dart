import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/progression.dart';
import '../../models/shop_catalog.dart';
import '../../providers/app_provider.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/buddy_mascot.dart';
import '../../widgets/header_back_button.dart';

/// Where stars go.
///
/// Before this, `total_stars` was a number that only ever went up and bought
/// nothing, so it stopped meaning anything after the first week. Everything
/// here is cosmetic — no story, quiz or activity is ever behind a price, so a
/// child who never spends a star still reaches all the learning content.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: provider.themeSkin.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(provider: provider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _Section(
                    title: provider.t('Buddies', 'Kawan Buddy'),
                    subtitle: provider.t(
                        'New friends to be', 'Kawan baharu untuk jadi'),
                    items: ShopCatalog.ofKind('buddy'),
                    provider: provider,
                  ),
                  _Section(
                    title: provider.t('Hats', 'Topi'),
                    subtitle: provider.t('Dress up your Buddy',
                        'Hiaskan Buddy kau'),
                    items: ShopCatalog.ofKind('hat'),
                    provider: provider,
                  ),
                  _Section(
                    title: provider.t('Accessories', 'Aksesori'),
                    subtitle: provider.t('Glasses, scarves and more',
                        'Cermin mata, skaf dan lagi'),
                    items: ShopCatalog.ofKind('accessory'),
                    provider: provider,
                  ),
                  _Section(
                    title: provider.t('Colour themes', 'Tema warna'),
                    subtitle:
                        provider.t('Repaint the app', 'Cat semula app ini'),
                    items: ShopCatalog.ofKind('theme'),
                    provider: provider,
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

class _Header extends StatelessWidget {
  final AppProvider provider;
  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
      child: Row(
        children: [
          const HeaderBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.t('Star Shop', 'Kedai Bintang'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.primaryDeep, size: 20),
                const SizedBox(width: 5),
                Text(
                  '${provider.spendableStars}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ShopItem> items;
  final AppProvider provider;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
          children: [
            for (final item in items)
              _ShopCard(item: item, provider: provider),
          ],
        ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  final ShopItem item;
  final AppProvider provider;

  const _ShopCard({required this.item, required this.provider});

  bool get _owned => provider.owns(item.key);

  bool get _equipped {
    switch (item.kind) {
      case 'buddy':
        return provider.userAvatar == item.value;
      case 'hat':
        return buddyHatId(provider.buddyHat) == item.value;
      case 'accessory':
        return buddyAccessoryId(provider.buddyAccessory) == item.value;
      case 'theme':
        return provider.themeSkin.key == item.value;
    }
    return false;
  }

  Future<void> _onTap(BuildContext context) async {
    SoundService.instance.tap();
    if (_owned) {
      await _equip();
      return;
    }
    if (provider.spendableStars < item.cost) {
      final short = item.cost - provider.spendableStars;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            provider.t(
              'You need $short more stars. Keep playing!',
              'Kau perlu $short bintang lagi. Teruskan main!',
            ),
          ),
        ),
      );
      return;
    }
    final bought = await provider.buyItem(item);
    if (!bought) return;
    SoundService.instance.star();
    await _equip();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(provider.t('Unlocked and equipped!',
            'Dibuka dan dipakai!')),
      ),
    );
  }

  Future<void> _equip() async {
    switch (item.kind) {
      case 'buddy':
        await provider.updateProfile(provider.userName, item.value);
      case 'hat':
        await provider.setHat(buddyHatFromId(item.value));
      case 'accessory':
        await provider.setAccessory(buddyAccessoryFromId(item.value));
      case 'theme':
        await provider.setThemeSkin(item.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final affordable = provider.spendableStars >= item.cost;
    return BouncyButton(
      onTap: () => _onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _equipped ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Opacity(
                opacity: _owned ? 1 : 0.55,
                child: _Preview(item: item, provider: provider),
              ),
            ),
            Text(
              provider.t(item.name, item.nameMs),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            _Tag(
              owned: _owned,
              equipped: _equipped,
              cost: item.cost,
              affordable: affordable,
              provider: provider,
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  final ShopItem item;
  final AppProvider provider;
  const _Preview({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    switch (item.kind) {
      case 'buddy':
        return Center(
          child: BuddyMascot(
            size: 62,
            variant: buddyVariantFromId(item.value),
            animation: BuddyAnim.idle,
            waving: false,
          ),
        );
      case 'hat':
        return Center(
          child: BuddyMascot(
            size: 62,
            variant: buddyVariantFromId(provider.userAvatar),
            hat: buddyHatFromId(item.value),
            animation: BuddyAnim.idle,
            waving: false,
          ),
        );
      case 'accessory':
        return Center(
          child: BuddyMascot(
            size: 62,
            variant: buddyVariantFromId(provider.userAvatar),
            accessory: buddyAccessoryFromId(item.value),
            animation: BuddyAnim.idle,
            waving: false,
          ),
        );
      case 'theme':
        final skin = themeSkinFor(item.value);
        return Center(
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: skin.headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        );
    }
    return const SizedBox.shrink();
  }
}

class _Tag extends StatelessWidget {
  final bool owned;
  final bool equipped;
  final int cost;
  final bool affordable;
  final AppProvider provider;

  const _Tag({
    required this.owned,
    required this.equipped,
    required this.cost,
    required this.affordable,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (equipped) {
      return _pill(provider.t('Wearing', 'Dipakai'), AppColors.primary,
          AppColors.onPrimary);
    }
    if (owned) {
      return _pill(provider.t('Wear it', 'Pakai'), AppColors.surfaceAlt,
          AppColors.textDark);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: affordable ? AppColors.primarySoft : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            size: 13,
            color: affordable ? AppColors.primaryDeep : AppColors.textMuted,
          ),
          const SizedBox(width: 2),
          Text(
            '$cost',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: affordable ? AppColors.onPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
      );
}
