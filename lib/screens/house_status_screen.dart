import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Thư viện Font Awesome
import 'package:pure_love/services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class HouseStatusScreen extends StatefulWidget {
  final String houseId;

  const HouseStatusScreen({Key? key, required this.houseId}) : super(key: key);

  @override
  _HouseStatusScreenState createState() => _HouseStatusScreenState();
}

class _HouseStatusScreenState extends State<HouseStatusScreen> {
  late Future<List<Map<String, dynamic>>> _statusesFuture;

  @override
  void initState() {
    super.initState();
    _statusesFuture = ApiService.getStatuses();
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    timeago.setLocaleMessages('vi_short', timeago.ViShortMessages());
  }

  String _formatTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inDays > 3) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else {
      return timeago.format(createdAt, locale: 'vi');
    }
  }

  // Hàm ánh xạ nội dung trạng thái thành icon tương ứng với màu sắc
  Widget _getStatusIcon(String content) {
    final cleanedContent = content.toLowerCase().trim();

    switch (cleanedContent) {
      case 'vui vẻ':
        return Icon(
          Icons.sentiment_satisfied,
          color: Colors.yellow, // Màu vàng cho mặt cười
        );
      case 'hôm nay là một ngày tuyệt vời!':
        return Icon(
          Icons.sentiment_satisfied,
          color: Colors.yellow, // Màu vàng cho mặt cười
        );
      case 'buồn':
      case 'nhớ lắm':
        return Icon(
          Icons.sentiment_dissatisfied,
          color: Colors.blue, // Màu xanh cho mặt buồn
        );
      case 'cô đơn':
        return Icon(
          Icons.sentiment_very_dissatisfied,
          color: Colors.grey, // Màu xám cho mặt buồn
        );
      case 'phấn khích':
        return Icon(
          Icons.sentiment_very_satisfied,
          color: Colors.pink, // Màu hồng cho mặt phấn khích
        );
      case 'lo lắng':
        return Icon(
          Icons.sentiment_neutral,
          color: Colors.orange, // Màu cam cho mặt lo lắng
        );
      case 'yêu thương':
        return Icon(
          Icons.favorite,
          color: Colors.red, // Màu đỏ cho trái tim
        );
      case 'hạnh phúc':
      case 'đáng iu':
      case 'giận lắm':
        return Icon(
          Icons.sentiment_very_satisfied,
          color: Colors.yellow, // Màu vàng cho mặt hạnh phúc
        );
      case 'cook điii':
        return FaIcon(
          FontAwesomeIcons.fire,
          color: Colors.red, // Màu đỏ cho icon lửa
        );
      default:
        return Icon(
          Icons.help_outline,
          color: Colors.grey, // Màu xám cho icon mặc định
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cặp Đôi: Xíu Tình, Xíu Hài',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.pink[800],
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.pink.withOpacity(0.5),
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(250, 255, 200, 219),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/capybara.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _statusesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Chưa có trạng thái nào.'));
            } else {
              final statuses = snapshot.data!;
              return ListView.builder(
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  final member = status['member'] ?? {};
                  final createdAt = DateTime.parse(status['created_at']);
                  final content = status['content'] ?? 'Trạng thái';

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tên người gửi
                        Text(
                          member['user_name'] ?? 'Người dùng',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Nội dung trạng thái có hiệu ứng mờ và icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _getStatusIcon(content),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 0, 0, 0)
                                      .withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                    bottomLeft: Radius.zero,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(255, 0, 0, 0)
                                          .withOpacity(0),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  content,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTimeAgo(createdAt),
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
