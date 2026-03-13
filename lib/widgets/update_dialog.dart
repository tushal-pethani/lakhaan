import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../services/update_service.dart';

/// A mandatory, non-dismissable dialog that downloads and installs updates in-app.
class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  /// Show the mandatory update dialog. Cannot be dismissed.
  static Future<void> show(BuildContext context, UpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(updateInfo: info),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _errorText;

  Future<void> _downloadAndInstall() async {
    setState(() {
      _downloading = true;
      _progress = 0.0;
      _statusText = 'Preparing download...';
      _errorText = null;
    });

    try {
      // 1. Get temp directory for download
      final tempDir = await getTemporaryDirectory();
      final zipPath = '${tempDir.path}\\billings_update.zip';
      final extractDir = '${tempDir.path}\\billings_update';

      // Clean up any previous download
      final zipFile = File(zipPath);
      if (await zipFile.exists()) await zipFile.delete();
      final extractDirObj = Directory(extractDir);
      if (await extractDirObj.exists()) await extractDirObj.delete(recursive: true);

      // 2. Download the zip with progress
      setState(() => _statusText = 'Connecting to server...');

      final request = http.Request('GET', Uri.parse(widget.updateInfo.downloadUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final sink = zipFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          setState(() {
            _progress = receivedBytes / totalBytes;
            final mb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
            final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
            _statusText = 'Downloading... $mb MB / $totalMb MB';
          });
        } else {
          setState(() {
            final mb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
            _statusText = 'Downloading... $mb MB';
          });
        }
      }

      await sink.close();
      setState(() {
        _progress = 1.0;
        _statusText = 'Download complete. Extracting...';
      });

      // 3. Extract the zip using PowerShell
      final extractResult = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        'Expand-Archive -Path "$zipPath" -DestinationPath "$extractDir" -Force',
      ]);

      if (extractResult.exitCode != 0) {
        throw Exception('Extraction failed: ${extractResult.stderr}');
      }

      setState(() => _statusText = 'Installing update...');

      // 4. Get the current app directory
      final appDir = File(Platform.resolvedExecutable).parent.path;
      final appExe = Platform.resolvedExecutable;

      // 5. Build a PowerShell script that:
      //    - Waits for the app to exit
      //    - Finds the actual content folder (handles nested zip structure)
      //    - Copies all files to the app directory
      //    - Restarts the app
      //    - Cleans up
      final ps1Path = '${tempDir.path}\\billings_updater.ps1';

      // Escape paths for PowerShell by using single-quoted strings
      final ps1Content = r'''
Start-Sleep -Seconds 3
Write-Host "Lakhaan Updater - Installing...`n"

$ExtractDir = "''' + extractDir + r'''"
$AppDir = "''' + appDir + r'''"
$AppExe = "''' + appExe + r'''"
$ZipPath = "''' + zipPath + r'''"

# Find the actual source folder:
# If the zip had a single root folder inside (e.g. billings-windows-v1.1.8/),
# use that folder as the source. Otherwise use the extract dir itself.
$Children = Get-ChildItem -Path $ExtractDir
$SourceDir = $ExtractDir
if ($Children.Count -eq 1 -and $Children[0].PSIsContainer) {
    $SourceDir = $Children[0].FullName
}

Write-Host "Copying files from $SourceDir to $AppDir ..."
try {
    Copy-Item -Path "$SourceDir\*" -Destination "$AppDir\" -Recurse -Force -ErrorAction Stop
    Write-Host "Files copied successfully."
} catch {
    Write-Host "ERROR: Failed to copy files: $_"
    pause
    exit 1
}

Write-Host "Starting updated application..."
Start-Process -FilePath $AppExe

Write-Host "Cleaning up..."
Remove-Item -Path $ExtractDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue

Write-Host "Update complete!"
Start-Sleep -Seconds 2
''';

      await File(ps1Path).writeAsString(ps1Content);

      setState(() => _statusText = 'Launching updater and closing app...');

      // 6. Launch the PowerShell updater in a new detached window
      await Process.start(
        'powershell',
        [
          '-NoProfile',
          '-ExecutionPolicy', 'Bypass',
          '-File', ps1Path,
        ],
        mode: ProcessStartMode.detached,
        runInShell: false,
      );

      // 7. Close this app so the script can copy files freely
      await Future.delayed(const Duration(milliseconds: 500));
      exit(0);
    } catch (e) {
      debugPrint('Update error: $e');
      setState(() {
        _downloading = false;
        _errorText = 'Update failed: $e';
        _statusText = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _downloading ? Icons.downloading_rounded : Icons.system_update_alt_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _downloading ? 'Updating...' : 'Update Required',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Version ${widget.updateInfo.latestVersion} is available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current vs latest version
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text('Current', style: theme.textTheme.bodySmall!.copyWith(color: theme.hintColor)),
                                const SizedBox(height: 4),
                                Text(
                                  'v${UpdateService.currentVersion}',
                                  style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary),
                          Expanded(
                            child: Column(
                              children: [
                                Text('Latest', style: theme.textTheme.bodySmall!.copyWith(color: theme.hintColor)),
                                const SizedBox(height: 4),
                                Text(
                                  'v${widget.updateInfo.latestVersion}',
                                  style: theme.textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Release notes
                    if (!_downloading && widget.updateInfo.releaseNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text("What's New", style: theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        widget.updateInfo.releaseNotes,
                        style: theme.textTheme.bodyMedium!.copyWith(color: theme.hintColor),
                      ),
                    ],

                    // Download progress
                    if (_downloading) ...[
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _statusText,
                        style: theme.textTheme.bodySmall!.copyWith(color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                      if (_progress > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(_progress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],

                    // Error message
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: theme.textTheme.bodySmall!.copyWith(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Update button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _downloading ? null : _downloadAndInstall,
                    icon: _downloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _downloading ? 'Updating...' : (_errorText != null ? 'Retry Update' : 'Update Now'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
