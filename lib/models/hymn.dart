// models/hymn.dart
import 'package:hive/hive.dart';

part 'hymn.g.dart';  // This will be generated

@HiveType(typeId: 0)
class Hymn {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String number;
  
  @HiveField(2)
  final String titleEn;
  
  @HiveField(3)
  final String titleFr;
  
  @HiveField(4)
  final String lyricsEn;
  
  @HiveField(5)
  final String lyricsFr;

  Hymn({
    required this.id,
    required this.number,
    required this.titleEn,
    required this.titleFr,
    required this.lyricsEn,
    required this.lyricsFr,
  });

  factory Hymn.fromJson(Map<String, dynamic> json) {
    return Hymn(
      id: json['id'] as int,
      number: json['number'] as String,
      titleEn: json['titleEn'] as String,
      titleFr: json['titleFr'] as String,
      lyricsEn: json['lyricsEn'] as String,
      lyricsFr: json['lyricsFr'] as String,
    );
  }
  
  // Convert to JSON if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'titleEn': titleEn,
      'titleFr': titleFr,
      'lyricsEn': lyricsEn,
      'lyricsFr': lyricsFr,
    };
  }
}