import 'dart:async';
import 'package:flutter/foundation.dart';

/// Central hook for interstitial ads shown at natural break points
/// (level complete, retry, quitting to the level map).
///
/// The game code already calls [maybeShowInterstitial] at every sensible
/// break. Right now it only throttles + logs — no real ad is shown. To turn
/// on real ads later:
///
///   1. Add `google_mobile_ads` to pubspec.yaml and run `flutter pub get`.
///   2. Add your AdMob App ID to android/app/src/main/AndroidManifest.xml
///      and ios/Runner/Info.plist.
///   3. Call [MobileAds.instance.initialize()] in main().
///   4. Load an InterstitialAd into [_interstitial] (see _loadInterstitial
///      sketch below) and uncomment the show() lines.
///
/// IMPORTANT for a kids' app like EduBuddy: Google Play's Families policy
/// requires a Google-certified, child-friendly ad SDK and that ads be tagged
/// child-directed (`tagForChildDirectedTreatment`). Avoid ads that interrupt
/// active gameplay or appear at app launch for under-13 audiences. Keeping
/// interstitials to *between* levels (as wired here) is the safe pattern.
class AdHelper {
  AdHelper._();

  /// How many break points must pass between interstitials. Family apps get
  /// flagged for showing ads too often, so keep this conservative.
  static const int frequency = 3;

  static int _breaks = 0;

  /// Returns true if an ad was (or would be) shown. Awaitable so callers can
  /// pause navigation until the ad is dismissed.
  static Future<bool> maybeShowInterstitial() async {
    _breaks++;
    if (_breaks % frequency != 0) return false;

    // TODO(ads): show the loaded interstitial, then preload the next one:
    //   if (_interstitial != null) {
    //     await _interstitial!.show();
    //     _interstitial = null;
    //     _loadInterstitial();
    //     return true;
    //   }
    if (kDebugMode) {
      debugPrint('[Ads] interstitial break #$_breaks — wire AdMob here.');
    }
    return false;
  }

  /// Reset the throttle counter (e.g. when the user leaves the game section).
  static void reset() => _breaks = 0;
}
