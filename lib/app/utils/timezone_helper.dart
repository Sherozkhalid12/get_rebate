import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// Returns the device's IANA timezone identifier (e.g. "Asia/Karachi", "America/New_York").
/// Never returns UTC offset—always returns an IANA identifier.
Future<String> getTimezoneIdentifier() async {
  try {
    final tz = await FlutterTimezone.getLocalTimezone();
    final id = tz.identifier;
    if (id.isNotEmpty && !id.startsWith('UTC')) {
      return id;
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ FlutterTimezone failed, using offset→IANA map: $e');
    }
  }
  return _getIanaFromOffset();
}

/// Maps UTC offset to IANA identifier (e.g. UTC+5:00 → Asia/Karachi).
/// Used when FlutterTimezone fails (e.g. web).
String _getIanaFromOffset() {
  final offset = DateTime.now().timeZoneOffset;
  final totalMinutes = offset.inMinutes;
  return _offsetToIana[totalMinutes] ?? 'Asia/Karachi';
}

/// Offset in minutes → IANA identifier. Covers common zones.
const _offsetToIana = <int, String>{
  0: 'UTC',
  60: 'Europe/London',   // BST
  120: 'Europe/Paris',
  180: 'Europe/Moscow',
  210: 'Asia/Tehran',
  240: 'Asia/Dubai',
  270: 'Asia/Kabul',
  330: 'Asia/Kolkata',   // UTC+5:30
  345: 'Asia/Kathmandu',
  360: 'Asia/Dhaka',
  420: 'Asia/Bangkok',
  480: 'Asia/Shanghai',
  540: 'Asia/Tokyo',
  570: 'Australia/Adelaide',
  600: 'Australia/Sydney',
  660: 'Pacific/Noumea',
  -300: 'America/New_York',
  -360: 'America/Chicago',
  -420: 'America/Denver',
  -480: 'America/Los_Angeles',
  -60: 'Atlantic/Azores',
  -180: 'America/Sao_Paulo',
  -240: 'America/Caracas',
  300: 'Asia/Karachi',   // UTC+5:00 - Pakistan
};
