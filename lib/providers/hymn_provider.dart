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
    _searchQuery = query.trim().toLowerCase();
    
    if (_searchQuery.isEmpty) {
      _filteredHymns = [];
    } else {
      // Searching across number, titles, AND lyrics for full coverage
      _filteredHymns = _hymns.where((hymn) {
        final matchesNumber = hymn.number.toLowerCase().contains(_searchQuery);
        
        final matchesTitle = hymn.titleEn.toLowerCase().contains(_searchQuery) ||
                             hymn.titleFr.toLowerCase().contains(_searchQuery);
        
        // Logic to check lyrics fields
        final matchesLyrics = hymn.lyricsEn.toLowerCase().contains(_searchQuery) ||
                              hymn.lyricsFr.toLowerCase().contains(_searchQuery);

        return matchesNumber || matchesTitle || matchesLyrics;
      }).toList();
    }
    
    notifyListeners();
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
          // FIXED: Map registration keys use the integer ID now, not the alphanumeric number string
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