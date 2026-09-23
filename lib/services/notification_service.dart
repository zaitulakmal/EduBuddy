import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// One gentle daily reminder, off until a parent turns it on.
///
/// Deliberately minimal for a children's app: a single notification at a time
/// the parent picks, no streak-loss warnings, no "you are falling behind", and
/// nothing that nags a child into opening the app. Google Play's Families
/// policy is strict about pressuring children, and a reminder aimed at the
/// household is both allowed and the kind that actually works.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _kEnabled = 'reminder_enabled';
  static const _kHour = 'reminder_hour';
  static const _kMinute = 'reminder_minute';

  /// Default time: late afternoon, when homework usually happens.
  static const defaultHour = 17;
  static const defaultMinute = 30;

  static const _dailyId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// True once the platform plugin has been set up. Everything below is a
  /// no-op until then, so a device without notification support (or a test)
  /// never breaks the app.
  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    try {
      tz.initializeTimeZones();
      // Nothing is requested at launch on any platform: permission is asked
      // for only when a parent actually turns the reminder on.
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        // The project also builds for macOS, and the plugin throws rather than
        // degrading when the platform it is running on has no settings.
        macOS: darwin,
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  Future<(int, int)> reminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getInt(_kHour) ?? defaultHour,
      prefs.getInt(_kMinute) ?? defaultMinute,
    );
  }

  /// Asks the OS for permission. Returns false when it was refused or is
  /// unavailable, so the caller can leave the toggle off rather than showing
  /// it on while nothing would ever arrive.
  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
      }
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macos != null) {
        return await macos.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
      }
      return false;
    } catch (e) {
      debugPrint('Notification permission failed: $e');
      return false;
    }
  }

  /// Turns the daily reminder on or off and stores the choice.
  /// Returns whether it ended up on.
  Future<bool> setEnabled(bool enabled, {int? hour, int? minute}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!enabled) {
      await prefs.setBool(_kEnabled, false);
      await _cancel();
      return false;
    }

    final granted = await requestPermission();
    if (!granted) {
      await prefs.setBool(_kEnabled, false);
      return false;
    }

    final (storedHour, storedMinute) = await reminderTime();
    final h = hour ?? storedHour;
    final m = minute ?? storedMinute;

    await prefs.setBool(_kEnabled, true);
    await prefs.setInt(_kHour, h);
    await prefs.setInt(_kMinute, m);
    await _schedule(h, m);
    return true;
  }

  /// Re-applies the stored schedule. Called at startup because Android drops
  /// scheduled alarms when the device restarts.
  Future<void> refresh() async {
    await init();
    if (!_ready) return;
    if (!await isEnabled()) return;
    final (hour, minute) = await reminderTime();
    await _schedule(hour, minute);
  }

  Future<void> _cancel() async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancel(_dailyId);
    } catch (e) {
      debugPrint('Cancelling reminder failed: $e');
    }
  }

  Future<void> _schedule(int hour, int minute) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancel(_dailyId);
      // Read the language straight from storage: the reminder is scheduled
      // outside any widget, so there is no provider to ask.
      final prefs = await SharedPreferences.getInstance();
      final ms = (prefs.getString('app_language') ?? 'en') == 'ms';
      await _plugin.zonedSchedule(
        _dailyId,
        ms ? 'Buddy tunggu kau! 🦉' : 'Buddy is waiting! 🦉',
        ms
            ? 'Nak belajar sekejap hari ini?'
            : 'A few minutes of learning today?',
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily reminder',
            channelDescription: 'One gentle reminder a day, set by a parent.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        // Inexact on purpose: an exact alarm needs a special permission that
        // Play scrutinises, and a reminder does not need to land on the second.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Scheduling reminder failed: $e');
    }
  }

  /// The next occurrence of [hour]:[minute] in local time — today if it has not
  /// passed yet, otherwise tomorrow.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }
}
