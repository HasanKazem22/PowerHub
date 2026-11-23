import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// This phone's model, e.g. "Samsung SM-A546E", saved with each backup so a new phone can show where it came
/// from. The model, never the device's own name (that is often the owner's name).
Future<String> currentDeviceName() async {
  if (kIsWeb) return 'Web browser';
  final info = DeviceInfoPlugin();
  try {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final a = await info.androidInfo;
        final brand = a.manufacturer.isEmpty ? '' : '${a.manufacturer[0].toUpperCase()}${a.manufacturer.substring(1)} ';
        return _limit('$brand${a.model}');
      case TargetPlatform.iOS:
        return _limit((await info.iosInfo).model);
      default:
        return defaultTargetPlatform.name;
    }
  } catch (_) {
    return 'Phone';
  }
}

String _limit(String s) => s.length <= 60 ? s : s.substring(0, 60);
