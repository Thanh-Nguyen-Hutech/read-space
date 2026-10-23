import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier quản lý trạng thái ThemeMode
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Mặc định trả về Theme sáng ban đầu
    return ThemeMode.light;
  }

  // Hàm chuyển đổi giữa Sáng và Tối
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

// Provider cung cấp ThemeNotifier cho toàn bộ app
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});