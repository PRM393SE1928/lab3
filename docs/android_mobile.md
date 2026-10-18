# Chạy Longeva trên điện thoại Android

Project là ứng dụng Flutter Android, không cần máy chủ web hay localhost.
Phần Member 2 dùng màn hình đổi món toàn màn hình, danh sách cuộn và nút xác nhận
ở dưới; các màn kết quả/gợi ý có SafeArea để tránh thanh điều hướng hệ thống.

## Chạy từ source

Mở Android Studio > Device Manager và khởi động máy ảo Android, hoặc kết nối
điện thoại Android bằng USB, bật USB debugging và chấp nhận kết nối trên máy.

Trong PowerShell:

```powershell
cd D:\FlutterTutorial\flutter_application_1\flutter_application_2
flutter pub get
flutter devices
flutter run -d <device-id>
```

Thay `<device-id>` bằng ID Android trong danh sách (ví dụ `emulator-5554`).

## Xuất APK để cài thử

```powershell
flutter build apk --debug
```

File tạo ra: `build\app\outputs\flutter-apk\app-debug.apk`.
Đây là APK thử nghiệm, chưa phải bản ký phát hành trên Play Store.

## Luồng kiểm thử Member 2

Nhật ký > chọn bữa ăn > kết quả > gợi ý hoặc đổi món > đánh giá lại.
Nút Back/đóng/Hủy ở màn đổi món không thay đổi bữa ăn.
Kiểm tra màn hình dọc, ngang và cỡ chữ lớn trong cài đặt điện thoại.
Dữ liệu hiện vẫn chỉ giữ trong phiên chạy theo thiết kế project gốc.

Repo hiện chỉ có Android. Build iOS cần bổ sung cấu hình iOS và máy macOS/Xcode;
phần giao diện Flutter của Member 2 có thể tái sử dụng.

## Mobile verification

Flutter analysis passed and all 20 existing tests passed after the mobile UI changes.
Two additional tests passed for 320x640 portrait and 640x320 landscape at 150% text
scale, including list scrolling, fixed submit controls and Android system Back.

APK build was attempted but the Gradle distribution download stalled with a
zero-byte partial file. That build process was stopped. No APK or device-run
verification is claimed; complete the Gradle download before building locally.
