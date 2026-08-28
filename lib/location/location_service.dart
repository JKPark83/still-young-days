import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPS lookup, kept behind an interface so tests can supply a fake instead
/// of the real `geolocator` plugin.
abstract interface class LocationService {
  /// Returns the current coarse position, or null when permission is
  /// refused (once or forever), the service is off, or the fetch fails or
  /// times out. Never opens the system settings app — that's too much for a
  /// first run.
  Future<Position?> current();
}

/// Real implementation backed by `package:geolocator`.
class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<Position?> current() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } on Object catch (error) {
      debugPrint('DeviceLocationService: failed to get position — $error');
      return null;
    }
  }
}
