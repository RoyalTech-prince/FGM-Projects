// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hymn.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HymnAdapter extends TypeAdapter<Hymn> {
  @override
  final int typeId = 0;

  @override
  Hymn read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Hymn(
      id: fields[0] as int,          // Added: Index 0 is now the integer ID
      number: fields[1] as String,   // Shifted: Index 1 is the String number
      titleEn: fields[2] as String,  // Shifted to 2
      titleFr: fields[3] as String,  // Shifted to 3
      lyricsEn: fields[4] as String, // Shifted to 4
      lyricsFr: fields[5] as String, // Shifted to 5
    );
  }

  @override
  void write(BinaryWriter writer, Hymn obj) {
    writer
      ..writeByte(6)                 // Changed from 5 to 6 fields total
      ..writeByte(0)
      ..write(obj.id)                // Writes the sorting ID first
      ..writeByte(1)
      ..write(obj.number)            // Writes the visual alphanumeric label
      ..writeByte(2)
      ..write(obj.titleEn)
      ..writeByte(3)
      ..write(obj.titleFr)
      ..writeByte(4)
      ..write(obj.lyricsEn)
      ..writeByte(5)
      ..write(obj.lyricsFr);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HymnAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}