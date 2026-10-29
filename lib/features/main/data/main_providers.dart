import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final mainTabIndexProvider = StateProvider<int>((ref) => 0);

final exploreFilterModeProvider = StateProvider<String>((ref) => 'all');