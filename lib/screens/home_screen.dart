import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pure_love/screens/house_status_screen.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pure_love/services/api_service.dart'; // Import ApiService
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _imageFileA;
  File? _imageFileB;
  String _loveDays = '0';
  double _previousLoveDays = 0; // Lưu giá trị trước đó để so sánh
  String _nameA = '';
  String _nameB = '';
  String? _imageUrlA;
  String? _imageUrlB;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _fetchLoveDays();

    // Khởi tạo AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(); // Lặp lại animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchLoveDays() async {
    final houseId = await _getHouseId();
    if (houseId == null) {
      _showSnackBar('Không tìm thấy thông tin nhà.');
      return;
    }

    await _fetchHouseDetails(houseId);
    await _fetchLoveDaysFromApi(houseId);
  }

  Future<void> _fetchHouseDetails(String houseId) async {
    try {
      final response = await ApiService.getHouseDetails(houseId);
      if (response != null) {
        final nameA = response['name_a'] ?? 'User A';
        final nameB = response['name_b'] ?? 'User B';
        final imageUrlA = response['image_a'] as String?;
        final imageUrlB = response['image_b'] as String?;

        setState(() {
          _nameA = nameA;
          _nameB = nameB;
          _imageUrlA = imageUrlA;
          _imageUrlB = imageUrlB;
        });
      } else {
        _showSnackBar('Dữ liệu không hợp lệ.');
      }
    } catch (e) {
      _showSnackBar('Có lỗi xảy ra khi lấy thông tin nhà.');
    }
  }

  Future<void> _fetchLoveDaysFromApi(String houseId) async {
    try {
      final response = await ApiService.getLoveDays(houseId);
      if (response.containsKey('love_days')) {
        final loveDays = response['love_days'] ?? 0;
        setState(() {
          _loveDays = loveDays.toString();
        });
      } else {
        _showSnackBar('Không tìm thấy số ngày yêu.');
      }
    } catch (e) {
      _showSnackBar('Có lỗi xảy ra khi lấy số ngày yêu.');
    }
  }

  Future<void> _pickImage(String imageType) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (imageType == 'image_a') {
          _imageFileA = File(pickedFile.path);
        } else {
          _imageFileB = File(pickedFile.path);
        }
      });

      await _updateImage(imageType);
    }
  }

  Future<String?> _getHouseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('house_id');
  }

  Future<void> _updateImage(String imageType) async {
    final houseId = await _getHouseId();
    if (houseId == null) {
      _showSnackBar('Không tìm thấy thông tin nhà.');
      return;
    }

    final imageFile = imageType == 'image_a' ? _imageFileA : _imageFileB;
    if (imageFile == null) {
      _showSnackBar('Vui lòng chọn ảnh trước.');
      return;
    }

    try {
      final response = await ApiService.updateImage(imageType, imageFile);
      if (response != null) {
        setState(() {
          if (imageType == 'image_a') {
            _imageUrlA = response['image_a'];
            _imageFileA = null;
          } else {
            _imageUrlB = response['image_b'];
            _imageFileB = null;
          }
        });

        await _fetchHouseDetails(houseId);
        _showSnackBar('Ảnh đã được cập nhật thành công!');
      } else {
        _showSnackBar('Có lỗi xảy ra khi cập nhật ảnh.');
      }
    } catch (e) {
      _showSnackBar('Có lỗi xảy ra khi cập nhật ảnh.');
    }
  }

  Future<void> _showSettingsDialog() async {
    final nameControllerA = TextEditingController(text: _nameA);
    final nameControllerB = TextEditingController(text: _nameB);
    final startDateController = TextEditingController();

    final prefs = await SharedPreferences.getInstance();
    final startDate = prefs.getString('start_date');
    startDateController.text = startDate ?? '';

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cài đặt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameControllerA,
                decoration:
                    const InputDecoration(labelText: 'Tên người dùng A'),
              ),
              TextField(
                controller: nameControllerB,
                decoration:
                    const InputDecoration(labelText: 'Tên người dùng B'),
              ),
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: startDate != null
                        ? DateTime.parse(startDate)
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );

                  if (pickedDate != null && pickedDate != DateTime.now()) {
                    startDateController.text =
                        pickedDate.toLocal().toString().split(' ')[0];
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Ngày bắt đầu',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType:
                        TextInputType.none, // Disable keyboard for this field
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Lưu'),
              onPressed: () async {
                final nameA = nameControllerA.text;
                final nameB = nameControllerB.text;
                final startDate = startDateController.text;

                try {
                  final response = await ApiService.updateHouse(
                    nameA: nameA,
                    nameB: nameB,
                    startDate: startDate,
                  );

                  if (response != null) {
                    setState(() {
                      _nameA = nameA;
                      _nameB = nameB;
                      _loveDays = response['love_days'].toString();
                    });

                    Navigator.of(context).pop();
                    _showSnackBar('Cài đặt đã được cập nhật thành công!');
                  } else {
                    _showSnackBar('Có lỗi xảy ra khi cập nhật cài đặt.');
                  }
                } catch (e) {
                  _showSnackBar('Có lỗi xảy ra khi cập nhật cài đặt.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  final ApiService _apiService = ApiService(); // Tạo đối tượng ApiService

  Future<void> _sendNotification() async {
    final result =
        await _apiService.sendNotification(); // Gọi phương thức từ ApiService
    if (result != null) {
      // Xử lý kết quả từ sendNotification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send notification.')),
      );
    }
  }

  void _handleStatusSelection(String status) async {
    // Gọi hàm saveStatus để lưu trạng thái
    await ApiService.saveStatus(status);
  }

  void _showStatusDialog() {
    String selectedStatus = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn trạng thái'),
          content: SingleChildScrollView(
            // Thêm SingleChildScrollView ở đây để cho phép cuộn
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.sentiment_very_dissatisfied,
                      color: const Color.fromARGB(255, 245, 241, 29)),
                  title: Text('Vui vẻ'),
                  onTap: () {
                    selectedStatus = 'Cô đơn';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.sentiment_dissatisfied),
                  title: Text('Buồn bã'),
                  onTap: () {
                    selectedStatus = 'Buồn bã';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.sentiment_dissatisfied),
                  title: Text('Nhớ lắm'),
                  onTap: () {
                    selectedStatus = 'Nhớ lắm';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.sentiment_very_dissatisfied,
                      color: Colors.grey),
                  title: Text('Cô đơn'),
                  onTap: () {
                    selectedStatus = 'Cô đơn';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.sentiment_very_satisfied,
                      color: const Color.fromARGB(255, 14, 216, 64)),
                  title: Text('Phấn khích'),
                  onTap: () {
                    selectedStatus = 'Phấn khích';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.sentiment_neutral, color: Colors.orange),
                  title: Text('Lo lắng'),
                  onTap: () {
                    selectedStatus = 'Lo lắng';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.favorite, color: Colors.red),
                  title: Text('Yêu thương'),
                  onTap: () {
                    selectedStatus = 'Yêu thương';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.sentiment_very_satisfied,
                      color: const Color.fromARGB(255, 255, 59, 216)),
                  title: Text('Hạnh phúc'),
                  onTap: () {
                    selectedStatus = 'Hạnh phúc';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.sentiment_very_satisfied,
                      color: const Color.fromARGB(255, 255, 32, 32)),
                  title: Text('Đáng iu'),
                  onTap: () {
                    selectedStatus = 'Đáng iu';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.sentiment_very_satisfied,
                      color: const Color.fromARGB(255, 208, 0, 0)),
                  title: Text('Giận lắm'),
                  onTap: () {
                    selectedStatus = 'Giận lắm';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_fire_department,
                      color: const Color.fromARGB(255, 248, 43, 43)),
                  title: Text('Cook điii'),
                  onTap: () {
                    selectedStatus = 'Cook điii';
                    Navigator.of(context).pop();
                    _handleStatusSelection(selectedStatus);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double loveDays;
    try {
      loveDays = double.parse(_loveDays);
    } catch (e) {
      loveDays = 0;
    }

    // Tính toán số ngày đã trôi qua kể từ ngày 0
    int daysSinceStart = (loveDays % 10).toInt();

    // Tính toán giá trị progress dựa trên số ngày yêu và chu kỳ 10 ngày hiện tại
    double progress = daysSinceStart / 10;

    // Kiểm tra nếu số ngày yêu là bội số của 10 và có thể cần cập nhật lại
    bool isMultipleOfTen = (loveDays % 10 == 0) && (loveDays > 0);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        title: const Text('Pure Love',
            style: TextStyle(
                color: Color.fromARGB(255, 255, 64, 129),
                fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings,
                color: Color.fromARGB(255, 255, 64, 129)),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.list,
                color: Color.fromARGB(255, 255, 64, 129)),
            onPressed: () async {
              // Lấy houseId từ SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final houseId = prefs.getString('houseId') ??
                  'houseId'; // Thay 'default_house_id' bằng giá trị mặc định nếu cần

              // Điều hướng đến trang trạng thái
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HouseStatusScreen(
                    houseId: houseId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Nội dung chính
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Vòng tròn đếm ngày yêu
                GestureDetector(
                  onTap: _sendNotification,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: screenWidth * 0.6,
                        height: screenWidth * 0.6,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_loveDays ngày',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          const Text(
                            'Gặp nhau của chúng ta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Hàng chứa ảnh đại diện và tên
                Padding(
                  padding: const EdgeInsets.only(top: 150.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cột cho ảnh đại diện và tên của người dùng A
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _pickImage('image_a'),
                            child: CircleAvatar(
                              backgroundImage: _imageUrlA != null
                                  ? NetworkImage(_imageUrlA!)
                                  : null,
                              radius: screenWidth * 0.15,
                              child: _imageUrlA == null
                                  ? const Icon(Icons.camera_alt,
                                      size: 30, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _nameA,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 100),
                      // Cột cho ảnh đại diện và tên của người dùng B
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _pickImage('image_b'),
                            child: CircleAvatar(
                              backgroundImage: _imageUrlB != null
                                  ? NetworkImage(_imageUrlB!)
                                  : null,
                              radius: screenWidth * 0.15,
                              child: _imageUrlB == null
                                  ? const Icon(Icons.camera_alt,
                                      size: 30, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _nameB,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Hiển thị hoạt ảnh pháo hoa nếu số ngày yêu là bội số của 10
          if (isMultipleOfTen)
            Positioned(
              top: screenHeight *
                  0.2, // Điều chỉnh giá trị này để thay đổi vị trí cao thấp
              left: 0,
              right: 0,
              child: SizedBox(
                width: screenWidth,
                height: screenHeight *
                    0.5, // Chiều cao điều chỉnh cho hiệu ứng phù hợp
                child: Lottie.asset(
                  'assets/animation/fireworks.json', // Đường dẫn đến file JSON của hoạt ảnh Lottie
                  repeat: false,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
      // Nút dấu +
      floatingActionButton: FloatingActionButton(
        onPressed: _showStatusDialog, // Thay hàm xử lý sự kiện khi bấm nút
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .endFloat, // Đặt vị trí của nút ở góc phải cuối màn hình
    );
  }
}
