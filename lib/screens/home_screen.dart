import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/hymn_provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/screens/lyrics_screen.dart';
import 'package:full_gospel_hymnal/screens/settings_screen.dart';
import 'package:full_gospel_hymnal/utils/app_strings.dart';
import 'package:full_gospel_hymnal/screens/favorites_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:full_gospel_hymnal/utils/update_checker.dart';


// NEW: Keep this placeholder inline or import it if it's a separate file
class FavoritesScreenPlaceholder extends StatelessWidget {
  const FavoritesScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Center(
        child: Text(
          settings.defaultLanguage == AppLanguage.en ? "Favorites Screen" : "Écran des Favoris",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 18),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Custom physics class that safely restricts swipes to exactly one screen at a time
class SinglePageScrollPhysics extends PageScrollPhysics {
  const SinglePageScrollPhysics({super.parent});

  @override
  SinglePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SinglePageScrollPhysics(parent: buildParent(ancestor));
  }

  // --- ADD THIS METHOD to stop the long drag past the edges ---
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // If trying to overscroll past the left edge (Home)
    if (value < position.minScrollExtent && position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    // If trying to overscroll past the right edge (Settings)
    if (value > position.maxScrollExtent && position.pixels >= position.maxScrollExtent) {
      return value - position.pixels;
    }
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // If the user flings fast to the right (positive velocity) or left (negative velocity),
    // we damp the speed down to a tiny number close to 0.
    // This stops kinetic momentum from carrying the swipe across multiple screens!
    if (velocity.abs() > 0.0) {
      return super.createBallisticSimulation(
        position, 
        velocity.isNegative ? -5 : 5,
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  
  // Track the target page index during a swipe to prevent page-skipping
  double _lastReportedPage = 0.0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    
    _screens = [
      const HymnListBody(),
      const FavoritesScreen(), 
      const SettingsScreen(),             
    ];

    // Listen to the page position dynamically as the user drags
    _pageController.addListener(() {
      final double currentPage = _pageController.page ?? 0.0;
      
      // If the user tries to jump past the immediate next screen in a single swipe,
      // we gracefully clamp the position back to the safe boundary.
      if ((currentPage - _lastReportedPage).abs() > 1.0) {
        _pageController.position.correctPixels(
          _lastReportedPage.roundToDouble() * _pageController.position.viewportDimension
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.checkForUpdates(_showUpdateDialog);
    });
  }

  //UI Dialog builder that is cleanly handled by the UpdateChecker background process
  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force an interactive selection option
      builder: (BuildContext context) {
        final settings = context.read<SettingsProvider>();
        final lang = settings.defaultLanguage;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            lang == AppLanguage.en 
                ? 'Update Available' 
                : 'Mise à jour disponible',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Text(
            lang == AppLanguage.en
                ? 'A new version of the Full Gospel Mission Hymnal is available. Update now for the better experience.'
                : 'Une nouvelle version du cantique de la Mission du Plein Evangile est disponible. Veuillez mettre à jour.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Save the current timestamp to Hive settings box to trigger a 5-day snooze cycle
                final box = Hive.box('settings');
                box.put('lastUpdateSnoozeDate', DateTime.now().toIso8601String());
                
                Navigator.of(context).pop(); // Dismiss window safely
              },
              child: Text(
                lang == AppLanguage.en ? 'Remind me later' : 'Plus tard',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F), // Matches app accent theme profile
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                UpdateChecker.launchPlayStore();
                Navigator.of(context).pop();
              },
              child: Text(
                lang == AppLanguage.en ? 'Update Now' : 'Mettre à jour',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
  

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final lang = settings.defaultLanguage;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          // As soon as the user finishes their drag gesture, we lock in the new reference baseline
          if (notification is ScrollEndNotification) {
            _lastReportedPage = _pageController.page ?? 0.0;
          }
          return false;
        },
        child: PageView(
          controller: _pageController,
          // BouncingScrollPhysics provides that instant, fluid WhatsApp touch-response
          physics: const SinglePageScrollPhysics(parent: ClampingScrollPhysics()), 
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _screens,
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, 
        backgroundColor: isRedTheme ? Colors.white : (theme.brightness == Brightness.dark ? Colors.black : Colors.white),
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _lastReportedPage = index.toDouble(); // Sync anchor on tab tap
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home), 
            label: lang == AppLanguage.en ? 'Home' : 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite), 
            label: lang == AppLanguage.en ? 'Favorites' : 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings), 
            label: AppStrings.settings(lang),
          ),
        ],
      ),
    );
  }


}

