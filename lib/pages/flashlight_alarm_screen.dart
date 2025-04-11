import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmModel {
  final TimeOfDay time;
  final String label;
  final List<int> repeatDays;
  final int id;

  AlarmModel(this.time, this.label, this.repeatDays, this.id);
}

class FlashlightAlarmScreen extends StatefulWidget {
  const FlashlightAlarmScreen({super.key});

  @override
  State<FlashlightAlarmScreen> createState() => _FlashlightAlarmScreenState();
}

class _FlashlightAlarmScreenState extends State<FlashlightAlarmScreen> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<AlarmModel> _alarms = [];
  bool _alarmGoingOff = false;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initNotifications();
    _listenToNotifications();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _startFlashlightAndVibration(); // Fallback trigger
      },
    );
  }

  void _listenToNotifications() {
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestPermission();
  }

  Future<void> _startFlashlightAndVibration() async {
    if (_alarmGoingOff) return;
    setState(() => _alarmGoingOff = true);

    try {
      for (int i = 0; i < 8 && _alarmGoingOff; i++) {
        try {
          await TorchLight.enableTorch();
          await Future.delayed(const Duration(milliseconds: 300));
          await TorchLight.disableTorch();
        } catch (_) {}

        try {
          bool? hasVibrator = await Vibration.hasVibrator();
          if (hasVibrator == true) {
            Vibration.vibrate(duration: 500);
          }
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 600));
      }
    } catch (_) {}

    setState(() => _alarmGoingOff = false);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final labelController = TextEditingController();
      final selectedDays = List<bool>.filled(7, false);

      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Alarm Details"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: "Label"),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      const dayNames = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      return FilterChip(
                        label: Text(dayNames[i]),
                        selected: selectedDays[i],
                        onSelected: (val) {
                          setState(() => selectedDays[i] = val);
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Save"),
                ),
              ],
            ),
      );

      final label =
          labelController.text.trim().isEmpty
              ? "Alarm at ${picked.format(context)}"
              : labelController.text.trim();

      final repeatDays = <int>[];
      for (int i = 0; i < 7; i++) {
        if (selectedDays[i]) repeatDays.add(i + 1);
      }

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final alarm = AlarmModel(picked, label, repeatDays, id);
      setState(() => _alarms.add(alarm));
      _scheduleAlarm(alarm);
    }
  }

  Future<void> _scheduleAlarm(AlarmModel alarm) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      fullScreenIntent: true,
      enableLights: true,
      visibility: NotificationVisibility.public,
    );

    await _notificationsPlugin.zonedSchedule(
      alarm.id,
      alarm.label,
      '',
      tzTime,
      const NotificationDetails(android: androidDetails),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          alarm.repeatDays.isNotEmpty
              ? DateTimeComponents.dayOfWeekAndTime
              : null,
      payload: 'alarm${alarm.id}',
    );

    _showMessage("Alarm set for ${alarm.time.format(context)}");

    Future.delayed(tzTime.difference(DateTime.now()), () {
      if (mounted) _startFlashlightAndVibration();
    });
  }

  void _deleteAlarm(int index) {
    final id = _alarms[index].id;
    setState(() => _alarms.removeAt(index));
    _notificationsPlugin.cancel(id);
  }

  void _stopAlarm() {
    setState(() => _alarmGoingOff = false);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flashlight Alarm')),
      body: Column(
        children: [
          if (_alarmGoingOff)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.all(10),
              child: ElevatedButton.icon(
                onPressed: _stopAlarm,
                icon: const Icon(Icons.stop),
                label: const Text("Stop Alarm"),
              ),
            ),
          Expanded(
            child:
                _alarms.isEmpty
                    ? const Center(child: Text("No alarms set"))
                    : ListView.builder(
                      itemCount: _alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = _alarms[index];
                        final days =
                            alarm.repeatDays.isNotEmpty
                                ? "(${alarm.repeatDays.map((d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1]).join(', ')})"
                                : "";
                        return ListTile(
                          leading: const Icon(Icons.alarm),
                          title: Text("${alarm.label} $days"),
                          subtitle: Text("Time: ${alarm.time.format(context)}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteAlarm(index),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickTime(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
