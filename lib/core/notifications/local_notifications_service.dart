import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService instance =
      LocalNotificationsService._();

  static const dailyReminderNotificationId = 1001;
  static const budgetLimitNotificationId = 1002;
  static const pushEnabledTestNotificationId = 1003;

  static const _channelId = 'mycashplanner_reminders';
  static const _channelName = 'Напоминания MyCashPlanner';
  static const _channelDescription =
      'Напоминания о внесении расходов и лимитах бюджета';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // If timezone lookup fails, keep default timezone.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _isInitialized = true;
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<bool> ensurePermissionsGranted() async {
    if (!_isInitialized) {
      await initialize();
    }

    var androidGranted = true;
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final enabled = await androidImpl.areNotificationsEnabled() ?? true;
      if (!enabled) {
        await androidImpl.requestNotificationsPermission();
        androidGranted = await androidImpl.areNotificationsEnabled() ?? false;
      }
    }

    var iosGranted = true;
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      iosGranted = granted ?? true;
    }

    return androidGranted && iosGranted;
  }

  Future<bool> syncDailyExpenseReminder({required bool enabled}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!enabled) {
      await _plugin.cancel(dailyReminderNotificationId);
      return false;
    }

    final granted = await ensurePermissionsGranted();
    if (!granted) {
      await _plugin.cancel(dailyReminderNotificationId);
      return false;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      dailyReminderNotificationId,
      'Не забудьте внести расходы',
      'Сегодня были траты? Добавьте их в MyCashPlanner до конца дня.',
      scheduled,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    return true;
  }

  Future<bool> showPushEnabledTest() async {
    if (!_isInitialized) {
      await initialize();
    }

    final granted = await ensurePermissionsGranted();
    if (!granted) return false;

    await _plugin.show(
      pushEnabledTestNotificationId,
      'Уведомления включены',
      'MyCashPlanner будет присылать напоминания и уведомления о лимите.',
      _notificationDetails(),
    );

    return true;
  }

  Future<void> showBudgetLimitReached({
    required double total,
    required double limit,
    required DateTime month,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final granted = await ensurePermissionsGranted();
    if (!granted) return;

    await _plugin.show(
      budgetLimitNotificationId,
      'Превышен лимит бюджета',
      'Расходы за ${_formatMonthYear(month)}: ${total.toStringAsFixed(0)} ₸ '
          '(лимит ${limit.toStringAsFixed(0)} ₸).',
      _notificationDetails(),
    );
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'январь',
      'февраль',
      'март',
      'апрель',
      'май',
      'июнь',
      'июль',
      'август',
      'сентябрь',
      'октябрь',
      'ноябрь',
      'декабрь',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
