import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';

// Match exact path from your project tree
import 'package:full_gospel_hymnal/models/hymn.dart'; 

class AppUpdateService {
  // Replace with your actual Play Store package URL
  static const String _playStoreUrl = 
      "https://play.google.com/store/apps/details?id=com.royaltech.full_gospel_hymnal";

  // Replace with your hosted version.json URL
  static const String _versionCheckUrl = 
      "https://raw.githubusercontent.com/RoyalTech-prince/FGM-Projects/refs/heads/main/docs/version.json";

  // ===========================================================================
  // 1. POST-UPDATE HIVE RELOAD (Runs in main.dart)
  // ===========================================================================
  static Future<void> checkAndMigrateDatabaseOnUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final settingsBox = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');

      final String? lastInstalledVersion = settingsBox.get('lastInstalledVersion');

      // First run or version change after a Play Store update
      if (lastInstalledVersion == null || lastInstalledVersion != currentVersion) {
        debugPrint("Update detected ($lastInstalledVersion -> $currentVersion). Reloading Hive DB...");

        await _reloadHymnDataFromAsset();

        // Store version so this reload only happens once per app update
        await settingsBox.put('lastInstalledVersion', currentVersion);
        debugPrint("Hive database successfully reloaded for version $currentVersion.");
      }
    } catch (e) {
      debugPrint("Error during database update migration: $e");
    }
  }

  /// Clears old hymn box and loads updated assets/hymns.json directly into Hive
  static Future<void> _reloadHymnDataFromAsset() async {
    final hymnBox = Hive.isBoxOpen('hymns')
        ? Hive.box<Hymn>('hymns')
        : await Hive.openBox<Hymn>('hymns');

    final String jsonString = await rootBundle.loadString('assets/hymns.json');
    final List<dynamic> jsonList = json.decode(jsonString);

    final List<Hymn> freshHymns = jsonList.map((item) => Hymn.fromJson(item)).toList();

    await hymnBox.clear();
    for (var hymn in freshHymns) {
      await hymnBox.put(hymn.id, hymn);
    }
  }

  // ===========================================================================
  // 2. PLAY STORE UPDATE CHECKER & PROMPT
  // ===========================================================================
  static Future<void> checkForUpdates(BuildContext context, {bool isEng = true}) async {
    try {
      // 1. Check if the user snoozed the update recently
      final settingsBox = Hive.isBoxOpen('settings')
          ? Hive.box('settings')
          : await Hive.openBox('settings');

      final String? snoozeDateStr = settingsBox.get('lastUpdateSnoozeDate');

      if (snoozeDateStr != null) {
        final DateTime snoozeDate = DateTime.parse(snoozeDateStr);
        final Duration difference = DateTime.now().difference(snoozeDate);

        // If less than 5 days have passed, skip showing the popup completely
        if (difference.inDays < 5) {
          debugPrint("Update dialog snoozed. Days remaining: ${5 - difference.inDays}");
          return; 
        }
      }

      // 2. Fetch version check if 5 days have passed (or first time asking)
      final response = await http.get(Uri.parse(_versionCheckUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String latestVersion = data['latest_version'] ?? '';
        
        final packageInfo = await PackageInfo.fromPlatform();
        final String currentVersion = packageInfo.version;

        if (_isVersionHigher(latestVersion, currentVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, isEng);
          }
        }
      }
    } catch (e) {
      debugPrint("Version check skipped or failed: $e");
    }
  }

  
  static bool _isVersionHigher(String latestStr, String currentStr) {
    int latest, current; 
  try {
    // 1. Clean strings (removes "+1" or build metadata)
    final latestParts = latestStr.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = currentStr.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // 2. Compare major, minor, patch step-by-step
    for (int i = 0; i < 3; i++) {
      latest = i < latestParts.length ? latestParts[i] : 0;
      current = i < currentParts.length ? currentParts[i] : 0;

      if (latest > current) return true;  // Remote is higher -> Update!
      if (latest < current) return false; // Local is higher/equal -> Skip!
    }

    return false; // Identical version
  } catch (e) {
    return false;
  }
}

  static void _showUpdateDialog(BuildContext context, String newVersion, bool isEng) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEng ? 'Update Available' : 'Mise à jour disponible',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Text(
            isEng
                ? 'A new version of the Full Gospel Mission Hymnal is available. Update now for a better experience.'
                : 'Une nouvelle version du cantique de la Mission du Plein Evangile est disponible. Veuillez mettre à jour.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final settingsBox = Hive.isBoxOpen('settings')
                    ? Hive.box('settings')
                    : await Hive.openBox('settings');

                await settingsBox.put(
                  'lastUpdateSnoozeDate',
                  DateTime.now().toIso8601String(),
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: Text(
                isEng ? 'Remind me later' : 'Plus tard',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final Uri storeUri = Uri.parse(_playStoreUrl);
                if (await canLaunchUrl(storeUri)) {
                  await launchUrl(storeUri, mode: LaunchMode.externalApplication);
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: Text(
                isEng ? 'Update Now' : 'Mettre à jour',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}