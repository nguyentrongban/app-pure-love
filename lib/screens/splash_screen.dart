import 'package:flutter/material.dart';
import 'package:pure_love/screens/create_house_screen.dart'; // Thay thế bằng đường dẫn đúng đến CreateHouseScreen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 2));
    Navigator.of(context)
        .pushReplacementNamed('/'); // Chuyển đến trang chính sau 3 giây
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
          255, 255, 156, 216), // Màu nền của màn hình khởi động
      body: Center(
        child: Image.asset(
            'assets/logo_pure_love.png'), // Đường dẫn đến logo của bạn
      ),
    );
  }
}
