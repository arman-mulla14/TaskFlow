import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _prefEnabled = 'notifications_enabled';
  static const String _prefHour = 'notification_hour';
  static const String _prefMinute = 'notification_minute';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabled) ?? true;
  }

  Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_prefHour) ?? 9;
    final minute = prefs.getInt(_prefMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> saveSettings({required bool enabled, required TimeOfDay time}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, enabled);
    await prefs.setInt(_prefHour, time.hour);
    await prefs.setInt(_prefMinute, time.minute);
  }
}
