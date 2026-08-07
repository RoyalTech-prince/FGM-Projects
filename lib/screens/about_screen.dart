import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Import to open mailing clients
import 'package:flutter/services.dart'; // Import for clipboard functionality
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = "1.0.0"; // Default version in case of failure

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try{
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted){
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint("Failed to load app version: $e");
    }
  }

  // Helper method to safely format and trigger the system mailto URI intent
  Future<void> _sendCorrectionEmail(bool isEng) async {
    const String email = "royaltechprince@gmail.com"; 
    final String subject = isEng 
        ? "FULL GOSPEL HYMNAL CORRECTION" 
        : "CORRECTION DES CANTIQUES DU PLEIN EVANGILE";
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not find a valid email application client on this device.");
      }
    } catch (e) {
      debugPrint("Error launching email client: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    
    final isDark = theme.brightness == Brightness.dark;
    final isBlackTheme = settings.selectedtheme == AppThemeType.black;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;
    final isEng = settings.defaultLanguage == AppLanguage.en;

    final Color cardBg = isRedTheme ? Colors.white : theme.cardColor;
    
    // FIXED CONTRAST: Use dark text when on the white card background of Red Theme
    final Color itemTextColor = isRedTheme ? Colors.black : (isDark ? Colors.white : Colors.black87);
    final Color dynamicIconColor = isBlackTheme ? Colors.white : (isRedTheme ? const Color(0xFFD32F2F):Colors.black);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        centerTitle: true, 
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: dynamicIconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEng ? "About" : "À propos",
          style: TextStyle(color: itemTextColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Align(
        alignment: const Alignment(0.0, -0.4), // Positions content nicely pulled slightly upward
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              const SizedBox(height: 10),
              // App Branding Graphic Context
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/images/FGM.png',
                        fit: BoxFit.contain, //Here the logo fits well in the white oval background
                        errorBuilder: (context, error, stackTrace){
                          return const Icon(
                            Icons.auto_stories,
                            size: 45,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 25),
              Text(
                isEng ? "Full Gospel Mission Hymnal" : "Cantiques de la Mission du Plein Évangile",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w700, 
                  color: isRedTheme ? Colors.white : (isDark ? Colors.white : Colors.black87), 
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Version $_appVersion",
                style: TextStyle(fontSize: 13, color: Colors.grey.withOpacity(0.8), letterSpacing: 0.5),
              ),
              const SizedBox(height: 30),
              Text(
                isEng
                    ? "PRAISE BE TO THE LORD OF HOST"
                    : "Louange à l'Éternel des armées",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6, color:isRedTheme ? Colors.white : (isDark ? Colors.white : Colors.black87)),
              ),

              const SizedBox(height: 35),

              // ADDED: Dropdown Accordion Contact Section
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent), // Removes the default expansion borders
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: ExpansionTile(
                    iconColor: dynamicIconColor,
                    collapsedIconColor: itemTextColor.withOpacity(0.6),
                    leading: Icon(Icons.mail_outline, color: dynamicIconColor),
                    title: Text(
                      isEng ? "Contact Us" : "Contactez-nous",
                      style: TextStyle(color: itemTextColor, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1, thickness: 1, color: Colors.black12),
                            const SizedBox(height: 12),
                            // Encouraging feedback text block
                            Text(
                              isEng
                                  ? "Did you spot a typing error, an incorrect hymn number, or missing lyrics? Please let us know so we can fix it immediately!"
                                  : "Avez-vous remarqué une faute de d'orthographe, un numéro de cantique incorrect ou des paroles manquantes ? Signalez-le nous pour correction immédiate !",
                              style: TextStyle(color: itemTextColor.withOpacity(0.7), fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 15),
                            // Interactive Clickable & Copyable Email Button Card
                            InkWell(
                              onTap: () => _sendCorrectionEmail(isEng),
                              onLongPress: () async {
                                // Automatically copies the email to the Android/iOS clipboard
                                await Clipboard.setData(
                                  const ClipboardData(text: "royaltechprince@gmail.com"),
                                );
                                
                                // Shows a quick confirmation snackbar to the user
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEng 
                                            ? "Email address copied to clipboard!" 
                                            : "Adresse e-mail copiée dans le presse-papiers !",
                                      ),
                                      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFD32F2F),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFD32F2F).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "royaltechprince@gmail.com",
                                        style: TextStyle(
                                          color: dynamicIconColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // The arrowed box icon also explicitly opens the email client when tapped
                                    Icon(
                                      Icons.open_in_new, 
                                      size: 16, 
                                      color: dynamicIconColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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