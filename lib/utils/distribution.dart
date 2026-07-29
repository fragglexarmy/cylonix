// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../services/ipn.dart';

/// Installer package name Android reports for apps installed from Google
/// Play.
const _playStoreInstaller = 'com.android.vending';

/// Human-readable install/distribution variant, e.g. for the About tile.
/// Returns null on platforms with a single distribution channel (or, on
/// Android, until [info] is available).
String? appDistributionLabel(PackageInfo? info) {
  if (Platform.isMacOS) {
    return IpnService.isDirectDistribution
        ? 'Direct Install (PKG)'
        : 'App Store (Network Extension)';
  }
  if (Platform.isAndroid && info != null) {
    return info.installerStore == _playStoreInstaller
        ? 'Google Play'
        : 'Direct APK Install';
  }
  return null;
}

/// Value reported to the daemon for `Hostinfo.App` so the control server
/// and machine details can show which app build a node runs. Format:
/// `cylonix-app/<version>+<build>` — keep stable, the admin console
/// parses it.
String appHostinfoValue(PackageInfo info) {
  final build = info.buildNumber.isEmpty ? '0' : info.buildNumber;
  return 'cylonix-app/${info.version}+$build';
}

/// Display form of a node's `Hostinfo.App` value: strips the
/// `cylonix-app/` prefix, passes anything else (e.g. tsnet app names)
/// through unchanged.
String hostinfoAppLabel(String app) {
  const prefix = 'cylonix-app/';
  return app.startsWith(prefix) ? app.substring(prefix.length) : app;
}

/// Friendly label for the `Hostinfo.Package` value a node reports.
///
/// Values seen from Cylonix clients:
/// - Android (AppSourceChecker): "googleplay", "fdroid", "amazon",
///   "unknown" (null installer = sideload/adb), or
///   "unknown(<installer package>)" for e.g. the manual APK installer.
/// - iOS and the macOS Network Extension app: "appstore" (hardcoded in
///   wireguard-apple's CylonixAppCtx).
/// - macOS direct PKG: "cylonixd" (darwin hostinfo falls back to the
///   daemon executable's name).
/// - Linux/Windows daemons: usually empty.
String hostinfoPackageLabel(String package) {
  switch (package) {
    case 'googleplay':
      return 'Google Play';
    case 'appstore':
      return 'App Store';
    case 'fdroid':
      return 'F-Droid';
    case 'amazon':
      return 'Amazon Appstore';
    case 'cylonixd':
      return 'Direct Install (PKG)';
    case 'unknown':
      return 'Direct APK Install';
  }
  final match = RegExp(r'^unknown\((.+)\)$').firstMatch(package);
  if (match != null) {
    return 'Direct APK Install (${match.group(1)})';
  }
  return package;
}

/// One-line build description for the uploaded logs so support can tell
/// from a log what the user is running: version, distribution variant,
/// and (on Android) the raw installer package name.
String appVersionLogLine(PackageInfo info) {
  final buffer = StringBuffer(
    'App version ${info.version} (build ${info.buildNumber})',
  );
  final variant = appDistributionLabel(info);
  if (variant != null) {
    buffer.write(' · $variant');
  }
  if (Platform.isAndroid) {
    buffer.write(' · installer=${info.installerStore ?? 'none'}');
  }
  return buffer.toString();
}
