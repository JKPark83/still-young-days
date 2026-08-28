import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the dialer. Returns false when the OS could not handle `tel:`.
/// `Uri(scheme:'tel', path:)` keeps hyphens intact; `canLaunchUrl` is
/// deliberately not used (see url_launcher README).
typedef PhoneLauncher = Future<bool> Function(String phone);

Future<bool> launchPhoneCall(String phone) async {
  debugPrint('metric:call_tap'); // P3 replaces with real instrumentation
  final uri = Uri(scheme: 'tel', path: phone);
  try {
    return await launchUrl(uri);
  } on Object {
    return false;
  }
}
