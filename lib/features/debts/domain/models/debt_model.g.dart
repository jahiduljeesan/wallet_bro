// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtModelAdapter extends TypeAdapter<DebtModel> {
  @override
  final int typeId = 4;

  @override
  DebtModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtModel(
      id: fields[0] as String,
      personName: fields[1] as String,
      amount: fields[2] as double,
      isDebt: fields[3] as bool,
      isSettled: fields[4] as bool,
      timestamp: fields[5] as DateTime,
      note: fields[6] as String,
      paidAmount: fields[7] == null ? 0.0 : fields[7] as double,
      payments: fields[8] == null ? [] : (fields[8] as List).cast<DebtPaymentModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, DebtModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.isDebt)
      ..writeByte(4)
      ..write(obj.isSettled)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.paidAmount)
      ..writeByte(8)
      ..write(obj.payments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
