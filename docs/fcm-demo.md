# Demo Firebase Cloud Messaging trên Android

FCM được bật cho Android/iOS, không bật cho Flutter Web. Để kiểm tra, triển khai
`firebase/firestore.rules` lên đúng dự án Firebase; thay đổi file local không tự
thay đổi rules trên server. Cần quyền quản trị dự án để triển khai.

1. Cài app trên điện thoại thật, đăng nhập và cho phép thông báo. Máy cần có
   kết nối mạng và Google Play services. Trên Android 13 trở lên hãy kiểm tra
   quyền thông báo trong cài đặt nếu đã từ chối trước đó.
2. Trong Firestore, tìm `users/{uid}/fcmTokens`: tài liệu chứa token của thiết bị.
   Token là thông tin nhạy cảm; không đăng công khai hoặc đưa vào slide.
3. Mở Firebase Console > Messaging, tạo notification và dùng chức năng gửi
   thử đến token đó. Đưa app xuống nền để quan sát thông báo hệ thống; khi app
   đang mở, nội dung được hiển thị bằng snackbar trong app. Nhấn thông báo khi
   app đang chạy nền để mở app. Kiểm tra cả trường hợp app đã được đóng.
4. Đăng xuất và kiểm tra tài liệu token đã bị xóa khỏi người dùng; đăng nhập lại
   để đăng ký lại. Nếu thiết bị mất mạng khi đăng xuất, việc xóa có thể thất bại.

App lấy token từ Firebase Messaging SDK, lưu dưới tài khoản Firebase Auth vào
Firestore, và cập nhật khi SDK phát token mới. Firebase Console là công cụ gửi
thử ở giai đoạn này; dự án chưa có API/web admin gửi thông báo. Token cũ sau khi
refresh có thể còn trong Firestore và cần được dọn dẹp khi xây dựng server gửi.
Thông báo nền và khi app bị đóng phụ thuộc payload và hệ điều hành; thử bằng
notification message từ Firebase Console. Không suy ra data-only message luôn
được giao khi hệ điều hành đã dừng ứng dụng.

iOS cần cấu hình riêng APNs, capabilities và Firebase trước khi kiểm thử; dự án
này hiện cần xác minh và hoàn thiện cấu hình iOS. Không dùng token FCM làm ID
đăng nhập hoặc đưa service-account vào ứng dụng.
