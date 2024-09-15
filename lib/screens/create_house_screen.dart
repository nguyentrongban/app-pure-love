import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Thư viện Font Awesome
import 'package:pure_love/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateHouseScreen extends StatefulWidget {
  const CreateHouseScreen({Key? key}) : super(key: key);

  @override
  State<CreateHouseScreen> createState() => _CreateHouseScreenState();
}

class _CreateHouseScreenState extends State<CreateHouseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _nameAController = TextEditingController();
  final TextEditingController _nameBController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _userNameController =
      TextEditingController(); // Controller cho userName
  bool _isCreated = false; // Theo dõi trạng thái đăng ký

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Hiển thị thông báo từ backend
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleCreateHouse() async {
    if (_formKey.currentState!.validate()) {
      // Gọi hàm từ ApiService để tạo nhà
      final response = await ApiService.createHouse(
        key: _keyController.text,
        nameA: _nameAController.text,
        nameB: _nameBController.text,
        startDate: _startDateController.text,
      );

      if (response != null) {
        print(
            'Response body: ${response.toString()}'); // In ra chi tiết phản hồi

        final message = response['message'] ?? 'Phòng đã tạo thành công!';
        _showSnackbar(message); // Hiển thị thông báo

        // Xử lý trạng thái thành công
        if (response['status'] == 'success') {
          setState(() {
            _isCreated = true;
          });

          // Chuyển tab về tab nhập key
          _tabController
              .animateTo(0); // Chuyển sang tab đầu tiên (tab nhập key)
        } else {
          _showSnackbar(response['message'] ??
              'Failed to create house.'); // Hiển thị thông báo lỗi
        }
      } else {
        _showSnackbar(
            'Failed to create house. Response is null.'); // Hiển thị thông báo lỗi
      }
    }
  }

  // Xử lý khi nhấn nút trong tab nhập key
  void _handleSubmitKey() async {
    final key = _keyController.text;
    final userName = _userNameController.text;

    final response = await ApiService.loginWithKey(key, userName);
    //print('API response login: $response'); // In ra phản hồi từ API

    if (response != null) {
      final message = response['message'] ?? 'Login successful!';
      _showSnackbar(message);

      if (response['status'] == 'success') {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('house_id', response['house']['id'].toString());
          await prefs.setString('user_name', userName);

          // Chuyển hướng sau khi lưu thông tin thành công
          Navigator.of(context).pushReplacementNamed('/home');
        } catch (e) {
          print('Error saving to SharedPreferences: $e');
        }
      } else {
        _showSnackbar('Login failed: ${response['message']}');
      }
    } else {
      _showSnackbar('Failed to login.');
    }
  }

  // Hiển thị thông báo khi người dùng nhấn vào icon home
  void _handleHomeButtonPress() {
    if (_isCreated) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      _showSnackbar(
          'Please! Bạn cần đăng kí mới có quyền truy cập.'); // Hiển thị thông báo yêu cầu đăng ký
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'assets/login-bg.jpg'), // Đặt đường dẫn đến ảnh nền của bạn
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  // Tab nhập key
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: 350), // Kích thước tối đa
                        child: Card(
                          elevation: 8, // Thêm đổ bóng để nổi bật
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Góc bo tròn
                          ),
                          color: const Color.fromARGB(255, 0, 0, 0).withOpacity(
                              0.4), // Đặt màu nền của Card với độ trong suốt
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 400, // Giảm chiều cao tối đa của Card
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize
                                    .min, // Điều chỉnh kích thước của Column
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  TextFormField(
                                    controller: _keyController,
                                    decoration: InputDecoration(
                                      labelText: 'Nhập key của bạn',
                                      prefixIcon:
                                          const Icon(FontAwesomeIcons.key),
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a house key';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _userNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Nhập tên người dùng',
                                      prefixIcon:
                                          const Icon(FontAwesomeIcons.user),
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your username';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _handleSubmitKey,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255,
                                          255, 107, 169), // Màu nền của nút bấm
                                      foregroundColor:
                                          Colors.white, // Màu chữ của nút bấm
                                      minimumSize:
                                          const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8), // Góc bo tròn
                                      ),
                                    ),
                                    child: const Text('Submit Key'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tab đăng ký
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: 350), // Kích thước tối đa
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: const Color.fromARGB(255, 0, 0, 0).withOpacity(
                              0.4), // Đặt màu nền của Card với độ trong suốt
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 500, // Giảm chiều cao tối đa của Card
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SingleChildScrollView(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize
                                        .min, // Điều chỉnh kích thước của Column
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      TextFormField(
                                        controller: _keyController,
                                        decoration: InputDecoration(
                                          labelText:
                                              'Tạo key để hai người đăng nhập',
                                          prefixIcon:
                                              const Icon(FontAwesomeIcons.key),
                                          border: const OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a house key';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _nameAController,
                                        decoration: InputDecoration(
                                          labelText: 'Tên của bạn',
                                          prefixIcon:
                                              const Icon(FontAwesomeIcons.user),
                                          border: const OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter Name A';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _nameBController,
                                        decoration: InputDecoration(
                                          labelText: 'Tên người ấy',
                                          prefixIcon: const Icon(
                                              FontAwesomeIcons.userAlt),
                                          border: const OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _startDateController,
                                        decoration: InputDecoration(
                                          labelText: 'Start Date (YYYY-MM-DD)',
                                          prefixIcon: const Icon(
                                              FontAwesomeIcons.calendarAlt),
                                          border: const OutlineInputBorder(),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter start date';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: _handleCreateHouse,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 255, 107, 169),
                                          foregroundColor: Colors.white,
                                          minimumSize:
                                              const Size(double.infinity, 48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Create House'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: const Color.fromARGB(255, 255, 107, 169),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Enter Key'),
                  Tab(text: 'Register'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
