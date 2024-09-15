import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static void initialize() {
    // Đặt mức độ ghi log cho OneSignal (tùy chọn)
    OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

    // Khởi tạo OneSignal với appId của bạn
    OneSignal.shared.setAppId("4120d7ac-40fe-40f7-b36e-573a69ce6340");

    // Yêu cầu quyền thông báo
    OneSignal.shared.promptUserForPushNotificationPermission();
  }

  // Lấy player_id
  static Future<String?> getPlayerId() async {
    var deviceState = await OneSignal.shared.getDeviceState();
    return deviceState?.userId; // Trả về player_id
  }
}
