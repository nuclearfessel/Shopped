import 'cloud_mailbox.dart';

/// Prefix so a grocery barcode is never treated as a sync code.
const syncQrPrefix = 'shopped:';

/// Older QR codes from when the app was named ShopIt.
const legacySyncQrPrefix = 'shopit:';

/// Text stored in the QR code the computer shows.
String syncQrPayload(String code) =>
    '$syncQrPrefix${code.trim().toLowerCase()}';

/// Household code inside a scan, or null when it is not a Shopped sync code.
String? householdFromQr(String raw) {
  final text = raw.trim();
  final lower = text.toLowerCase();
  final String body;
  if (lower.startsWith(syncQrPrefix)) {
    body = text.substring(syncQrPrefix.length);
  } else if (lower.startsWith(legacySyncQrPrefix)) {
    body = text.substring(legacySyncQrPrefix.length);
  } else {
    body = text;
  }
  final code = body.trim().toLowerCase();
  return isHouseholdCode(code) ? code : null;
}
