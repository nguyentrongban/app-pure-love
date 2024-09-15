import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pure_love/services/onesignal_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl =
      'https://stalkery.click/api'; // Thay URL phù hợp với backend của bạn

  // Hàm tạo nhà
  static Future<Map<String, dynamic>?> createHouse({
    required String key,
    required String nameA,
    String? nameB,
    required String startDate,
  }) async {
    final url = Uri.parse('$_baseUrl/houses');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'key': key,
          'name_a': nameA,
          'name_b': nameB,
          'start_date': startDate,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      print('Error creating house: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> loginWithKey(
      String key, String userName) async {
    final playerId =
        await OneSignalService.getPlayerId(); // Lấy player_id từ OneSignal

    if (playerId == null) {
      print('Player ID is null');
      return null;
    }

    final url = Uri.parse('$_baseUrl/houses/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'key': key,
          'user_name': userName,
          'player_id': playerId.toString(), // Đảm bảo player_id là kiểu String
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Lưu player_id, username và house_id vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_player_id', playerId.toString());
        await prefs.setString('current_user_name', userName); // Lưu username

        // Kiểm tra xem player_id và username có được lưu vào SharedPreferences không
        final storedPlayerId = prefs.getString('current_user_player_id');
        final storedUserName = prefs.getString('current_user_name');
        print(
            'Stored Player ID: $storedPlayerId'); // In ra giá trị player_id đã lưu
        print(
            'Stored Username: $storedUserName'); // In ra giá trị username đã lưu

        if (data['house'] != null) {
          final houseId = data['house']['id'];
          await prefs.setString('house_id', houseId.toString());
        }

        return data;
      } else {
        print('Server error: ${response.body}');
        return json.decode(response.body);
      }
    } catch (e, stackTrace) {
      print('Error logging in with key: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Hàm cập nhật ảnh
  static Future<Map<String, String>?> updateImage(
      String imageType, File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final houseId = prefs.getString('house_id');
    if (houseId == null) {
      print('House ID not found in SharedPreferences.');
      return null;
    }

    final url = Uri.parse('$_baseUrl/houses/upload-image/$houseId');

    var request = http.MultipartRequest('POST', url)
      ..fields['image_type'] = imageType
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        final jsonResponse = json.decode(responseBody);
        if (response.statusCode == 200) {
          // Lấy thông tin ngôi nhà sau khi ảnh được cập nhật
          final houseDetails = await getHouseDetails(houseId);
          if (houseDetails != null) {
            return {
              'image_a': houseDetails['image_a'] ?? '',
              'image_b': houseDetails['image_b'] ?? ''
            };
          } else {
            print('Failed to fetch updated house details.');
            return null;
          }
        } else {
          print('Server returned error response: $responseBody');
          return null;
        }
      } else {
        print('Server returned non-JSON response: $responseBody');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error updating image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Phương thức lấy số ngày yêu
  static Future<Map<String, dynamic>> getLoveDays(String houseId) async {
    final response =
        await http.get(Uri.parse('$_baseUrl/houses/love-days/$houseId'));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load love days');
    }
  }

  // Phương thức lấy thông tin chi tiết ngôi nhà
  static Future<Map<String, dynamic>?> getHouseDetails(String houseId) async {
    final url = Uri.parse('$_baseUrl/houses/$houseId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load house details: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error fetching house details: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Hàm cập nhật thông tin ngôi nhà
  static Future<Map<String, dynamic>?> updateHouse({
    required String nameA,
    required String nameB,
    required String startDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final houseId = prefs.getString('house_id');
    if (houseId == null) {
      print('House ID not found in SharedPreferences.');
      return null;
    }

    final url = Uri.parse('$_baseUrl/houses/$houseId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name_a': nameA,
          'name_b': nameB,
          'start_date': startDate,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Server error: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error updating house: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final houseId = prefs.getString('house_id');
    final currentUserPlayerId = prefs.getString('current_user_player_id');

    if (houseId == null) {
      print('House ID not found in SharedPreferences.');
      return null;
    }

    if (currentUserPlayerId == null) {
      print('Current User Player ID not found in SharedPreferences.');
      return null;
    }

    final url = Uri.parse('$_baseUrl/notifications/send-notification');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'house_id': houseId,
          'current_user_player_id':
              currentUserPlayerId, // Thêm current_user_player_id vào body
        }),
      );

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          print('Failed to decode JSON: $e');
          print('Response body: ${response.body}');
          return null;
        }
      } else {
        print('Server error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error sending notification: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<void> saveStatus(String content) async {
    final prefs = await SharedPreferences.getInstance();
    final houseId = prefs.getString('house_id');
    final userName = prefs.getString(
        'current_user_name'); // Đổi tên biến từ 'username' thành 'userName'

    if (houseId == null || userName == null) {
      print('Không tìm thấy houseId hoặc userName trong bộ nhớ đệm.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/statuses/post'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'house_id': houseId,
          'user_name': userName, // Sửa tên trường ở đây
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        print('Trạng thái đã được lưu thành công');
      } else {
        print('Lỗi khi lưu trạng thái: ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi gửi yêu cầu: $e');
    }
  }

  // Hàm lấy trạng thái của ngôi nhà
  static Future<List<Map<String, dynamic>>> getStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final houseId = prefs.getString('house_id');

    if (houseId == null) {
      print('House ID not found in SharedPreferences.');
      return []; // Trả về danh sách rỗng thay vì null
    }

    final url = Uri.parse('$_baseUrl/statuses/$houseId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print(
            'Response body: ${response.body}'); // Log dữ liệu nhận được từ API
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        print('Server error: ${response.statusCode} - ${response.body}');
        return []; // Trả về danh sách rỗng thay vì null
      }
    } catch (e) {
      print('Error fetching statuses: $e');
      return []; // Trả về danh sách rỗng thay vì null
    }
  }
}
