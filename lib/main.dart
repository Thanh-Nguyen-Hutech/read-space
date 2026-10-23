import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Thêm import localizations
import 'package:flutter_quill/flutter_quill.dart'; // Thêm import thư viện Quill

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  // Đảm bảo Flutter binding đã khởi tạo trước khi gọi native code (Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Bọc toàn bộ app bằng ProviderScope để sử dụng Riverpod
  runApp(const ProviderScope(child: ReadSpaceApp()));
}

class ReadSpaceApp extends ConsumerWidget {
  const ReadSpaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    // Lắng nghe trạng thái Sáng/Tối từ Provider
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'ReadSpace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),

      themeMode: themeMode,
      routerConfig: goRouter,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate, // Cấp quyền đọc ngôn ngữ cho tool bar Quill
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
    );
  }
}