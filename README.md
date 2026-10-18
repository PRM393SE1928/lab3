# Longeva - mobile app lab 2

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

The demo evaluation rule is `58 + 12 * number of food items`, clamped to `0..100`, and is owned by the meal evaluation feature. Home and progress only display scores explicitly saved for a meal; unevaluated meals contribute `0` until a result is recorded. Weekly score is the rounded average of saved scores for meals logged in the last seven calendar days. Streak is the number of consecutive calendar days with at least one meal, ending today; it is `0` when there is no meal today. Updating a meal clears its saved evaluation, and deleting a meal removes its evaluation.

Data is process-local only. There is no backend, database, authentication, notification scheduler, or persistence across app restarts.

## Team split

- Member 1: `features/home` and `features/food_diary`. Own Home, diary, add/edit/delete meal flows.
- Member 2: `features/meal_evaluation`. Own result scoring presentation, loading/error states, and suggestions.
- Member 3: `features/knowledge` and `features/user_progress`. Own articles, progress, profile, and settings.

Shared contracts are in `core`, `shared/services/app_state.dart`, and the feature model folders. Before merging, each member should keep routes in `core/router/app_router.dart`, use existing shared widgets, and run `flutter analyze` and `flutter test`.

## Main routes and route data

| Route | Data contract |
| --- | --- |
| `/`, `/diary`, `/learn`, `/progress`, `/suggestions`, `/profile`, `/settings` | No route data |
| `/add-meal` | Optional `extra: Meal` or `?mealId=...`; no data opens create mode, a valid meal opens edit mode |
| `/meal/:mealId` | Required meal ID; missing IDs show a safe detail state |
| `/meal-result` | Required `extra: Meal` |
| `/article` | Required `extra: Article` |

Invalid or missing required `extra` values show a safe error screen. No route currently uses path parameters or query parameters.

The expected flow is Add Meal -> Meal Detail -> Meal Result -> Suggestions. Progress reads the same meals and saved evaluations from `AppState`; it does not maintain a separate score list.

## Next steps

The settings switches are intentionally disabled and labeled as not implemented in this demo. Do not re-enable them until reminder scheduling and compact-diary behavior have an owner and persistence contract.

Before parallel work, keep changes to feature-owned folders where possible. Changes to `AppState`, `AppRepository`, models, or `app_router.dart` are shared-contract changes and should be coordinated first. Each member should run `flutter analyze` and `flutter test` before merging.

Future work can replace `MockRepository` with a repository implementation backed by an API or local persistence, add production error/loading handling, review accessibility and localization, and define the nutrition evaluation contract with appropriate non-medical product language.
