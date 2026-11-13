# LONGEVA — Báo cáo audit kỹ thuật

Ngày: 09/11/2026. Phạm vi: snapshot workspace hiện tại, bao gồm các thay đổi chưa commit. `CONFIRMED` nghĩa là hành vi được xác minh trong mã hoặc test; không đồng nghĩa đã chạy thành công trên môi trường thật. `OBSERVED` là kết quả lệnh; `SUSPECTED` cần tái hiện; `NOT_TESTED` chưa kiểm tra; `BLOCKED` không có môi trường hoặc công cụ. Đây là audit có giới hạn, không phải chứng nhận bảo mật hay xác nhận toàn bộ màn hình và nghiệp vụ.

## 1. Executive Summary

LONGEVA đã có nền tảng prototype khá rộng: đăng nhập Firebase, nhật ký, hồ sơ, kế hoạch, danh sách mua sắm, đọc bài, phân tích và gợi ý AI đều có implementation. Các luồng được mô tả dưới đây là xác minh mã, chưa chứng minh hoạt động đầu cuối với dịch vụ thật. Chưa đủ bằng chứng để triển khai sản phẩm sức khỏe công khai: lưu dữ liệu có thể báo thành công trước khi ghi xong, có kết quả AI cũ trên màn hình sau khi thay lựa chọn, thiếu giới hạn sử dụng backend và chưa xác thực quy tắc Firestore đang triển khai.

Backend build thành công và 12 test backend đạt. Ba lệnh Flutter không tạo output và bị dừng sau khi chờ; không thể công bố kết quả analyze, test hay build web. Không truy cập Firestore thật, không gọi AI thật, không deploy hoặc sửa source/dữ liệu.

## 2. Architecture Overview

- **CONFIRMED:** Flutter tổ chức theo feature, `provider`/`ChangeNotifier`, `go_router`; `LongevaBootstrap` theo dõi Firebase Auth và tạo app theo UID ([main.dart](lib/main.dart), [app.dart](lib/app.dart), [app_router.dart](lib/core/router/app_router.dart)). `AppState` giữ nhiều loại dữ liệu và logic; repository Firestore kế thừa mock để dùng catalog/nội dung mẫu ([app_state.dart](lib/shared/services/app_state.dart), [firestore_repository.dart](lib/shared/services/firestore_repository.dart)).
- **CONFIRMED:** Backend minimal API .NET 8, Firebase Admin 3.4.0; test project .NET 10 xUnit; Flutter SDK constraint Dart ^3.13.3, Firebase, provider, go_router, http và image_picker ([pubspec.yaml](pubspec.yaml), [LongEva.Api.csproj](backend/LongEva.Api/LongEva.Api.csproj)). Backend gom routing, validation và HTTP response trong [Program.cs](backend/LongEva.Api/Program.cs); orchestration, prompt và hai provider nằm trong [GeminiService.cs](backend/LongEva.Api/GeminiService.cs). Không thấy controller/repository backend, OpenAPI hoặc versioning trong mã đã kiểm tra.
- **CONFIRMED:** Firestore truy cập trực tiếp từ client; AI qua backend, token Firebase gửi bằng Bearer. Có phân lớp nhưng UI vẫn điều phối request và lưu, state tập trung nhiều trách nhiệm; không cần đại tu ngay, nên tách dần ranh giới theo use case sau khi sửa tính đúng đắn.

### Hợp đồng API đã truy vết

| Method / endpoint | Client | Backend / hợp đồng | Đánh giá |
|---|---|---|---|
| GET `/health` | Chưa thấy client gọi | `Program.cs`: trả status | CONFIRMED có route; NOT_TESTED runtime |
| POST `/api/ai/meal-evaluation` | `meal_photo_analyzer.dart` | multipart `image`, `mealType`, `profile`, `principles`, `catalog`; Bearer; ảnh tối đa 10 MB | CONFIRMED có kiểm tra magic bytes, response parse JSON; ảnh thật NOT_TESTED |
| POST `/api/ai/meal-evaluation/manual` | `analyzeFoods` cùng service | JSON `mealType`, `confirmedFoods`, profile/principles dạng chuỗi; không yêu cầu ảnh | CONFIRMED chung `EvaluateAsync`; thành công với provider thật NOT_TESTED |
| POST `/api/ai/meal-recommendations` | `ai_meal_recommendation_service.dart` | JSON profile, targetAgeGroup, mealType, catalog; Bearer; profile, mealType, catalog bắt buộc | CONFIRMED DTO tương ứng; 400 lịch sử không đủ log để xác định nguyên nhân |

