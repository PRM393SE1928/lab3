# Longeva AI backend

ASP.NET Core 8 API. It verifies Firebase ID tokens before calling Gemini.

Configure the secrets once with .NET User Secrets. They are stored outside the
repository and loaded automatically on every `dotnet run`:

```powershell
dotnet user-secrets --project backend\LongEva.Api set "GEMINI_API_KEY" "your-gemini-key"
dotnet user-secrets --project backend\LongEva.Api set "GEMINI_MODEL" "gemini-2.5-flash"
dotnet user-secrets --project backend\LongEva.Api set "Firebase:ProjectId" "your-firebase-project-id"
dotnet user-secrets --project backend\LongEva.Api set "Firebase:ServiceAccountPath" "C:\secure\service-account.json"
```

The service-account JSON file must exist at the configured path. Never commit
the API key or service-account file.

## Meal image storage

To enable the optional "Lưu ảnh cùng bữa ăn" switch in the photo-analysis
screen, configure Cloudinary on the backend (never in Flutter):

```powershell
dotnet user-secrets --project backend\LongEva.Api set "Cloudinary:CloudName" "your-cloud-name"
dotnet user-secrets --project backend\LongEva.Api set "Cloudinary:ApiKey" "your-api-key"
dotnet user-secrets --project backend\LongEva.Api set "Cloudinary:ApiSecret" "your-api-secret"
```

Restart the backend. `POST /api/meal-images` accepts a Firebase ID token and a
multipart `image` file (JPEG, PNG or WebP, maximum 10 MB); it returns the
Cloudinary HTTPS URL and public ID. The app stores the URL with the meal in
Firestore. Images use Cloudinary's default public delivery: anyone with the URL
can access them. Deleting a meal does not delete its Cloudinary asset; remove
unwanted assets in Cloudinary. An upload can also be left behind if saving the
meal fails. Do not upload sensitive images until private delivery and lifecycle
cleanup are implemented. Firestore writes use the app's existing asynchronous
persistence and errors are handled by its existing sync mechanism.

For a physical phone, set `MEAL_AI_BACKEND_URL` to a backend URL reachable by
the phone. Use HTTPS outside a trusted local development network.

Start the backend:

```powershell
dotnet run --project backend\LongEva.Api --urls http://localhost:51889
```

The backend also accepts `GEMINI_API_KEY`, `GOOGLE_APPLICATION_CREDENTIALS`,
and `FIREBASE_PROJECT_ID` environment variables as an alternative.

The VS Code launch configurations pass the backend URL automatically. For a
manual Flutter run, pass the matching URL explicitly:

```powershell
# Chrome
flutter run -d chrome --dart-define=MEAL_AI_BACKEND_URL=http://localhost:51889/api/ai/meal-evaluation

# Android emulator
flutter run -d emulator-5554 --dart-define=MEAL_AI_BACKEND_URL=http://10.0.2.2:51889/api/ai/meal-evaluation
```

`gemini-2.5-flash` is the configured multimodal Gemini Developer API model
with structured JSON output support. Keep the model configurable because model
availability and free-tier quotas are account and region dependent. Google’s
model documentation lists it as a stable model with text/image input and
structured outputs; confirm the current free-tier quota in AI Studio for the
API key’s project before production use.

The backend returns `503` when Gemini or Firebase credentials are not
configured; it never returns fake AI results.

Temporary Gemini `502/503/504` and connection failures are retried at most twice
with short delays. The entire AI operation has a 24-second budget. If overload
persists, the API returns `503` with `Retry-After: 10`; quota failures remain `429`.
An unconfigured Groq fallback no longer masks these as `502`.
Optional Groq fallback uses `Groq:ApiKey` in User Secrets or `GROQ_API_KEY`;
configure it only with your own key. Restart the backend after configuration changes.

Endpoints:

- `POST /api/ai/meal-recommendations` JSON, bearer Firebase ID token.
- `POST /api/ai/meal-evaluation` multipart form with `image`, `mealType`,
  optional `profile` and `notes`, bearer Firebase ID token.
- `POST /api/ai/meal-evaluation/manual` JSON with `mealType` and
  `confirmedFoods`, bearer Firebase ID token; this path does not require an
  image.

## Kết nối điện thoại Android thật qua Wi-Fi (phát triển)

1. Kết nối máy tính và điện thoại vào cùng mạng Wi-Fi. Chạy `ipconfig` trên máy tính và lấy IPv4 của adapter Wi-Fi (ví dụ `192.168.1.31`); địa chỉ này có thể thay đổi.
2. Cấu hình Firebase và Gemini như phần đầu tài liệu. Nếu cần tải ảnh, cấu hình thêm Cloudinary. Mở PowerShell tại thư mục gốc dự án và chạy:

   ```powershell
   dotnet run --project backend\LongEva.Api --no-launch-profile --urls http://0.0.0.0:51889
   ```

   Để cửa sổ này chạy. `0.0.0.0` là địa chỉ lắng nghe của backend, không phải địa chỉ nhập trên điện thoại.
3. Trên trình duyệt điện thoại, mở `http://192.168.1.31:51889/health`, thay địa chỉ bằng IPv4 thực tế của máy. Kết quả mong đợi là `{"status":"ok"}`. Nếu không truy cập được, kiểm tra Wi-Fi, tường lửa Windows cho cổng TCP 51889 trên mạng Private và chức năng client isolation của router. `/health` chỉ kiểm tra kết nối, không kiểm tra Gemini/Firebase/Cloudinary.
4. Bật USB debugging, kết nối điện thoại và kiểm tra bằng `flutter devices`. Trong cửa sổ PowerShell khác, thay IP và ID thiết bị rồi chạy bản debug:

   ```powershell
   flutter run -d <device-id> --dart-define=MEAL_AI_BACKEND_URL=http://192.168.1.31:51889/api/ai/meal-evaluation --dart-define=MEAL_AI_RECOMMENDATIONS_URL=http://192.168.1.31:51889/api/ai/meal-recommendations --dart-define=CRASHLYTICS_DEMO=true
   ```

   `MEAL_AI_BACKEND_URL` dùng cho phân tích và xác định máy chủ tải ảnh; `MEAL_AI_RECOMMENDATIONS_URL` cấu hình riêng chức năng gợi ý. Đăng nhập trước khi sử dụng các API.

Android debug cho phép HTTP trong cấu hình hiện tại. Bản release không bật HTTP: dùng backend HTTPS có chứng chỉ hợp lệ và thay cả hai URL bằng HTTPS khi build release. Không dùng HTTP để gửi token hoặc ảnh qua mạng không tin cậy. Nếu muốn thử Crashlytics ở release, dùng HTTPS cho backend hoặc chỉ thử Crashlytics mà không gọi backend. Crashlytics giao tiếp trực tiếp với Firebase, không phụ thuộc backend này.
