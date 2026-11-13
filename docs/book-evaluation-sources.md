# Đánh giá bữa ăn và gợi ý theo hồ sơ

Nguồn đối chiếu là file `backend/LongEva.Api/docs/longo.pdf` trong dự án
(109 trang PDF). Số trang PDF khác với số trang in trong sách.

| Nội dung dùng trong ứng dụng | Trang in | Trang PDF |
|---|---:|---:|
| Chủ yếu thực vật, các loại hạt và một phần cá | 79 | 11 |
| Carbohydrate phức hợp từ đậu và thực vật | 79 | 11 |
| Hạn chế đường, chất béo bão hòa/trans | 79 | 11 |
| Bảng so sánh nguồn thực phẩm trong Mediterranean / Longevity Diet | 165–166 | 34–35 |
| Khác biệt về protein và duy trì khối cơ khoảng tuổi 65–70 | 166 | 35 |

Đây là các đoạn mô tả chế độ ăn và nghiên cứu trong sách, không phải một
thang điểm đánh giá từng bữa. Ứng dụng không còn hiển thị điểm; AI trả nhận xét
theo tiêu chí, thông tin thiếu và gợi ý cải thiện. Không suy luận lượng đường,
loại dầu, khẩu phần, tần suất hay protein hằng ngày từ một ảnh. Không áp dụng
chế độ hạn chế của người lớn cho trẻ em, hoặc tự đặt mục tiêu nhịn ăn/giảm cân.

Backend dùng danh sách nguồn do dự án quản lý tại
`backend/LongEva.Api/docs/verified-principles.json`, không tin trích dẫn mà client
gửi lên. Trường `principleId` phải khớp danh sách; tên tiêu chí, số trang và nguồn
được backend gắn lại. Tiêu chí AI không trả lời được hiển thị là chưa đủ dữ liệu.
Flutter giữ bản tương ứng trong `BookPrinciplesRepository`.

Nhận diện ảnh chỉ cung cấp danh sách dự kiến. Danh mục món là dữ liệu để tra cứu,
không phải bằng chứng món có trong ảnh. ID không khớp tên không được dùng để đổi
tên món. Tên món ghép không bị tách theo từ “và”. Khi xác nhận, AI đánh giá lại
đúng danh sách đã chỉnh sửa trước khi lưu; ảnh không rõ không tự điền món từ catalog.

Chức năng mới: **Hồ sơ → Lưu hồ sơ → AI phân tích hồ sơ và gợi ý món ăn**.
AI nhận tuổi, cân nặng, chiều cao, dị ứng, món không thích và chế độ ăn; trả nhận
xét hồ sơ, các yếu tố cân nhắc, dữ liệu còn thiếu, món chính và món thay thế theo
loại bữa. Có thể thêm món vào kế hoạch hôm nay. Bộ lọc loại bỏ xung đột rõ ràng
với hồ sơ ở cả client và backend; danh mục chưa có đầy đủ thành phần và thông tin
nhiễm chéo nên không thể bảo đảm an toàn dị ứng chỉ từ tên món.

Backend vẫn cần cấu hình Firebase và nhà cung cấp AI theo `backend/README.md`.
Android emulator sử dụng `10.0.2.2:51889`; điện thoại thật cần URL backend truy cập
được từ điện thoại, và HTTPS cho bản phát hành. Các kiểm thử dùng dịch vụ giả lập
để kiểm tra hợp đồng dữ liệu; không thay thế kiểm tra ảnh thật hoặc tài khoản thật.

Kiểm tra ngày 06/11/2026: `flutter analyze --no-pub` không báo lỗi,
`flutter test --no-pub` qua 54 kiểm thử, `dotnet test backend/LongEva.Api.Tests
--no-restore` qua 8 kiểm thử. Chưa xác minh đăng nhập/đăng xuất với tài khoản thật,
Firestore trên thiết bị hoặc độ chính xác nhận diện với ảnh thật trong lần sửa này.