// --- Extracted Body for Tab 0 (The Search/Hymn List) ---
class HymnListBody extends StatelessWidget {
  const HymnListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final isRedTheme = settings.selectedtheme == AppThemeType.red;
    
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
            child: SearchBarWidget(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                decoration: BoxDecoration(
                  color: isRedTheme ? Colors.white : theme.cardColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const HymnListView(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Search Bar Widget ---
class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;

    return TextField(
      controller: _controller,
      style: TextStyle(color: isRedTheme ? Colors.black : (isDark ? Colors.white : Colors.black)),
      onChanged: (value) {
        context.read<HymnProvider>().search(value);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: isRedTheme ? Colors.white : (isDark ? const Color(0xFF1E1E1E) : const Color.fromARGB(255, 228, 227, 227)),
        hintText: AppStrings.searchHint(settings.defaultLanguage),
        hintStyle: TextStyle(color: isRedTheme ? Colors.black54 : (isDark ? const Color.fromARGB(137, 206, 204, 204) : Colors.black54)),
        prefixIcon: Icon(Icons.search, color: isRedTheme ? const Color(0xFFD32F2F) : (isDark ? Colors.white54 : Colors.black54)),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: isRedTheme ? const Color(0xFFD32F2F) : (isDark ? Colors.white54 : Colors.black54)),
                onPressed: () {
                  _controller.clear();
                  context.read<HymnProvider>().search('');
                  setState(() {}); 
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// --- Hymn List Widget ---
class HymnListView extends StatelessWidget {
  const HymnListView({super.key});

  @override
  Widget build(BuildContext context) {
    final hymnProvider = context.watch<HymnProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;

    if (hymnProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)));
    }

    if (hymnProvider.hymns.isEmpty) {
      return Center(
        child: Text(
          settings.defaultLanguage == AppLanguage.en ? "No hymns found!" : "Aucun cantique trouvé !",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: hymnProvider.hymns.length,
      separatorBuilder: (context, index) => Divider(
        indent: 70, 
        endIndent: 20, 
        color: isRedTheme ? const Color(0xFFD32F2F) : (isDark ? Colors.white10 : const Color.fromARGB(255, 128, 126, 126))
      ),
      itemBuilder: (context, index) {
        final hymn = hymnProvider.hymns[index];
        final mainTitle = settings.defaultLanguage == AppLanguage.en ? hymn.titleEn : hymn.titleFr;
        final subTitle = settings.defaultLanguage == AppLanguage.en ? hymn.titleFr : hymn.titleEn;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isRedTheme ? const Color(0xFFD32F2F) : (isDark ? Colors.black : const Color(0xFFD32F2F)),
            child: Text(hymn.number, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          title: Text(
            mainTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: isRedTheme ? Colors.black : (isDark ? Colors.white : Colors.black),
            ),
          ),
          subtitle: Text(
            subTitle, 
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isRedTheme ? Colors.black54 : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => LyricsScreen(hymn: hymn),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final slideIn = Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutQuart));
                  
                  final slideOut = Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(-0.3, 0.0),
                  ).animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOutQuart));
                  
                  return SlideTransition(
                    position: slideOut,
                    child: SlideTransition(
                      position: slideIn,
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          }
        );
      },
    );
  }
}