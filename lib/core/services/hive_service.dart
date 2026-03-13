import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String categoryBoxName = 'categories';
  static const String userBoxName = 'user_data';
  static const String settingsBoxName = 'settings';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(categoryBoxName);
    await Hive.openBox(userBoxName);
    await Hive.openBox(settingsBoxName);
  }

  Box get categoryBox => Hive.box(categoryBoxName);
  Box get userBox => Hive.box(userBoxName);
  Box get settingsBox => Hive.box(settingsBoxName);

  Future<void> clearAll() async {
    await categoryBox.clear();
    await userBox.clear();
    await settingsBox.clear();
  }
}
