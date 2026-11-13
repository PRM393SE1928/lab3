# Demo Firebase Crashlytics trên Android

## Yêu cầu và cách hoạt động

Người dùng nhấn nút trong Cài đặt để cố ý làm ứng dụng dừng. Crashlytics lưu báo cáo trên thiết bị và gửi khi ứng dụng được mở lại, có kết nối mạng. Firebase xử lý báo cáo bất đồng bộ nên kết quả có thể xuất hiện sau vài phút. Quản trị viên xem issue, stack trace, phiên bản và thiết bị trên web Firebase Console; dự án không tự sao chép báo cáo sang Firestore hay cung cấp một trang quản trị riêng.

## Chuẩn bị và chạy

1. Trong [Firebase Console](https://console.firebase.google.com/project/lab3-10e8a/crashlytics), chọn dự án `lab3-10e8a`, bật Crashlytics cho ứng dụng Android và đảm bảo tài khoản quản trị có quyền xem dự án.
2. Chạy `flutter pub get`, sau đó cài bản demo Android bằng `flutter run --release --dart-define=CRASHLYTICS_DEMO=true`. Thiết bị cần kết nối mạng. Cờ này chỉ hiển thị nút demo; bản build thông thường không có nút.
3. Đăng nhập, vào **Cài đặt → Thử nghiệm Crashlytics → Gây crash**. Ứng dụng sẽ đóng ngay.
4. Mở lại ứng dụng, giữ kết nối mạng, chờ vài phút rồi tải lại trang Crashlytics trong Firebase Console. Tìm issue thử nghiệm và xem chi tiết. Việc nhìn thấy lỗi trên thiết bị chưa chứng minh Firebase đã nhận báo cáo; cần xác nhận trên Console.

Nút và cấu hình báo cáo hiện chỉ hỗ trợ Android. Flutter Web không hỗ trợ Firebase Crashlytics; iOS chưa được cấu hình trong dự án. Không đưa thông tin cá nhân vào log hoặc khóa tùy chỉnh của Crashlytics.
