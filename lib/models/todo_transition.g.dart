// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_transition.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoTransitionAdapter extends TypeAdapter<TodoTransition> {
  @override
  final int typeId = 5;

  @override
  TodoTransition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoTransition(
      id: fields[0] as String,
      todoId: fields[1] as String,
      title: fields[2] as String,
      fromStatus: fields[3] as String,
      toStatus: fields[4] as String,
      timestamp: fields[5] as DateTime,
      xpDelta: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TodoTransition obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.todoId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.fromStatus)
      ..writeByte(4)
      ..write(obj.toStatus)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.xpDelta);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoTransitionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
