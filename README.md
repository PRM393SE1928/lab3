# Longeva - mobile app lab 2 / lab 3 foundation

> Cập nhật 06/11/2026: code hiện có Firebase Auth, lưu dữ liệu Firestore và backend
> AI; các đoạn mô tả nền tảng mock bên dưới là tài liệu của giai đoạn cũ.
> Màn đánh giá đã bỏ điểm số, dùng tiêu chí đối chiếu từ `longo.pdf`.
> Tính năng mới nằm tại **Hồ sơ → Lưu hồ sơ → AI phân tích hồ sơ và gợi ý món ăn**.
> Xem [nguồn sách, cách đánh giá và chức năng hồ sơ](docs/book-evaluation-sources.md).

Longeva is a Flutter base app for students living away from home who want to build healthier eating habits. This phase contains UI flows and in-memory mock data only. It does not provide medical advice, authentication, backend services, or life-expectancy predictions.

## Stack

- Flutter stable 3.47.4 / Dart 3.13.3
- Material 3
- `go_router` for centralized navigation
- `provider` for shared session state
- Android-first, with a structure ready for iOS

## Run locally

```bash
flutter pub get
flutter analyze
flutter test
flutter emulators --launch flutter_android_36
flutter run -d emulator-5554
```

Use the `Longeva (Android emulator)` launch configuration in VS Code, or run the commands above. Do not select Chrome or Edge as the Flutter device. If `emulator-5554` is reported as offline, close the emulator, restart Android Studio's AVD, and wait until `adb devices` reports `emulator-5554 device` before running the app. The app starts with seeded meals and articles; changes persist only while the app process is running.

## Structure

`lib/core` contains theme tokens, router, and reusable widgets. `lib/shared` contains mock services and `AppState`. Each product area is isolated under `lib/features` with models and screens owned by that feature.

## Shared contracts

`AppState` is the only in-memory source of truth for meals, evaluations, articles, profile data, and progress. Screens must use its methods instead of mutating model lists or model fields directly. `AppRepository` is the read boundary for seed/catalog data; `MockRepository` is the current implementation and can later be replaced without changing feature screens.


Data is process-local only. There is no backend, database, authentication, notification scheduler, or persistence across app restarts.

## Lab 3 readiness

The repository now includes the Lab 3 audit and implementation traceability:

- [Design traceability](docs/design-traceability.md)
- [Architecture](docs/architecture.md)
- [Analytics plan](docs/analytics-plan.md)
- [Test plan](docs/test-plan.md)
- [Design decisions](docs/design-decisions.md)
- Firestore and Storage ownership rules in `firebase/`
- Remote Config defaults in `firebase/remote-config-defaults.json`
- ARTEMIS test harness scaffold in `e2e_test/`

Firebase services are not claimed as configured. Before enabling them, provide a
Firebase project, registered Android app, test account, `google-services.json`,
and the required device/API access. The current app continues to use the
process-local repository until a configured cloud repository is injected.

## Phân tích ảnh bữa ăn

Từ màn hình thêm bữa ăn, người dùng có thể chọn ảnh từ thư viện hoặc camera.
Ứng dụng mặc định gọi backend AI qua `MEAL_AI_BACKEND_URL`; nếu chưa cấu hình
endpoint, ứng dụng báo lỗi rõ ràng và không giả lập kết quả AI. Chế độ `Demo`
chỉ dùng khi bật tường minh để kiểm thử UI:

```bash
flutter run --dart-define=MEAL_AI_MODE=demo
flutter run --dart-define=MEAL_AI_BACKEND_URL=https://your-backend.example/meal-analysis
```

Client gửi ảnh dạng multipart cùng loại bữa ăn tới backend, kèm Firebase ID
token trong `Authorization: Bearer`. Backend xác thực token, gọi Gemini bằng
secret lưu phía server, rồi trả JSON dạng:

Kết quả gồm `recognizedFoods`, `visibleIngredients`, `unknownInformation`,
`overallSummary`, `principleAnalyses`, `improvementPoints`, `suggestions`,
`references` và `insufficientData`. Khi chưa có dữ liệu sách đã xác minh,
`principleAnalyses` và `references` rỗng, đồng thời `insufficientData` nêu rõ
giới hạn này; ứng dụng không tự tạo trích dẫn hoặc số trang.

Flutter không nhận API key AI và không gọi trực tiếp nhà cung cấp AI. Backend
ASP.NET Core nằm trong `backend/LongEva.Api`; cấu hình Gemini và Firebase được
thực hiện bằng biến môi trường theo hướng dẫn trong `backend/README.md`. Không
có tài liệu nguồn về sách “Chế độ ăn trường thọ” trong repository; không gán
các tiêu chí hiện tại là trích dẫn chính thức của sách.

## Team split

- Member 1: `features/home` and `features/food_diary`. Own Home, diary, add/edit/delete meal flows.
- Member 2: `features/meal_evaluation`. Own result scoring presentation, loading/error states, and suggestions.
- Member 3: `features/knowledge` and `features/user_progress`. Own articles, progress, profile, and settings.

Shared contracts are in `core`, `shared/services/app_state.dart`, and the feature model folders. Before merging, each member should keep routes in `core/router/app_router.dart`, use existing shared widgets, and run `flutter analyze` and `flutter test`.

## Main routes and route data

| Route | Data contract |
| --- | --- |

| `/meal-result` | Required `extra: Meal` |
| `/suggestions` | Optional `extra: Meal`; otherwise latest evaluated meal |
| `/article` | Required `extra: Article` |

Invalid or missing required `extra` values show a safe error screen. No route currently uses path parameters or query parameters.

The expected flow is Add Meal -> Meal Detail -> Meal Result -> Suggestions. Progress reads the same meals and saved evaluations from `AppState`; it does not maintain a separate score list.

## Next steps

The settings switches are intentionally disabled and labeled as not implemented in this demo. Do not re-enable them until reminder scheduling and compact-diary behavior have an owner and persistence contract.

Before parallel work, keep changes to feature-owned folders where possible. Changes to `AppState`, `AppRepository`, models, or `app_router.dart` are shared-contract changes and should be coordinated first. Each member should run `flutter analyze` and `flutter test` before merging.

Future work can replace `MockRepository` with a repository implementation backed by an API or local persistence, add production error/loading handling, review accessibility and localization, and define the nutrition evaluation contract with appropriate non-medical product language.

## Android mobile

Xem [hướng dẫn chạy Android và xuất APK](docs/android_mobile.md).
Phần đổi món dùng màn hình toàn màn hình với vùng chọn cuộn và nút xác nhận cố định.
