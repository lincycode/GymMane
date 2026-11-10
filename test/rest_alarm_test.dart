import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/services/rest_alarm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;
  late bool platformSaysEnabled;

  setUp(() {
    calls = [];
    platformSaysEnabled = true;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'areNotificationsEnabled':
          return platformSaysEnabled;
        case 'requestNotificationsPermission':
          return platformSaysEnabled;
        case 'initialize':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  List<String> methods() => calls.map((c) => c.method).toList();

  Map<String, dynamic> scheduleArgs() =>
      (calls.firstWhere((c) => c.method == 'zonedSchedule').arguments as Map).cast<String, dynamic>();

  Future<void> ready() async {
    await RestAlarm.instance.init();
    calls.clear();
  }

  DateTime deadline() => DateTime.now().add(const Duration(seconds: 90));

  test('init reaches the platform', () async {
    await RestAlarm.instance.init();
    expect(methods(), contains('initialize'));
  });

  test('scheduling actually reaches the platform', () async {
    await ready();
    await RestAlarm.instance.schedule(deadline());
    expect(methods(), contains('zonedSchedule'),
        reason: 'si esto falta, para Android el aviso no existe');
  });

  test('it schedules even when the platform claims notifications are off', () async {
    await ready();
    platformSaysEnabled = false;
    await RestAlarm.instance.schedule(deadline());
    expect(methods(), contains('zonedSchedule'),
        reason: 'no nos negamos la alarma a nosotros mismos');
  });

  test('the permission is asked once, not on every set', () async {
    await ready();
    await RestAlarm.instance.schedule(deadline());
    await RestAlarm.instance.schedule(deadline());
    await RestAlarm.instance.schedule(deadline());
    expect(methods().where((m) => m == 'requestNotificationsPermission').length, lessThanOrEqualTo(1));
  });

  test('it uses alarmClock — the mode Doze and MIUI cannot defer', () async {
    await ready();
    await RestAlarm.instance.schedule(deadline());
    final specifics = (scheduleArgs()['platformSpecifics'] as Map).cast<String, dynamic>();
    expect(specifics['scheduleMode'], 'alarmClock');
  });

  test('the notification is scheduled for the countdown deadline', () async {
    await ready();
    final end = deadline();
    await RestAlarm.instance.schedule(end);

    final when = DateTime.parse(scheduleArgs()['scheduledDateTimeISO8601'] as String);
    expect(when.difference(end).inMilliseconds.abs(), lessThan(1000));
  });

  for (final (style, sound, fullScreen) in [
    ('loud', true, true),
    ('quiet', true, false),
    ('silent', false, false),
  ]) {
    test('$style keeps the rest notification without vibration', () async {
      await ready();
      RestAlarm.instance.style = style;
      addTearDown(() => RestAlarm.instance.style = 'quiet');
      await RestAlarm.instance.schedule(deadline());
      final specifics = (scheduleArgs()['platformSpecifics'] as Map).cast<String, dynamic>();
      expect(specifics['importance'], Importance.max.value);
      expect(specifics['playSound'], sound);
      expect(specifics['enableVibration'], false);
      expect(specifics['fullScreenIntent'], fullScreen);
      expect(specifics['channelId'], 'rest_end_$style');
    });
  }

  test('cancel reaches the platform', () async {
    await ready();
    await RestAlarm.instance.cancel();
    expect(methods(), contains('cancel'));
  });

  test('skipping the rest wins the race against a pending schedule', () async {
    await ready();
    final pending = RestAlarm.instance.schedule(deadline());
    await RestAlarm.instance.cancel();
    await pending;

    final scheduledAfterCancel = calls
        .skipWhile((c) => c.method != 'cancel')
        .any((c) => c.method == 'zonedSchedule');
    expect(scheduledAfterCancel, false);
  });
}
