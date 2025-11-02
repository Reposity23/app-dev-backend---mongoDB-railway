// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toy.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ToyAdapter extends TypeAdapter<Toy> {
  @override
  final int typeId = 1;

  @override
  Toy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Toy(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      rfidUid: fields[3] as String,
      price: fields[4] as double,
      imageUrl: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Toy obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.rfidUid)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
