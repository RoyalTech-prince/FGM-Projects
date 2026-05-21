import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:full_gospel_hymnal/providers/hymn_provider.dart';
import 'package:full_gospel_hymnal/providers/settings_provider.dart';
import 'package:full_gospel_hymnal/screens/lyrics_screen.dart';
import 'package:full_gospel_hymnal/models/hymn.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final hymnProvider = context.watch<HymnProvider>();
    
    final isDark = theme.brightness == Brightness.dark;
    final isRedTheme = settings.selectedtheme == AppThemeType.red;
    final isEng = settings.defaultLanguage == AppLanguage.en;

    // 1. Extract the active favorite number strings from disk cache
    final List<String> favoriteNumbers = settings.favoriteHymnNumbers;

    // 2. Filter out matching objects from your complete loaded asset directory
    final List<Hymn> favoriteHymns = hymnProvider.allHymns.where((hymn) {
      return favoriteNumbers.contains(hymn.number);
    }).toList();

    // 3. Keep the list perfectly sorted chronologically by our structural integer IDs
    favoriteHymns.sort((a, b) => a.id.compareTo(b.id));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Title block matching your structural design
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isEng ? "My Favorites" : "Mes Favoris",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isRedTheme ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ),
            
            // Core List surface container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  decoration: BoxDecoration(
                    color: isRedTheme ? Colors.white : theme.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: favoriteHymns.isEmpty
                      ? _buildEmptyState(isEng, isDark, isRedTheme)
                      : _buildFavoritesList(favoriteHymns, settings, isDark, isRedTheme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildEmptyState(bool isEng, bool isDark, bool isRedTheme) {
  // Set explicit, high-contrast colors for the red theme status
  final Color iconColor = isRedTheme 
      ? const Color(0xFFD32F2F).withOpacity(0.4) // Soft red accent
      : (isDark ? Colors.white24 : Colors.black26);

  final Color textColor = isRedTheme 
      ? const Color(0xFFD32F2F).withOpacity(0.7) // Readable deep red text
      : (isDark ? Colors.white38 : Colors.black54);

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.favorite_border,
          size: 65,
          color: iconColor, // UPDATED
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            isEng ? "No favorites added yet!" : "Aucun favori ajouté pour le moment !",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600, // Slightly bolder for better legibility
              color: textColor, // UPDATED
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildFavoritesList(List<Hymn> items, SettingsProvider settings, bool isDark, bool isRedTheme) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 15),
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(
        indent: 70, 
        endIndent: 20, 
        color: isRedTheme ? const Color(0xFFD32F2F).withOpacity(0.2) : (isDark ? Colors.white10 : Colors.black12)
      ),
      itemBuilder: (context, index) {
        final hymn = items[index];
        final mainTitle = settings.defaultLanguage == AppLanguage.en ? hymn.titleEn : hymn.titleFr;
        final subTitle = settings.defaultLanguage == AppLanguage.en ? hymn.titleFr : hymn.titleEn;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isRedTheme ? const Color(0xFFD32F2F) : (isDark ? Colors.black : const Color(0xFFD32F2F)),
            child: Text(hymn.number, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
              fontSize: 13,
              color: isRedTheme ? Colors.black54 : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.favorite, color: Color(0xFFE63946)),
            onPressed: () => settings.toggleFavorite(hymn.number),
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