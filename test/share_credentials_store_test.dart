import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopped/services/share_credentials_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late File file;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('shopped-share-');
    file = File('${temp.path}/$shareCredentialsFileName');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  ShareCredentialsStore store() => ShareCredentialsStore(
    file: file,
    supportDirectory: () async => temp,
  );

  test('save writes prefs and the durable file', () async {
    final s = store();
    await s.save(
      const ShareCredentials(
        cloudCode: 'abcd1234.abcdefghijabcdefghij',
        sharing: true,
        deviceId: 'device-1',
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(sharePrefCloudHousehold), 'abcd1234.abcdefghijabcdefghij');
    expect(prefs.getString(sharePrefDeviceLink), contains('"sharing":true'));
    expect(prefs.getString(sharePrefDeviceId), 'device-1');

    final disk = jsonDecode(await file.readAsString()) as Map;
    expect(disk['cloudCode'], 'abcd1234.abcdefghijabcdefghij');
    expect(disk['sharing'], isTrue);
  });

  test('load recovers the household from the file when prefs were wiped', () async {
    await file.writeAsString(
      jsonEncode(
        const ShareCredentials(
          cloudCode: 'abcd1234.abcdefghijabcdefghij',
          sharing: true,
        ).toJson(),
      ),
    );
    SharedPreferences.setMockInitialValues({});

    final loaded = await store().load();
    expect(loaded.cloudCode, 'abcd1234.abcdefghijabcdefghij');
    expect(loaded.sharing, isTrue);

    // Heal prefs so the next launch still finds the code there too.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(sharePrefCloudHousehold), 'abcd1234.abcdefghijabcdefghij');
  });

  test('load recovers from prefs when the durable file is missing', () async {
    SharedPreferences.setMockInitialValues({
      sharePrefCloudHousehold: 'abcd1234.abcdefghijabcdefghij',
      sharePrefDeviceLink: jsonEncode({'sharing': true}),
    });

    final loaded = await store().load();
    expect(loaded.cloudCode, 'abcd1234.abcdefghijabcdefghij');
    expect(loaded.sharing, isTrue);
    expect(await file.exists(), isTrue);
  });

  test('merge prefers a household code from either side', () {
    const a = ShareCredentials(cloudCode: 'abcd1234.abcdefghijabcdefghij');
    const b = ShareCredentials(sharing: true);
    final merged = a.merge(b);
    expect(merged.cloudCode, 'abcd1234.abcdefghijabcdefghij');
    expect(merged.sharing, isTrue);
  });
}
