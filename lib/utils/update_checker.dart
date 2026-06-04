import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  // Your live GitHub Pages direct URL endpoint
  static const String _updateUrl = 'https://royaltech-prince.github.io/FGM-Projects/version.json';
  
  // Replace this with your exact Play Store package identifier once registered
  static const String _playStoreUrl = 'https://www.google.com/search?client=ubuntu-sn&channel=fs&q=games';

  static Future<void> checkForUpdates(Function showDialogCallback) async {
    try {
      // 1. Fetch current local app version (e.g., "1.0.0")
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      // 2. Fetch latest version deployment configuration from GitHub Pages
      final response = await http.get(Uri.parse(_updateUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      final String latestVersion = data['latest_version'];

      // If up to date, exit early
      if (currentVersion == latestVersion) return;

      // 3. Evaluate the 5-day snooze logic from your settings box
      final box = Hive.box('settings');
      final String? lastSnoozeStr = box.get('lastUpdateSnoozeDate');
      
      if (lastSnoozeStr != null) {
        final DateTime lastSnoozeDate = DateTime.parse(lastSnoozeStr);
        final int daysDifference = DateTime.now().difference(lastSnoozeDate).inDays;
        
        if (daysDifference < 5) {
          return; // Suppress dialog; 5 days have not passed yet
        }
      }

      // Trigger the modal dialog callback on the UI thread
      showDialogCallback();
    } catch (e) {
      // Fail silently to safeguard application boot stability on poor networks
      print("Update diagnostic check omitted: $e");
    }
  }

  static Future<void> launchPlayStore() async {
    final Uri url = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}