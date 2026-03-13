import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Holds info about an available update.
class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    this.releaseNotes = '',
  });
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// The version baked into the app at compile time.
  /// Must match the version in pubspec.yaml.
  static const String currentVersion = '1.1.0';

  /// Compares [a] and [b] as semver strings.
  /// Returns true if [b] is newer than [a].
  static bool _isNewer(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).toList();
    final bParts = b.split('.').map(int.tryParse).toList();
    for (int i = 0; i < 3; i++) {
      final av = (i < aParts.length ? aParts[i] : 0) ?? 0;
      final bv = (i < bParts.length ? bParts[i] : 0) ?? 0;
      if (bv > av) return true;
      if (bv < av) return false;
    }
    return false; // equal
  }

  /// Checks Firestore `app_config/latest_version` for a newer version.
  /// Returns [UpdateInfo] if an update is available, or null.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('latest_version')
          .get()
          .timeout(const Duration(seconds: 8));

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      final latestVersion = data['version'] as String? ?? '';
      final downloadUrl = data['downloadUrl'] as String? ?? '';
      final releaseNotes = data['releaseNotes'] as String? ?? '';

      if (latestVersion.isEmpty || downloadUrl.isEmpty) return null;

      if (_isNewer(currentVersion, latestVersion)) {
        return UpdateInfo(
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null; // Don't block the app if the check fails
    }
  }
}
