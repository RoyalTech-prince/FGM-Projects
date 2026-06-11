import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:full_gospel_hymnal/models/hymn.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HymnProvider extends ChangeNotifier {
  List<Hymn> _hymns = [];
  List<Hymn> _filteredHymns = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  Box<Hymn>? _hymnsBox;

  // Getters
  List<Hymn> get hymns => _searchQuery.isEmpty ? _hymns : _filteredHymns;
  
  // NEW: Exposes the full master list so the Favorites Screen works flawlessly
  List<Hymn> get allHymns => _hymns;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Optimized search implementation for production
  void search(String query) {
  // Normalize the query once outside the loop for maximum performance
    _searchQuery = _normalizeText(query);
    
    if (_searchQuery.isEmpty) {
      _filteredHymns = [];
      } else {
        // Searching across numbers, titles, AND lyrics with accent/sign normalization
        _filteredHymns = _hymns.where((hymn) {
          // Numbers don't have accents, but we lower-case them for safety
          final matchesNumber = hymn.number.toLowerCase().contains(_searchQuery);
          
          // Normalize titles
          final normalizedTitleEn = _normalizeText(hymn.titleEn);
          final normalizedTitleFr = _normalizeText(hymn.titleFr);
          final matchesTitle = normalizedTitleEn.contains(_searchQuery) ||
                              normalizedTitleFr.contains(_searchQuery);
          
          // Normalize lyrics
          final normalizedLyricsEn = _normalizeText(hymn.lyricsEn);
          final normalizedLyricsFr = _normalizeText(hymn.lyricsFr);
          final matchesLyrics = normalizedLyricsEn.contains(_searchQuery) ||
                                normalizedLyricsFr.contains(_searchQuery);

          return matchesNumber || matchesTitle || matchesLyrics;
      }).toList();
    }
  
  notifyListeners();
}

  String _normalizeText(String text) {
  var normalized = text.toLowerCase();

  // 1. Map common French accents manually to their base characters
  // (Fastest, most reliable way in Dart without heavy external packages)
  final accents = {
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'à': 'e', 'â': 'e', 'ä': 'e',
    'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c',
  };

  accents.forEach((accent, base) {
    normalized = normalized.replaceAll(accent, base);
  });

  // 2. Strip out apostrophes, hyphens, commas, and periods
  // This turns "l'eternel" into "leternel" and "chante-haut" into "chantehaut"
  normalized = normalized.replaceAll(RegExp(r"[‘’''`\-,\.]"), "");

  // 3. Remove extra internal spaces and trim whitespace boundaries
  return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
}

  /// Initializing the local DB from assets if empty
  Future<void> initHymns() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      _hymnsBox = await Hive.openBox<Hymn>('hymnsBox');
      
      if (_hymnsBox!.isEmpty) {
        try {
          final String jsonString = await rootBundle.loadString('assets/hymns.json');
          final List<dynamic> jsonData = json.decode(jsonString);
          
          // Bulk insert for better performance on mobile devices
          //Map registration keys use the integer ID now, not the alphanumeric number string
          final Map<int, Hymn> hymnMap = {};
          for (var item in jsonData) {
            final parsedHymn = Hymn.fromJson(item);
            hymnMap[parsedHymn.id] = parsedHymn;
          }
          await _hymnsBox!.putAll(hymnMap);
          
        } catch (e) {
          _errorMessage = "Data migration failed: $e";
          _isLoading = false;
          notifyListeners();
          return;
        }
      } 
      
      // Materialize list from Hive and sort
      _hymns = _hymnsBox!.values.toList();
      
      // FIXED: Sort using the structural integer ID so 41a and 41b sit beautifully in line
      _hymns.sort((a, b) => a.id.compareTo(b.id));
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _errorMessage = "Initialization error: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Maintenance method for data updates or corruption
  Future<void> resetBox() async {
    try {
      await Hive.deleteBoxFromDisk('hymnsBox');
      _hymns = [];
      _filteredHymns = [];
      await initHymns();
    } catch (e) {
      debugPrint("Error resetting persistence layer: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}