import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys used for list sharing / household pairing.
const sharePrefDeviceLink = 'device_link';
const sharePrefDeviceId = 'device_id';
const sharePrefCloudHousehold = 'cloud_household';
const sharePrefLastWifiSync = 'last_wifi_sync';
const sharePrefLastCloudSync = 'last_cloud_sync';
const sharePrefWifiShareOff = 'wifi_share_explicit_off';

/// Durable copy of pairing next to the SQLite file so an Android update that
/// drops or migrates SharedPreferences still keeps the household code.
const shareCredentialsFileName = 'shopped_share.json';

/// Household pairing and Wi-Fi share flags that must survive app updates.
class ShareCredentials {
  const ShareCredentials({
    this.cloudCode,
    this.sharing = false,
    this.wifiShareOff = false,
    this.deviceId,
    this.lastWifiSync,
    this.lastCloudSync,
  });

  final String? cloudCode;
  final bool sharing;
  final bool wifiShareOff;
  final String? deviceId;
  final DateTime? lastWifiSync;
  final DateTime? lastCloudSync;

  bool get hasHousehold => cloudCode != null && cloudCode!.trim().isNotEmpty;

  Map<String, Object?> toJson() => {
    'cloudCode': cloudCode,
    'sharing': sharing,
    'wifiShareOff': wifiShareOff,
    'deviceId': deviceId,
    'lastWifiSync': lastWifiSync?.toUtc().toIso8601String(),
    'lastCloudSync': lastCloudSync?.toUtc().toIso8601String(),
  };

  static ShareCredentials fromJson(Map<String, Object?> json) {
    DateTime? parse(Object? raw) =>
        raw is String ? DateTime.tryParse(raw) : null;
    final code = json['cloudCode'];
    final deviceId = json['deviceId'];
    return ShareCredentials(
      cloudCode: code is String && code.trim().isNotEmpty ? code : null,
      sharing: json['sharing'] == true,
      wifiShareOff: json['wifiShareOff'] == true,
      deviceId: deviceId is String && deviceId.isNotEmpty ? deviceId : null,
      lastWifiSync: parse(json['lastWifiSync']),
      lastCloudSync: parse(json['lastCloudSync']),
    );
  }

  /// Prefers a real household code from either side; OR-merges sharing flags.
  ShareCredentials merge(ShareCredentials other) {
    final code = hasHousehold
        ? cloudCode
        : (other.hasHousehold ? other.cloudCode : null);
    final sharingOn = sharing || other.sharing;
    return ShareCredentials(
      cloudCode: code,
      sharing: sharingOn,
      // Keep an explicit Wi-Fi off only when sharing is not saved as on.
      wifiShareOff: sharingOn ? false : (wifiShareOff || other.wifiShareOff),
      deviceId: (deviceId != null && deviceId!.isNotEmpty)
          ? deviceId
          : other.deviceId,
      lastWifiSync: _later(lastWifiSync, other.lastWifiSync),
      lastCloudSync: _later(lastCloudSync, other.lastCloudSync),
    );
  }
}

DateTime? _later(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isAfter(b) ? a : b;
}

/// Reads and writes [ShareCredentials] to SharedPreferences and a local file.
class ShareCredentialsStore {
  ShareCredentialsStore({
    SharedPreferences? prefs,
    File? file,
    Future<Directory> Function()? supportDirectory,
  }) : _prefsOverride = prefs,
       _fileOverride = file,
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final SharedPreferences? _prefsOverride;
  final File? _fileOverride;
  SharedPreferences? _prefs;
  File? _file;
  final Future<Directory> Function() _supportDirectory;

  Future<SharedPreferences> _prefsInstance() async {
    final existing = _prefs ?? _prefsOverride;
    if (existing != null) return existing;
    return _prefs = await SharedPreferences.getInstance();
  }

  Future<File> _fileInstance() async {
    final existing = _file ?? _fileOverride;
    if (existing != null) return existing;
    final dir = await _supportDirectory();
    return _file = File(p.join(dir.path, shareCredentialsFileName));
  }

  /// Loads prefs and the durable file, then merges them.
  Future<ShareCredentials> load() async {
    final fromPrefs = await _loadPrefs();
    final fromFile = await _loadFile();
    final merged = fromPrefs.merge(fromFile);
    // Heal a missing side so the next update still finds the code.
    if (merged.hasHousehold || merged.sharing || merged.deviceId != null) {
      await save(merged);
    }
    return merged;
  }

  Future<void> save(ShareCredentials credentials) async {
    await _savePrefs(credentials);
    await _saveFile(credentials);
  }

  Future<ShareCredentials> _loadPrefs() async {
    try {
      final prefs = await _prefsInstance();
      final raw = prefs.getString(sharePrefDeviceLink);
      var sharing = false;
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          sharing = decoded is Map && decoded['sharing'] == true;
        } on FormatException {
          sharing = false;
        }
      }
      return ShareCredentials(
        cloudCode: prefs.getString(sharePrefCloudHousehold),
        sharing: sharing,
        wifiShareOff: prefs.getBool(sharePrefWifiShareOff) ?? false,
        deviceId: prefs.getString(sharePrefDeviceId),
        lastWifiSync: DateTime.tryParse(
          prefs.getString(sharePrefLastWifiSync) ?? '',
        ),
        lastCloudSync: DateTime.tryParse(
          prefs.getString(sharePrefLastCloudSync) ?? '',
        ),
      );
    } on Object {
      return const ShareCredentials();
    }
  }

  Future<ShareCredentials> _loadFile() async {
    try {
      final file = await _fileInstance();
      if (!await file.exists()) return const ShareCredentials();
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const ShareCredentials();
      return ShareCredentials.fromJson(Map<String, Object?>.from(decoded));
    } on Object {
      return const ShareCredentials();
    }
  }

  Future<void> _savePrefs(ShareCredentials credentials) async {
    try {
      final prefs = await _prefsInstance();
      if (credentials.sharing) {
        await prefs.setString(
          sharePrefDeviceLink,
          jsonEncode({'sharing': true}),
        );
      } else {
        await prefs.remove(sharePrefDeviceLink);
      }
      final code = credentials.cloudCode?.trim();
      if (code != null && code.isNotEmpty) {
        await prefs.setString(sharePrefCloudHousehold, code);
      } else {
        await prefs.remove(sharePrefCloudHousehold);
      }
      if (credentials.wifiShareOff) {
        await prefs.setBool(sharePrefWifiShareOff, true);
      } else {
        await prefs.remove(sharePrefWifiShareOff);
      }
      final deviceId = credentials.deviceId;
      if (deviceId != null && deviceId.isNotEmpty) {
        await prefs.setString(sharePrefDeviceId, deviceId);
      }
      final wifiAt = credentials.lastWifiSync;
      if (wifiAt != null) {
        await prefs.setString(
          sharePrefLastWifiSync,
          wifiAt.toUtc().toIso8601String(),
        );
      }
      final cloudAt = credentials.lastCloudSync;
      if (cloudAt != null) {
        await prefs.setString(
          sharePrefLastCloudSync,
          cloudAt.toUtc().toIso8601String(),
        );
      }
    } on Object {
      // File copy may still hold the pairing for the next launch.
    }
  }

  Future<void> _saveFile(ShareCredentials credentials) async {
    try {
      final file = await _fileInstance();
      if (!credentials.hasHousehold &&
          !credentials.sharing &&
          (credentials.deviceId == null || credentials.deviceId!.isEmpty)) {
        if (await file.exists()) await file.delete();
        return;
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(credentials.toJson()));
    } on Object {
      // Prefs may still hold the pairing for the next launch.
    }
  }
}
