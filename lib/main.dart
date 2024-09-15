import 'package:flutter/material.dart';
import 'package:pure_love/screens/splash_screen.dart';
import 'package:pure_love/services/onesignal_service.dart';
import 'screens/create_house_screen.dart';
import 'screens/home_screen.dart'; // Thay thế bằng file chứa trang chính của bạn
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() {
  runApp(const MyApp());
  OneSignalService.initialize(); // Khởi tạo OneSignal
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pure Love',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Cấu hình định tuyến
      initialRoute: '/splash', // Thay đổi để bắt đầu với màn hình khởi động
      routes: {
        '/splash': (context) => SplashScreen(),
        '/': (context) => const CreateHouseScreen(),
        '/home': (context) => const HomeScreen(), // Trang chính của bạn
      },
    );
  }
}
