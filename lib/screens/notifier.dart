import 'package:flutter/foundation.dart';

class ModeChangeNotifier extends ValueNotifier<int> {
  ModeChangeNotifier() : super(0);
  void notify() => value++;
}

final modeChangeNotifier = ModeChangeNotifier();