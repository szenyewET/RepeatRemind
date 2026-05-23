import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Validates store submission assets and configuration exist and are correct.
// These are infrastructure tests — they verify files on disk, not runtime behaviour.

final _root = Directory.current.path.endsWith('test')
    ? Directory.current.parent.path
    : Directory.current.path;

void main() {
  // ── Cycle 1: privacy policy ──────────────────────────────────────────────

  group('privacy policy', () {
    late String content;

    setUpAll(() {
      final file = File('$_root/docs/privacy/index.html');
      expect(file.existsSync(), isTrue,
          reason: 'docs/privacy/index.html must exist for GitHub Pages');
      content = file.readAsStringSync();
    });

    test('states data is stored locally only', () {
      expect(content,
          contains('RepeatRemind stores all data locally on your device'));
    });

    test('states no personal data is collected', () {
      expect(content, contains('No personal data is collected'));
    });

    test('states no account required', () {
      expect(content, contains('No account'));
    });
  });

  // ── Cycle 2: Android key.properties.template ─────────────────────────────

  group('Android signing template', () {
    late String content;

    setUpAll(() {
      final file = File('$_root/android/key.properties.template');
      expect(file.existsSync(), isTrue,
          reason: 'android/key.properties.template must exist');
      content = file.readAsStringSync();
    });

    test('has storePassword key', () {
      expect(content, contains('storePassword='));
    });

    test('has keyPassword key', () {
      expect(content, contains('keyPassword='));
    });

    test('has keyAlias key', () {
      expect(content, contains('keyAlias='));
    });

    test('has storeFile key', () {
      expect(content, contains('storeFile='));
    });
  });

  // ── Cycle 3: build.gradle.kts signing config ─────────────────────────────

  group('Android build.gradle.kts signing config', () {
    late String content;

    setUpAll(() {
      final file = File('$_root/android/app/build.gradle.kts');
      expect(file.existsSync(), isTrue);
      content = file.readAsStringSync();
    });

    test('reads key.properties file', () {
      expect(content, contains('key.properties'));
    });

    test('defines release signingConfig', () {
      expect(content, contains('signingConfigs'));
    });

    test('release build uses release signingConfig not debug', () {
      // Should not use debug signing for release
      final releaseBlock = RegExp(
        r'release\s*\{[^}]*signingConfig[^}]*\}',
        dotAll: true,
      ).firstMatch(content);
      expect(releaseBlock, isNotNull);
      expect(releaseBlock!.group(0), isNot(contains('"debug"')));
    });
  });

  // ── Cycle 4: iOS iPhone-only ──────────────────────────────────────────────

  group('iOS project configuration', () {
    late String content;

    setUpAll(() {
      final file =
          File('$_root/ios/Runner.xcodeproj/project.pbxproj');
      expect(file.existsSync(), isTrue);
      content = file.readAsStringSync();
    });

    test('deployment target is 16', () {
      expect(content, contains('IPHONEOS_DEPLOYMENT_TARGET = 16'));
    });

    test('targets iPhone only (no iPad)', () {
      // "1,2" includes iPad; "1" is iPhone only
      expect(content, isNot(contains('TARGETED_DEVICE_FAMILY = "1,2"')));
      expect(content, contains('TARGETED_DEVICE_FAMILY = "1"'));
    });
  });
}
