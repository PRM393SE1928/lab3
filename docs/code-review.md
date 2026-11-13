# Longeva Lab 3 - AI-assisted code review record

This record is deliberately limited to findings that can be verified in the
current repository. An external pull-request review and linked fix commits
still need to be added before submission; this file does not claim that those
steps were completed.

| ID | Tool | Location | Kind | Finding | Decision | Action |
|---|---|---|---|---|---|---|
| CR-01 | Local review | `lib/features/user_progress/screens/settings_screen.dart` | Architecture | The screen called Crashlytics directly, bypassing the service boundary. | Accepted | Routed crash logging through `CrashReportingService`. |
| CR-02 | Local review | `lib/app.dart` | Architecture | Repository selection inspected Firebase state inside the widget tree. | Accepted | Moved selection to `RepositoryFactory`. |
| CR-03 | Local review | `lib/main.dart` | Reliability | Auth service construction could happen before Firebase initialization. | Accepted | Constructed `AuthService` after Firebase initialization and injected it into the auth gate. |
| CR-04 | Local review | `lib/shared/services/app_state.dart` | Persistence | Firestore writes are intentionally asynchronous, but the error is only retained in `lastPersistenceError`. | Modified | Kept the non-blocking UI contract; the next fix is to surface retryable persistence state in the app shell. |
| CR-05 | Local review | `e2e_test/conftest.py` | Test gap | ARTEMIS client setup is a skip placeholder, so no E2E evidence can be claimed. | Accepted | Kept the fail-fast skip and marked ARTEMIS execution as pending rather than fabricating results. |

## Disclosure

The repository has used ChatGPT/Codex for implementation and review assistance.
The external AI review tool, pull request URL, review output, and fix commit
links must be recorded here after they are actually run.
