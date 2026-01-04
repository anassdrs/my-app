// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 0;

  @override
  Todo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Todo(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      date: fields[3] as DateTime,
      isCompleted: fields[4] as bool,
      status: fields[8] as String?,
      completedAt: fields[9] as DateTime?,
      xpApplied: fields[10] as bool? ?? false,
      isFocused: fields[11] as bool? ?? false,
      focusDate: fields[12] as DateTime?,
      focusBonusAwardedAt: fields[13] as DateTime?,
      subtasks: (fields[14] as List?)?.cast<TodoSubtask>(),
      linkedHabitId: fields[15] as String?,
      memorizationStatus: fields[16] as String?,
      reviewDueDate: fields[17] as DateTime?,
      reviewIntervalDays: fields[18] as int?,
      lastReviewedAt: fields[19] as DateTime?,
      reviewRepeatCount: fields[20] as int?,
      reviewInterval: fields[21] as Duration?,
      surahNumber: fields[22] as int?,
      startAyah: fields[23] as int?,
      endAyah: fields[24] as int?,
      endTime: fields[5] as DateTime?,
      priority: fields[6] as int,
      category: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.endTime)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.xpApplied)
      ..writeByte(11)
      ..write(obj.isFocused)
      ..writeByte(12)
      ..write(obj.focusDate)
      ..writeByte(13)
      ..write(obj.focusBonusAwardedAt)
      ..writeByte(14)
      ..write(obj.subtasks)
      ..writeByte(15)
      ..write(obj.linkedHabitId)
      ..writeByte(16)
      ..write(obj.memorizationStatus)
      ..writeByte(17)
      ..write(obj.reviewDueDate)
      ..writeByte(18)
      ..write(obj.reviewIntervalDays)
      ..writeByte(19)
      ..write(obj.lastReviewedAt)
      ..writeByte(20)
      ..write(obj.reviewRepeatCount)
      ..writeByte(21)
      ..write(obj.reviewInterval)
      ..writeByte(22)
      ..write(obj.surahNumber)
      ..writeByte(23)
      ..write(obj.startAyah)
      ..writeByte(24)
      ..write(obj.endAyah);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TodoSubtaskAdapter extends TypeAdapter<TodoSubtask> {
  @override
  final int typeId = 4;

  @override
  TodoSubtask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoSubtask(
      id: fields[0] as String,
      title: fields[1] as String,
      completed: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TodoSubtask obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoSubtaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
