import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/hymn_provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/screens/lyrics_screen.dart';
import 'package:full_gospel_hymnal/screens/settings_screen.dart';
import 'package:full_gospel_hymnal/utils/app_strings.dart';
import 'package:full_gospel_hymnal/screens/favorites_screen.dart';
import 'package:full_gospel_hymnal/utils/AppUpdateService.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      final isEng = settings.defaultLanguage == AppLanguage.en;

      AppUpdateService.checkForUpdates(context, isEng: isEng);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    if (index == _currentIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings   = context.watch<SettingsProvider>();
    final theme      = Theme.of(context);
    final lang       = settings.defaultLanguage;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        // ClampingScrollPhysics: no bounce, no stretch, no elastic effect.
        // At the first and last page the view simply stops dead.
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [
          HymnListBody(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isRedTheme
            ? Colors.white
            : (theme.brightness == Brightness.dark ? Colors.black : Colors.white),
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: _navigateTo,
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


class HymnListBody extends StatelessWidget {
  const HymnListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final settings   = context.watch<SettingsProvider>();
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


class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final settings   = context.watch<SettingsProvider>();
    final theme      = Theme.of(context);
    final isDark     = theme.brightness == Brightness.dark;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;

    return TextField(
      controller: _controller,
      style: TextStyle(
        color: isRedTheme ? Colors.black : (isDark ? Colors.white : Colors.black),
      ),
      onChanged: (value) => context.read<HymnProvider>().search(value),
      decoration: InputDecoration(
        filled: true,
        fillColor: isRedTheme
            ? Colors.white
            : (isDark ? const Color(0xFF1E1E1E) : const Color.fromARGB(255, 228, 227, 227)),
        hintText: AppStrings.searchHint(settings.defaultLanguage),
        hintStyle: TextStyle(
          color: isRedTheme
              ? Colors.black54
              : (isDark ? const Color.fromARGB(137, 206, 204, 204) : Colors.black54),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isRedTheme ? const Color(0xFFD32F2F) : (isDark ? Colors.white54 : Colors.black54),
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: isRedTheme
                      ? const Color(0xFFD32F2F)
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
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


class HymnListView extends StatelessWidget {
  const HymnListView({super.key});

  @override
  Widget build(BuildContext context) {
    final hymnProvider = context.watch<HymnProvider>();
    final settings     = context.watch<SettingsProvider>();
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final isRedTheme   = settings.selectedtheme == AppThemeType.red;

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
      separatorBuilder: (_, __) => Divider(
        indent: 70,
        endIndent: 20,
        color: isRedTheme
            ? const Color(0xFFD32F2F)
            : (isDark ? Colors.white10 : const Color.fromARGB(255, 128, 126, 126)),
      ),
      itemBuilder: (context, index) {
        final hymn      = hymnProvider.hymns[index];
        final mainTitle = settings.defaultLanguage == AppLanguage.en ? hymn.titleEn : hymn.titleFr;
        final subTitle  = settings.defaultLanguage == AppLanguage.en ? hymn.titleFr : hymn.titleEn;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isRedTheme
                ? const Color(0xFFD32F2F)
                : (isDark ? Colors.black : const Color(0xFFD32F2F)),
            child: Text(
              hymn.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
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
                pageBuilder: (_, animation, secondaryAnimation) => LyricsScreen(hymn: hymn),
                transitionsBuilder: (_, animation, secondaryAnimation, child) {
                  final slideIn = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutQuart));
                  final slideOut = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.3, 0.0))
                      .animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOutQuart));
                  return SlideTransition(
                    position: slideOut,
                    child: SlideTransition(position: slideIn, child: child),
                  );
                },
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          },
        );
      },
    );
  }
}