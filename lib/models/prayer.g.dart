// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrayerAdapter extends TypeAdapter<Prayer> {
  @override
  final int typeId = 2;

  @override
  Prayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Prayer(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[4] as String,
      prayerTime: fields[5] as DateTime,
      latitude: fields[6] as double,
      longitude: fields[7] as double,
      reminderMinutes: fields[8] as int? ?? 0,
      completedDates: (fields[2] as List?)?.cast<DateTime>(),
      streak: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Prayer obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.completedDates)
      ..writeByte(3)
      ..write(obj.streak)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.prayerTime)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude)
      ..writeByte(8)
      ..write(obj.reminderMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
