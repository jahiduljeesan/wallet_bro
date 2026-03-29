import 'package:hive/hive.dart';

part 'account_model.g.dart';

@HiveType(typeId: 1)
class AccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type; // cash, bank, mobile

  @HiveField(3)
  final double initialBalance;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
  });

  AccountModel copyWith({
    String? id,
    String? name,
    String? type,
    double? initialBalance,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'initialBalance': initialBalance,
    };
  }
}
