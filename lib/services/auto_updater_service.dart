import 'dart:io';
import 'package:auto_updater/auto_updater.dart';
import 'package:flutter/foundation.dart';

class AutoUpdaterService {
  AutoUpdaterService._();
  static final AutoUpdaterService instance = AutoUpdaterService._();

  static const String _appcastUrl =
      'https://github.com/tushal-pethani/lakhaan/releases/latest/download/appcast.xml';

  static const String currentVersion = '1.1.9';

  Future<void> initialize() async {
    if (!Platform.isMacOS && !Platform.isWindows) return;

    try {
      await autoUpdater.setFeedURL(_appcastUrl);
      debugPrint('[AutoUpdater] Feed URL set: $_appcastUrl');

      autoUpdater.addListener(_UpdaterListener());

      debugPrint('[AutoUpdater] Initialized successfully');
    } catch (e) {
      debugPrint('[AutoUpdater] Initialization failed: $e');
    }
  }

  Future<void> checkForUpdates() async {
    if (!Platform.isMacOS && !Platform.isWindows) return;
    try {
      await autoUpdater.checkForUpdates();
    } catch (e) {
      debugPrint('[AutoUpdater] Check failed: $e');
    }
  }
}

class _UpdaterListener extends UpdaterListener {
  @override
  void onUpdaterError(UpdaterError? error) {
    debugPrint('[AutoUpdater] Error: ${error?.message}');
  }

  @override
  void onUpdaterCheckingForUpdate(Appcast? appcast) {
    debugPrint('[AutoUpdater] Checking for update...');
  }

  @override
  void onUpdaterUpdateAvailable(AppcastItem? appcastItem) {
    debugPrint('[AutoUpdater] Update available: ${appcastItem?.versionString}');
  }

  @override
  void onUpdaterUpdateNotAvailable(UpdaterError? error) {
    debugPrint('[AutoUpdater] No update available');
  }

  @override
  void onUpdaterUpdateDownloaded(AppcastItem? appcastItem) {
    debugPrint(
      '[AutoUpdater] Update downloaded: ${appcastItem?.versionString}',
    );
  }

  @override
  void onUpdaterBeforeQuitForUpdate(AppcastItem? appcastItem) {
    debugPrint(
      '[AutoUpdater] Before quit for update: ${appcastItem?.versionString}',
    );
  }
}
