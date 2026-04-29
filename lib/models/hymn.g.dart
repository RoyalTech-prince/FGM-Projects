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
      number: fields[0] as int,
      titleEn: fields[1] as String,
      titleFr: fields[2] as String,
      lyricsEn: fields[3] as String,
      lyricsFr: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Hymn obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.titleEn)
      ..writeByte(2)
      ..write(obj.titleFr)
      ..writeByte(3)
      ..write(obj.lyricsEn)
      ..writeByte(4)
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
