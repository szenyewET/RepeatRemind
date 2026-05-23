import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
enum Category {
  @HiveField(0)
  car,
  @HiveField(1)
  home,
  @HiveField(2)
  pet,
  @HiveField(3)
  health,
  @HiveField(4)
  garden,
  @HiveField(5)
  other,
}
