import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/hymn_provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/screens/lyrics_screen.dart';
import 'package:full_gospel_hymnal/screens/settings_screen.dart';
import 'package:full_gospel_hymnal/utils/app_strings.dart';
import 'package:full_gospel_hymnal/screens/favorites_screen.dart';

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

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  double _dragStartX = 0.0;
  bool _isSwiping = false;

  // NEW: Exactly 3 Screens ordered matching the bottom navbar tabs
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    
    _screens = [
      const HymnListBody(),
      const FavoritesScreen(), // Index 1: Inserted Favorites Screen
      const SettingsScreen(),             // Index 2: Shifted Settings Screen
    ];
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
      
      body: GestureDetector(
        // Intercept horizontal drag gestures manually to control page thresholds
        onHorizontalDragStart: (details) {
          _dragStartX = details.globalPosition.dx;
          _isSwiping = true;
        },
        onHorizontalDragUpdate: (details) {
          if (!_isSwiping) return;
          
          final dragDistance = details.globalPosition.dx - _dragStartX;
          
          // Swipe Left (Go to Next Page)
          if (dragDistance < -60) { // 60 is the pixel threshold sensitivity
            _isSwiping = false; // Lock out further movement during this gesture
            if (_currentIndex < _screens.length - 1) {
              final nextIndex = _currentIndex + 1;
              setState(() {
                _currentIndex = nextIndex;
              });
              _pageController.animateToPage(
                nextIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
          
          // Swipe Right (Go to Previous Page)
          if (dragDistance > 60) {
            _isSwiping = false;
            if (_currentIndex > 0) {
              final prevIndex = _currentIndex - 1;
              setState(() {
                _currentIndex = prevIndex;
              });
              _pageController.animateToPage(
                prevIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        },
        onHorizontalDragEnd: (_) {
          _isSwiping = false; // Reset gesture lock on release
        },
        child: PageView(
          controller: _pageController,
          // CRITICAL: Disable standard momentum scrolling entirely so native physics won't skip pages
          physics: const NeverScrollableScrollPhysics(), 
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _screens,
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Keeps labels locked in place evenly
        backgroundColor: isRedTheme ? Colors.white : (theme.brightness == Brightness.dark ? Colors.black : Colors.white),
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Smooth animation sliding transition on navigation button tap
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          // Index 0
          BottomNavigationBarItem(
            icon: const Icon(Icons.home), 
            label: lang == AppLanguage.en ? 'Home' : 'Accueil',
          ),
          // Index 1: Added Favorites 
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite), 
            label: lang == AppLanguage.en ? 'Favorites' : 'Favoris',
          ),
          // Index 2: Shifted Settings
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