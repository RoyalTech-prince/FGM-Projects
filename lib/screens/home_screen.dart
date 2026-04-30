import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/hymn_provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/screens/lyrics_screen.dart';
import 'package:full_gospel_hymnal/screens/settings_screen.dart';
import 'package:full_gospel_hymnal/utils/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // The screens for each tab
  final List<Widget> _screens = [
    const HymnListBody(),
    const SettingsScreen(),
    const Center(child: Text("About Screen")),
  ];

  @override
  Widget build(BuildContext context) {
    // Access the provider for language and theme updates
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final lang = settings.defaultLanguage;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _screens[_currentIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        // Dynamic styling to match the theme
        backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
        selectedItemColor: theme.brightness == Brightness.dark ? Colors.redAccent : const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home), 
            label: lang == AppLanguage.en ? 'Home' : 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings), 
            label: AppStrings.settings(lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info), 
            label: lang == AppLanguage.en ? 'About' : 'À propos',
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
                  color: theme.cardColor,
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
    
    return TextField(
      controller: _controller,
      style: const TextStyle(color: Colors.black),
      onChanged: (value) {
        context.read<HymnProvider>().search(value);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: AppStrings.searchHint(settings.defaultLanguage),
        hintStyle: const TextStyle(color: Colors.black54),
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.black54),
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
        color: isDark ? Colors.white10 : Colors.black12,
      ),
      itemBuilder: (context, index) {
        final hymn = hymnProvider.hymns[index];
        // Flip titles based on preferred language
        final mainTitle = settings.defaultLanguage == AppLanguage.en ? hymn.titleEn : hymn.titleFr;
        final subTitle = settings.defaultLanguage == AppLanguage.en ? hymn.titleFr : hymn.titleEn;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFD32F2F),
            child: Text("${hymn.number}", style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          title: Text(
            mainTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            subTitle, 
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LyricsScreen(hymn: hymn)),
            );
          },
        );
      },
    );
  }
}