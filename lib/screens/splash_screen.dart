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
    setState(() {
      _lineFactor = 1.0;
    });

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

    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. TOP MARGIN (Your original 80)
            const SizedBox(height: 80),

            // 2. FRENCH TEXT
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Chantez des louanges de Dieu",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Limelight',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // 3. THE CENTER LOGO & NOTES (Using your exact coordinates)
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // Bottom Layer: The Main Logo
                Image.asset(
                  'assets/images/FGM.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
                
                // Top Layer: The Music Notes (Your restored offset)
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

            const SizedBox(height: 40),

            // 4. THE TAPERED ANIMATED LINE (Width 230)
            _buildAnimatedLine(230),

            const SizedBox(height: 30),

            // 5. ENGLISH TEXT
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Sing Praises of the Lord",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Limelight',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            // 6. BOTTOM BALANCE
            const Spacer(),
          ],
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
        height: 8, // Thicker in the middle
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

// CUSTOM CLIPPER FOR THE TAPERED SHAPE
class SpindleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Pointed at the left end
    path.moveTo(0, size.height / 2);
    // Curve up to the thickest part in the middle, then to the right point
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height / 2);
    // Curve back down through the bottom center to the starting point
    path.quadraticBezierTo(size.width / 2, size.height, 0, size.height / 2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}