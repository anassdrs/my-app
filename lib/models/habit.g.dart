// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 1;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[4] as String,
      startTime: fields[5] as DateTime?,
      completedDates: (fields[2] as List?)?.cast<DateTime>(),
      streak: fields[3] as int,
      category: fields[6] as String,
      habitType: fields[7] as String,
      frequencyType: fields[8] as String? ?? 'daily',
      frequencyValue: fields[9] as int? ?? 1,
      customDays: (fields[10] as List?)?.cast<int>(),
      windowStartMinutes: fields[11] as int?,
      windowEndMinutes: fields[12] as int?,
      evaluatedDates: (fields[13] as List?)?.cast<String>(),
      lastEvaluatedDate: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.completedDates)
      ..writeByte(3)
      ..write(obj.streak)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.habitType)
      ..writeByte(8)
      ..write(obj.frequencyType)
      ..writeByte(9)
      ..write(obj.frequencyValue)
      ..writeByte(10)
      ..write(obj.customDays)
      ..writeByte(11)
      ..write(obj.windowStartMinutes)
      ..writeByte(12)
      ..write(obj.windowEndMinutes)
      ..writeByte(13)
      ..write(obj.evaluatedDates)
      ..writeByte(14)
      ..write(obj.lastEvaluatedDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
