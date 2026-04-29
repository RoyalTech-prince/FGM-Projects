// models/hymn.dart
import 'package:hive/hive.dart';

part 'hymn.g.dart';  // This will be generated

@HiveType(typeId: 0)
class Hymn {
  @HiveField(0)
  final int number;
  
  @HiveField(1)
  final String titleEn;
  
  @HiveField(2)
  final String titleFr;
  
  @HiveField(3)
  final String lyricsEn;
  
  @HiveField(4)
  final String lyricsFr;

  Hymn({
    required this.number,
    required this.titleEn,
    required this.titleFr,
    required this.lyricsEn,
    required this.lyricsFr,
  });

  factory Hymn.fromJson(Map<String, dynamic> json) {
    return Hymn(
      number: json['number'] as int,
      titleEn: json['titleEn'] as String,
      titleFr: json['titleFr'] as String,
      lyricsEn: json['lyricsEn'] as String,
      lyricsFr: json['lyricsFr'] as String,
    );
  }
  
  // Convert to JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'titleEn': titleEn,
      'titleFr': titleFr,
      'lyricsEn': lyricsEn,
      'lyricsFr': lyricsFr,
    };
  }
}