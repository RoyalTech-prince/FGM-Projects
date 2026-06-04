import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:full_gospel_hymnal/screens/home_screen.dart';
import 'package:full_gospel_hymnal/screens/LanguageSelectionScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _lineFactor = 0.0; // 0.0 to 1.0

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  void _startSequence() async {
    // 1. Initial pause to see the logo
    await Future.delayed(const Duration(milliseconds: 2000));

    // 2. Start the spindle line expansion
    if (mounted) {
      setState(() {
        _lineFactor = 1.0;
      });
    }

    // 3. Wait for the animation to finish
    await Future.delayed(const Duration(milliseconds: 2500));

    _navigateToNext();
  }

  void _navigateToNext() {
    if (!mounted) return;
    final bool isFirstRun = Hive.box('settings').get('isFirstRun', defaultValue: true);
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => 
            isFirstRun ? const LanguageSelectionScreen() : const HomeScreen(),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color softBg = Color(0xFFF5F5F5);
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // Check orientation to calculate optical balance adjustments
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // TOP BALANCER: Safe baseline spacing
              const Spacer(flex: 3),

              // FRENCH TEXT
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Chantez des louanges de Dieu",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Limelight',
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Dynamic gap between text and core branding
              const Spacer(flex: 1),

              // THE CENTER LOGO & NOTES
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    'assets/images/FGM.png',
                    width: 220,
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    bottom: -(screenHeight * 0.05), 
                    child: Image.asset(
                      'assets/images/MusicNote.png',
                      width: 180,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),

              // Spacing cushion to isolate music note offset overlap
              const Spacer(flex: 1),

              // THE TAPERED ANIMATED LINE
              _buildAnimatedLine(230),

              // Dynamic gap before second text string
              //const Spacer(flex: 1),
              const SizedBox(height: 20), // Small fixed gap for visual breathing

              // ENGLISH TEXT
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Sing Praises of the Lord",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Limelight',
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: Colors.black87,
                  ),
                ),
              ),

              // BOTTOM BALANCER: Applies extra weight in portrait to create an 
              // upward pull, accommodating human optical centering.
              Spacer(flex: isPortrait ? 5 : 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLine(double maxWidth) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 2500),
        curve: Curves.easeInOutSine,
        width: _lineFactor * maxWidth,
        height: 8,
        child: ClipPath(
          clipper: SpindleClipper(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFD700), // Gold
                  Color(0xFFD32F2F), // Red
                  Color(0xFFFFD700), // Gold
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpindleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height / 2);
    path.quadraticBezierTo(size.width / 2, size.height, 0, size.height / 2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}