Client timeout 30 giây; backend tổng ngân sách AI 24 giây, retry Gemini tối đa hai lần cho lỗi unavailable rồi có thể fallback Groq. Client không có retry/cancellation rõ ràng. Backend bỏ qua principles client và dùng danh sách server; `verifiedPrinciples` client gửi là dư. Recommendations gửi `weightKg`/`heightCm` và prompt vẫn đưa vào: báo cáo trước đây rằng đã loại bỏ là **không đúng với snapshot**. Sai lệch khác của response với mọi trường hợp chưa được kiểm thử hợp đồng đầy đủ.

## 3. Module Audit

### Frontend, UX và nghiệp vụ

- **CONFIRMED:** Có gate đăng nhập, loading/error khởi tạo và hydrate, chọn/chỉnh sửa món, lưu nhật ký, xem kết quả, lập kế hoạch, danh sách mua sắm, hồ sơ, bài đọc và cài đặt. Xem [auth_screen.dart](lib/features/auth/screens/auth_screen.dart), [meal_photo_analysis_screen.dart](lib/features/meal_evaluation/screens/meal_photo_analysis_screen.dart), [meal_planner_screen.dart](lib/features/meal_planner/screens/meal_planner_screen.dart). Có cơ chế kẹp `viewInsets` âm tại [main.dart](lib/main.dart) và [app.dart](lib/app.dart); không chứng minh cảnh báo lịch sử đã hết trên mọi thiết bị.
- **CONFIRMED:** Ảnh gửi đến AI để nhận diện ban đầu; danh sách được sửa/xác nhận rồi gọi `analyzeFoods` lại trước khi lưu. Món không khớp catalog vẫn được tạo theo tên; danh sách loại trùng ID ([meal_photo_analysis_screen.dart:412](lib/features/meal_evaluation/screens/meal_photo_analysis_screen.dart#L412)). Trạng thái confidence có trong model nhưng cần đánh giá UI và chất lượng ảnh thực tế.
- **CONFIRMED:** Một số file lớn: analyzer ~25 KB, photo screen ~25 KB, state ~23 KB, planner screen ~21 KB. Có logic ứng dụng trong UI và `AppState`; `ChangeNotifier` rộng có thể tạo rebuild không cần thiết (**SUSPECTED**, chưa profile). Controllers và router có dispose trong các chỗ đã kiểm tra.
- **NOT_TESTED:** responsive, accessibility, overflow, Noto Fonts, camera/Android, web, toàn bộ đường đi đăng ký/đăng nhập và lỗi UI thực tế. Không suy luận lỗi console cũ vẫn tồn tại.

### AI và an toàn

- **CONFIRMED:** Gemini được gọi trước; Groq chỉ được thử khi có key và Gemini ném unavailable, rate limit hoặc provider error; thiếu cấu hình Gemini không kích hoạt fallback ([GeminiService.cs:145](backend/LongEva.Api/GeminiService.cs#L145)). Cả hai hỗ trợ ảnh trong code. Không có bằng chứng đã cấu hình hoặc khả dụng thật; không thấy ghi token usage.
- **CONFIRMED:** AI có thể trả JSON tự do; server kiểm tra object/list và khôi phục citation từ whitelist ID, bổ sung trạng thái thiếu dữ liệu, bỏ điểm ([GeminiService.cs:73](backend/LongEva.Api/GeminiService.cs#L73)). Không kiểm chứng nội dung lý do, lời khuyên hay an toàn y khoa bằng bộ kiểm định độc lập. Prompt có hướng dẫn không hạn chế ăn/giảm cân cho trẻ, nhưng prompt không phải bảo đảm thực thi.
- **CONFIRMED:** Recommendation lọc catalog và danh mục trả về, áp dụng độ tuổi và `CatalogPolicy`; catalog thiếu thông tin thành phần/nhiễm chéo nên không thể bảo đảm dị ứng. Client tự cảnh báo giới hạn này ([ai_meal_recommendation_service.dart](lib/features/user_progress/services/ai_meal_recommendation_service.dart)).
- **SUSPECTED:** Timeout tổng 24 giây có thể hết trước khi Groq có thời gian trả sau nhiều lần retry; cần test thời gian và lỗi thực tế. Không có bằng chứng gọi song song không cần thiết.

### Dữ liệu sách

**CONFIRMED:** [verified-principles.json](backend/LongEva.Api/docs/verified-principles.json) có 5 mục gắn `BOOK_VERIFIED`: 3 mục Chapter 4, 2 mục Chapter 9; trích trang in 79, 165–166 và PDF 11, 34–35. Bản Dart trùng lặp dữ liệu ở [book_principle.dart](lib/features/meal_evaluation/models/book_principle.dart); enum có ba loại nguồn nhưng whitelist backend hiện là sách. Server gắn lại trang/nguồn từ ID hợp lệ, giảm giả mạo citation, nhưng lời giải thích vẫn do AI sinh. Hai mục về nguồn thực phẩm có phạm vi gần nhau, không đủ cơ sở kết luận trùng hoàn toàn. Một số tiêu chí diễn đạt chế độ dài hạn chứ không chứng minh phù hợp từng bữa.

**NOT_TESTED:** Chưa đọc trực tiếp các trang PDF và chưa xác minh độc lập số trang, diễn giải hoặc tổng số chương cuốn sách; số 109 trang là tài liệu dự án báo cáo, không phải phép đo audit. Chỉ có thể nói kho hiện có hai nhãn chương, không nói đã khai thác toàn sách. Cần kiểm duyệt chuyên môn, nguồn trang in/PDF và version dữ liệu trước khi mở rộng; dùng một nguồn chuẩn có version cho cả client/server. Không biến nội dung nhịn ăn, FMD, giảm cân hoặc hạn chế năng lượng thành mục tiêu cho trẻ.

### Firebase và dữ liệu

**CONFIRMED:** [firestore_repository.dart:29](lib/shared/services/firestore_repository.dart#L29) đặt dữ liệu dưới `users/{uid}`; collections `meals`, `mealPlans`, `aiMealAnalyses`, `readingProgress`, `settings`, `shopping`, `health_profile/current`. Hydrate đọc lại nhiều collection; update/delete meal dùng batch xóa analysis khi được yêu cầu; analysis dùng document ID meal nên mỗi meal chỉ giữ một bản hiện tại. [firestore.rules](firebase/firestore.rules) yêu cầu UID chủ sở hữu và mặc định từ chối đường dẫn không khớp. Rules cho phép chủ sở hữu ghi nhiều loại document với ít validation schema.

**BLOCKED:** Rules đang deploy, phân quyền tài khoản thật, indexes, offline/sync đa thiết bị, quota Spark, document size, trùng ghi, khôi phục sau restart và cách xử lý đổi tài khoản chưa được xác minh bằng emulator/thiết bị. Firebase Storage không cần thiết cho đề xuất này. `loadUserData` đọc tuần tự toàn bộ collection; chi phí và độ trễ tăng theo dữ liệu (**SUSPECTED**, chưa đo).

### Security, deployment

**CONFIRMED:** API dùng Firebase Admin `VerifyIdTokenAsync` ([FirebaseTokenVerifier.cs:17](backend/LongEva.Api/FirebaseTokenVerifier.cs#L17)); cơ chế kiểm tra chữ ký/issuer/audience/expiry dựa SDK, chưa kiểm thử token thực và revocation. CORS cho mọi origin/header/method; không thấy rate limiting trong [Program.cs:17](backend/LongEva.Api/Program.cs#L17). CORS rộng không tự vượt qua Bearer, nhưng không hạn chế origin. Endpoint client mặc định HTTP localhost hoặc emulator; cần cấu hình HTTPS thực tế. Không công bố giá trị cấu hình nhạy cảm. Chưa kiểm tra toàn bộ lịch sử Git hoặc secret manager; không khẳng định không có secret.

**BLOCKED:** Hosting production, TLS, CORS thực tế, Firebase Auth providers, giám sát, backups, rules deploy, package vulnerability và cấu hình release. Backend hiện trả nội dung lỗi provider trong một số `Problem` response; cần đánh giá redaction. Chưa đủ bằng chứng tuyên bố Firebase/backend an toàn.

## 4. Confirmed Issues

| ID | Mức | Vị trí | Nguyên nhân và ảnh hưởng | Hướng xử lý |
|---|---|---|---|---|
| C01 | P1 | [app_state.dart:431](lib/shared/services/app_state.dart#L431), [meal_photo_analysis_screen.dart:481](lib/features/meal_evaluation/screens/meal_photo_analysis_screen.dart#L481) | Ghi Firestore chạy bất đồng bộ sau cập nhật state/chuyển trang; `lastPersistenceError` chỉ được gán, không có UI consumer trong mã đã tìm. Lỗi ghi có thể khiến người dùng tưởng đã lưu và mất dữ liệu sau reload. Meal và analysis là hai write riêng. | Trả Future kết quả, biểu thị pending/failure/retry; giao dịch/batch cho meal+analysis khi phù hợp; test lỗi mạng và đổi tài khoản. |
| C02 | P1 | [meal_photo_analysis_screen.dart:121](lib/features/meal_evaluation/screens/meal_photo_analysis_screen.dart#L121), [meal_photo_analysis_screen.dart:300](lib/features/meal_evaluation/screens/meal_photo_analysis_screen.dart#L300) | Thay/xóa món hoặc lỗi lần phân tích tiếp theo không xóa `_result`; card cũ vẫn xuất hiện cạnh danh sách mới. Khi lưu có đánh giá lại nên không khẳng định dữ liệu cũ được lưu, nhưng feedback đang gây hiểu nhầm. | Invalidate kết quả khi đổi đầu vào/loại bữa và khi bắt đầu request; test thất bại và thay lựa chọn. |
| C03 | P1 | [GeminiService.cs:427](backend/LongEva.Api/GeminiService.cs#L427), [ai_meal_recommendation_service.dart](lib/features/user_progress/services/ai_meal_recommendation_service.dart) | Cân nặng/chiều cao vẫn được gửi và đưa vào prompt gợi ý, trái trạng thái mong đợi đã nêu; tăng dữ liệu nhạy cảm chuyển provider. | Loại khỏi request/prompt khi không có mục đích cần thiết; test payload và prompt. |
| C04 | P1 | [Program.cs:17](backend/LongEva.Api/Program.cs#L17) | Không có rate limit ở các endpoint AI; người có token hợp lệ có thể tạo nhiều yêu cầu tiêu tốn quota. | Rate limit theo UID/IP, giới hạn kích thước và giám sát phù hợp hosting; không yêu cầu Blaze. |
| C05 | P2 | [meal_photo_analysis_screen.dart:141](lib/features/meal_evaluation/screens/meal_photo_analysis_screen.dart#L141), [meal_photo_analysis_screen.dart:469](lib/features/meal_evaluation/screens/meal_photo_analysis_screen.dart#L469) | Luồng thủ công đánh giá để hiện card rồi đánh giá lại khi lưu kể cả không sửa đầu vào; ảnh cũng có hai lần gọi theo thiết kế nhận diện rồi xác nhận. Tăng độ trễ/chi phí; kết quả hai lần có thể khác. | Cache kết quả theo phiên bản đầu vào xác nhận, chỉ đánh giá lại khi cần; giữ xác nhận người dùng. |
| C06 | P2 | [GeminiService.cs:254](backend/LongEva.Api/GeminiService.cs#L254) | Parser dùng `GetProperty`/index nhưng chỉ bắt `JsonException`; envelope hợp lệ thiếu key hoặc list rỗng có thể ném exception khác và thành 500 thay vì lỗi provider có kiểm soát. | Validate envelope đầy đủ và test response rỗng/bị chặn. |
| C07 | P2 | [firestore_repository.dart:32](lib/shared/services/firestore_repository.dart#L32) | Khi không có user, `_write` return thành công mà không ghi; caller không nhận thất bại. | Trả lỗi rõ ràng hoặc kết quả typed; kiểm thử logout khi ghi. |
| C08 | P2 | [GeminiService.cs:153](backend/LongEva.Api/GeminiService.cs#L153) | Thiếu cấu hình Gemini luôn rethrow ngay cả khi Groq có key. Fallback chỉ hoạt động cho các lỗi khác. | Quyết định chính sách thiếu cấu hình rõ ràng, kiểm thử cả trường hợp chỉ có Groq. |
| C09 | P2 | [app_state.dart:191](lib/shared/services/app_state.dart#L191) | `weeklyProgress.averageScore` luôn bằng 0; không nên diễn giải như điểm đo thật. | Bỏ trường/nhãn điểm hoặc thay bằng metric có định nghĩa và dữ liệu. |

Chưa xác nhận P0 từ bằng chứng hiện có; điều này không chứng minh không có P0.

## 5. Suspected Issues

- **SUSPECTED P1:** `_userRef` đọc `currentUser` động trong các tác vụ bất đồng bộ; cần test chuyển tài khoản giữa hydrate/write để xác định race hoặc sai lệch. Không có bằng chứng đã xảy ra rò rỉ chéo UID.
- **SUSPECTED P1:** Chỉ dựa vào prompt để bảo vệ trẻ em và kiểm soát dị ứng có thể không đủ; cần red-team response và kiểm định chuyên môn. Không khẳng định provider đã tạo lời khuyên nguy hiểm.
- **SUSPECTED P2:** Fallback có thể bị hết ngân sách thời gian sau retry; danh mục/matching tên có thể bỏ sót dị ứng hoặc đồng nhất hai món cùng tên. Cần test dữ liệu thực và đo.
- **NOT_TESTED:** Lỗi HTTP 400 trước đây, Noto Fonts, overflow, serialization thực tế, chi phí, memory leak và độ trễ. Không có log hoặc môi trường để kết luận hiện tại.

## 6. Missing Features

- **CONFIRMED:** Cài đặt nhắc nhở được lưu trong state/Firestore, nhưng chưa thấy dependency/lịch trình thông báo cục bộ trong các file đã kiểm tra; giao hàng thông báo **NOT_TESTED**. Không coi toggle là bằng chứng notification hoạt động.
- **CONFIRMED:** Analysis lưu theo meal ID, ghi đè bản trước; không phải lịch sử nhiều phiên/so sánh longitudinal. `shopping/current` là một document duy nhất, chưa chứng minh có tổng hợp nguyên liệu có định lượng.
- **NOT_TESTED:** Toàn bộ chức năng khác không thể xếp là hoàn chỉnh hay chỉ UI nếu chưa chạy luồng; xác minh bằng test end-to-end trên emulator và thiết bị trước khi gắn nhãn.

## 7. Improvement Opportunities

1. Tách use case lưu, xác nhận, AI và đồng bộ khỏi widget; giảm trách nhiệm `AppState`; định nghĩa repository interface không phụ thuộc subclass mock.
2. Tạo contract tests cho nullable, JSON sai kiểu, lỗi 400/401/429/502/503, timeout, 2 provider và không có ảnh; thêm emulator rules tests, offline và account switch.
3. Pagination và song song hóa đọc phù hợp, theo dõi dung lượng `shopping/current`; đo trước khi tối ưu. Cân nhắc `HttpClient` DI vì `AddHttpClient<GeminiService>` và đăng ký singleton cùng loại cùng tồn tại; xác minh lifecycle thực tế.
4. Giới hạn input từng trường/catalog, structured logging không chứa dữ liệu sức khỏe, rate limit, cấu hình HTTPS/origin theo môi trường. Thêm OpenAPI nếu phục vụ contract và release.
5. Xây dựng pipeline nguồn sách versioned, kiểm định trang và an toàn theo độ tuổi; phân biệt dữ liệu sách với lời khuyên tổng quát. Không tin citation hoặc câu trả lời tự do chỉ vì JSON hợp lệ.

## 8. New Feature Recommendations

Độ phức tạp là ước lượng tương đối, không phải cam kết. Tất cả cần khả năng sửa/xác nhận, không chẩn đoán hoặc hướng dẫn hạn chế năng lượng/nhịn ăn cho trẻ.

| Tính năng / ưu tiên | Vấn đề, cách hoạt động và giá trị | Phức tạp; module, phụ thuộc; rủi ro |
|---|---|---|
| H. Dị ứng và sở thích / P1 | Một hồ sơ có cấu trúc dùng xuyên suốt lựa chọn, đánh giá và gợi ý; cảnh báo khi thiếu thành phần. | Cao; profile, catalog, AI; taxonomy và review chuyên môn; nhiễm chéo không được bảo đảm. |
| E. Catalog thống nhất / P1 | ID, tên đồng nghĩa, thành phần và provenance dùng cho nhận diện/gợi ý, người dùng xác nhận; giảm lệch mapping. | Cao; catalog, editor, AI, data; cần dữ liệu được quản trị; sai mapping gây rủi ro dị ứng. |
| I. Nhật ký thông minh / P2 | Tìm/lặp món đã ăn và xác nhận nhanh, giảm nhập lại. | Vừa; diary, repository, search; quyền riêng tư và trùng tên. |
| D. Shopping list / P2 | Tổng hợp nguyên liệu kế hoạch và cho sửa trước khi lưu; giảm mua trùng. | Vừa; planner, catalog, shopping; cần đơn vị/định lượng đáng tin, không suy đoán. |
| C. Kế hoạch cá nhân / P2 | Gợi ý kế hoạch theo tuổi, dị ứng, sở thích và loại bữa trong catalog; user duyệt. | Cao; planner, AI, catalog; taxonomy, kiểm định; không hứa an toàn tuyệt đối. |
| F. Trung tâm kiến thức / P2 | Tra nguyên tắc đã kiểm chứng, chương/trang và giải thích; giúp kiểm tra nguồn. | Vừa; knowledge, book data; bản quyền và rà soát trang, chuyên gia. |
| G. Lịch sử đánh giá / P2 | Lưu phiên có version nguồn và so sánh theo thời gian; giúp theo dõi thay đổi. | Vừa; Firestore schema, AI, UI; lưu tăng và so sánh thiếu dữ liệu có thể gây hiểu nhầm. |
| B. Phân tích lịch sử / P2 | Thống kê đa dạng món và tần suất từ nhật ký, hiển thị dữ liệu thiếu; hỗ trợ nhận biết thói quen. | Vừa; diary, analytics; phân loại đáng tin, tránh chấm điểm sức khỏe. |
| J. Nhắc thói quen / P3 | Người dùng chọn lịch nhắc ghi chép/kế hoạch và tắt được. | Vừa; settings, platform notification; quyền, timezone, không gây áp lực ăn uống. |
| A. Trợ lý kiến thức / P3 | Trả lời câu hỏi kèm nguồn đã duyệt và nêu khi không đủ thông tin. | Cao; AI, knowledge, backend; kiểm định nguồn, an toàn, chi phí và quyền nội dung; không chẩn đoán. |

## 9. Test Results

| Lệnh | Kết quả audit |
|---|---|
| `git diff --check` | **OBSERVED PASS**, exit 0; cảnh báo chuyển LF/CRLF, không phải lỗi whitespace. Nhiều thay đổi có sẵn và file backend chưa được Git theo dõi; diff check không bao phủ nội dung untracked. |
| `dotnet build backend\LongEva.Api\LongEva.Api.csproj --no-restore` | **OBSERVED PASS**, 0 warning, 0 error. |
| `dotnet test backend\LongEva.Api.Tests\LongEva.Api.Tests.csproj --no-restore` | **OBSERVED PASS**, 12 passed, 0 failed/skipped, VSTest/xUnit, SDK 10.0.401. Không đồng nghĩa đã test dịch vụ thật. |
| `flutter analyze --no-pub` | **BLOCKED**: không output trong thời gian chờ, dừng thủ công; không có kết quả. |
| `flutter test --no-pub` | **BLOCKED**: không output trong thời gian chờ, dừng thủ công; không có kết quả. |
| `flutter build web --no-pub` | **BLOCKED**: không output trong thời gian chờ, dừng thủ công; không có kết quả. |

Không đo coverage, không chạy dependency vulnerability/outdated hoặc Flutter integration/thiết bị. Build/test tạo output và cache cục bộ; không gọi API ghi dữ liệu thật. Các kết quả trước đây trong tài liệu không thay thế kết quả hiện tại.

## 10. Priority Roadmap

1. **Phase 1 — tính đúng đắn và an toàn:** C01–C04, C07; [app_state.dart](lib/shared/services/app_state.dart), [firestore_repository.dart](lib/shared/services/firestore_repository.dart), [meal_photo_analysis_screen.dart](lib/features/meal_evaluation/screens/meal_photo_analysis_screen.dart), [GeminiService.cs](backend/LongEva.Api/GeminiService.cs), [Program.cs](backend/LongEva.Api/Program.cs), [ai_meal_recommendation_service.dart](lib/features/user_progress/services/ai_meal_recommendation_service.dart). Kiểm thử lỗi ghi, thay tài khoản, payload và giới hạn request.
2. **Phase 2 — hoàn thiện luồng lõi:** sửa C02/C05/C09; [meal_result_screen.dart](lib/features/meal_evaluation/screens/meal_result_screen.dart), photo screen, planner, state; xác nhận và thử lại, đọc dữ liệu sau restart, thông báo trạng thái lưu.
3. **Phase 3 — chất lượng AI:** [GeminiService.cs](backend/LongEva.Api/GeminiService.cs), [Contracts.cs](backend/LongEva.Api/Contracts.cs), [meal_photo_analyzer.dart](lib/features/meal_evaluation/services/meal_photo_analyzer.dart), [verified-principles.json](backend/LongEva.Api/docs/verified-principles.json); contract, fallback, ảnh thật được phép, whitelist, an toàn trẻ em và kiểm duyệt nguồn.
4. **Phase 4 — kiến trúc và hiệu năng:** tách state/repository và widget lớn; đo startup, rebuild, query, concurrency; quản lý catalog và nguồn dùng chung.
5. **Phase 5 — tính năng:** dị ứng/catalog trước, sau đó nhật ký, mua sắm và lịch sử; assistant sau khi có dữ liệu và kiểm định.
6. **Phase 6 — production:** [firestore.rules](firebase/firestore.rules), [firebase.json](firebase.json), [Program.cs](backend/LongEva.Api/Program.cs), cấu hình Android/web; test rules emulator, HTTPS, secrets, CORS, monitoring, backup, test release trên thiết bị. Không yêu cầu Blaze như điều kiện bắt buộc.

## 11. Final Assessment

Kiến trúc có nền tảng phân module và các luồng quan trọng đã được cài đặt, nhưng state, persistence và AI orchestration còn tập trung. Chất lượng code có test backend đạt; Flutter và runtime chưa kiểm chứng. Mức hoàn thiện nghiệp vụ phù hợp prototype đang phát triển, không đủ bằng chứng gọi là sẵn sàng sản xuất. Tính ổn định dữ liệu và trải nghiệm cần sửa trước. Bảo mật local rules và token có nền tảng, nhưng triển khai thực tế, rate limiting và kiểm thử xâm nhập chưa đủ bằng chứng. AI có Gemini chính, Groq fallback có điều kiện và citation whitelist, song an toàn/độ chính xác nội dung chưa được chứng minh. UX có hướng dẫn, loading và chỉnh sửa, nhưng cần kiểm thử trực quan và xử lý kết quả cũ. Android, Web, backend hosting và Firebase production đều **NOT_TESTED/BLOCKED** cho mục đích release.
