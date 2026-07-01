// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_summary_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlySummaryModelAdapter extends TypeAdapter<MonthlySummaryModel> {
  @override
  final int typeId = 3;

  @override
  MonthlySummaryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlySummaryModel(
      id: fields[0] as String,
      totalIncome: fields[1] as double,
      totalExpense: fields[2] as double,
      categoryBreakdown: (fields[3] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, MonthlySummaryModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.totalIncome)
      ..writeByte(2)
      ..write(obj.totalExpense)
      ..writeByte(3)
      ..write(obj.categoryBreakdown);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlySummaryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
