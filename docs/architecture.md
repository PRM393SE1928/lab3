# LONGEVA architecture

## Current and target structure

```text
lib/
  core/                 theme, router, reusable UI
  features/
    food_diary/         meal models and diary UI
    meal_evaluation/    evaluation model, rule and UI
    meal_planner/       plan model and planning UI
    knowledge/          article model and UI
    user_progress/      profile, progress and settings UI
    home/               home UI
  shared/services/      AppState and repository boundaries
```

The current implementation uses Provider. `AppState` is the in-memory
application state and `AppRepository` is the read boundary for seed data.
Provider is retained because it is already used throughout the app, the
existing tests construct `AppState` with a repository, and replacing it would
create migration risk without improving the current flows.

## MVVM mapping

```text
Widget/View
  -> Provider<AppState> / feature controller
  -> AppState and injected service interfaces
  -> AppRepository / future Firebase repositories
  -> Firestore, Storage, Auth, FCM, Analytics, Crashlytics, Remote Config
```

Widgets render state and forward user actions. Validation, filtering, scoring,
plan completion, and cross-feature consistency belong in `AppState` or a
feature service. SDK calls must remain in service implementations, never in
`build()` methods.

## Data flow: record and evaluate a meal

```text
User -> AddMealScreen
     -> AppState.addMeal()
     -> MealRepository.saveMeal() [target]
     -> Diary / MealDetail
     -> MealEvaluator.evaluate(snapshot)
     -> AppState.recordEvaluation()
     -> EvaluationRepository.saveEvaluation() [target]
     -> MealResultScreen and ProgressScreen
```

The current mock implementation stops at `AppState`; the target repository
calls are intentionally not described as implemented until Firebase
configuration and device verification exist.

## State contract

Every asynchronous cloud operation should expose `initial/loading/data/empty`
and `error` with a retry action. Existing synchronous mock flows use explicit
empty widgets and safe invalid-route screens. Cloud adapters must preserve the
same behavior and must not silently fall back to seeded data after an
authenticated request fails.

## Dependency injection

`AppState` already receives an `AppRepository`. The next seams should follow
the same constructor-injection pattern:

| Service | Responsibility | Test replacement |
|---|---|---|
| `AuthService` | sign-in, sign-out, auth stream | fake auth service |
| `MealRepository` | meals, evaluations and plans by UID | in-memory repository |
| `ContentRepository` | catalog and articles | mock content repository |
| `StorageService` | upload and URL retrieval | fake upload service |
| `MessagingService` | permission, tokens and messages | fake messaging service |
| `AnalyticsService` | event names and safe parameters | recording analytics service |
| `CrashReportingService` | non-fatal and test-crash hooks | recording crash service |
| `RemoteConfigService` | defaults, fetch and activate | fixed-value fake |

