# LONGEVA Lab 3 design traceability

## Phase A audit

Audit date: 2026-11-02

| Area | Current evidence | Status | Gap or next action |
|---|---|---|---|
| Flutter baseline | Flutter 3.47.4, Dart 3.13.3, SDK constraint `^3.13.3` | PASS | Keep the current toolchain |
| Navigation | `GoRouter` shell with Home, Diary, Knowledge, Progress, Planner | PASS | Preserve the five destinations |
| State management | `Provider` and `AppState extends ChangeNotifier` | PASS | Keep Provider; introduce cloud repositories behind interfaces |
| Meal diary | Add, edit, delete, date filtering, detail and empty state | PASS | Persist through Firestore when Firebase is configured |
| Meal evaluation | Explainable 0-100 qualitative score with warnings and suggestions | PASS | Keep non-medical wording; persist completed evaluations |
| Knowledge | Search, topic filter, detail, read progress | PASS | Persist read progress per UID |
| Progress | Real in-memory meals/evaluations only; zero distinguishes no score | PASS | Replace process-local source with authenticated repository |
| Planner | Day/week navigation, meal slots, age-filtered suggestions, completion to diary | PASS | Persist plans and completion links |
| Photo analysis | Demo mode is explicit; Real mode fails without a build-time key | PARTIAL | Move real AI calls behind a backend in production |
| Design system | LONGEVA colors, 20dp cards, 16dp inputs, Material 3 | PASS | Centralize remaining screen-level text styles incrementally |
| Firebase Authentication | No Firebase package/config or sign-in route | BLOCKED | Requires Firebase project, Android app registration and test account |
| Firestore | No SDK/config/rules previously present | PARTIAL | Rules scaffold added; SDK integration needs project configuration |
| Cloud Storage | Not implemented | BLOCKED | Requires Firebase project and a real report export flow |
| Cloud Messaging | Not implemented | BLOCKED | Requires Firebase project, device permission and FCM test |
| Analytics | Not instrumented | PARTIAL | Event contract documented; DebugView verification still required |
| Crashlytics | Not configured | BLOCKED | Requires Firebase project and dashboard verification |
| Remote Config | Not configured | PARTIAL | Defaults scaffolded; console fetch/activate verification required |
| ARTEMIS | No E2E harness | PARTIAL | Test structure and cases documented; device/API key required |
| AI code review | No external review evidence in repository | BLOCKED | Run review on a PR/diff and record actual findings |

A local `google-services.json` was detected, but the Flutter Firebase SDK
dependencies, runtime wiring, test account, ARTEMIS API key, and connected
Android device were not verified during this audit. The local config is ignored
by Git and is not evidence that any service is operational.

## Lab 2 traceability

| Flow or screen | Route | Screen/widget | State/service boundary | Loading/empty/error/recovery | Tests | Implementation |
|---|---|---|---|---|---|---|
| Home and quick add | `/` and `/add-meal` | `HomeScreen`, `AddMealScreen` | `AppState.addMeal`, `MockRepository` | Empty diary links to Planner; invalid route has recovery to Home | `app_test.dart`, `app_state_test.dart` | PASS |
| Record and evaluate meal | `/meal/:mealId`, `/meal-result` | `MealDetailScreen`, `MealResultScreen` | `RuleBasedMealEvaluator`, `AppState.recordEvaluation` | Evaluation error/retry is handled by evaluation UI; missing meal is safe | `meal_evaluator_test.dart`, `meal_evaluation_widget_test.dart` | PASS |
| Edit meal | `/add-meal?mealId=...` | `AddMealScreen`, `MealFoodEditor` | `AppState.updateMeal` invalidates stale score | Empty selection is rejected; cancel preserves original | `app_state_test.dart`, evaluation widget tests | PASS |
| Delete meal | `/diary` | `DiaryScreen` and confirmation dialog | `AppState.deleteMeal` | Confirmation required; unknown ID is a no-op | `app_state_test.dart` | PASS |
| Search/read knowledge | `/learn`, `/article` | `KnowledgeScreen`, `ArticleDetailScreen` | `AppState.markArticleRead` | No-result empty state; clear-filter recovery | `knowledge_widget_test.dart` | PASS |
| Progress | `/progress` | `ProgressScreen` | `AppState.weeklyProgress`, saved evaluations | Unevaluated meals remain distinct from low scores | `app_state_test.dart` | PASS |
| Plan and age suggestions | `/planner` and `/planner/edit` | `MealPlannerScreen`, suggestion sheet/editor | `AppState` meal-plan contract | Empty day; invalid/unknown catalog metadata is not invented | `meal_planner_test.dart`, `meal_suggestion_age_test.dart` | PASS |

## Lab 3 target traceability

| Requirement | Planned boundary | Evidence required | Status |
|---|---|---|---|
| Auth routing | `AuthService` + auth gate before `AppState` | Firebase Auth emulator/device sign-in and sign-out | BLOCKED |
| User-scoped data | `CloudAppRepository` and UID-based collections | Firestore read/write under two test UIDs | BLOCKED |
| Report export/upload | `ReportExporter` + `StorageService` | URL for a report built from viewed data | BLOCKED |
| Notifications | `MessagingService` + in-app notification model | Foreground/background/terminated device runs | BLOCKED |
| Analytics | `AnalyticsService` | DebugView events with non-PII parameters | PARTIAL |
| Crash reporting | `CrashReportingService` | Crashlytics dashboard event | BLOCKED |
| Feature flags | `RemoteConfigService` | Console change visible without rebuild | PARTIAL |
| E2E | `e2e_test` pytest/ARTEMIS harness | Three-run results and exploratory notes | BLOCKED |
