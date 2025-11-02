import 'package:hive/hive.dart';

part 'toy.g.dart';

@HiveType(typeId: 1)
class Toy extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String rfidUid;

  @HiveField(4)
  final double price;

  @HiveField(5)
  final String imageUrl;

  Toy({
    required this.id,
    required this.name,
    required this.category,
    required this.rfidUid,
    required this.price,
    required this.imageUrl,
  });
}
