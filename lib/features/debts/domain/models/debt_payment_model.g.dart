// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_payment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtPaymentModelAdapter extends TypeAdapter<DebtPaymentModel> {
  @override
  final int typeId = 6;

  @override
  DebtPaymentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtPaymentModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      timestamp: fields[2] as DateTime,
      note: fields[3] as String,
      accountId: fields[4] == null ? 'cash_account' : fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DebtPaymentModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.accountId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtPaymentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
