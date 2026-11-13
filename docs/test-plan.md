# LONGEVA Lab 3 test plan

The cases below are the required ARTEMIS scope. Results are intentionally
`NOT RUN` until an Android device/emulator, Firebase project, test account and
ARTEMIS access are supplied.

| ID | Preconditions | Observable instruction and expected result | Flow | Result |
|---|---|---|---|---|
| E2E-01 | Test account and Firebase Auth configured | Sign in; Home title and authenticated shell are visible | Sign-in | NOT RUN |
| E2E-02 | Signed in | Add a meal, open detail, evaluate; score and explanation are visible | Record/evaluate | NOT RUN |
| E2E-03 | Existing meal | Edit items, save, reopen; prior evaluation is cleared | Edit | NOT RUN |
| E2E-04 | Existing meal | Delete and confirm; diary shows empty state for the date | Delete/recovery | NOT RUN |
| E2E-05 | Articles loaded | Search, filter, open and mark read; progress changes | Knowledge | NOT RUN |
| E2E-06 | Signed in | Visit all five tabs; each title/content is visible | Navigation | NOT RUN |
| E2E-07 | Planner enabled | Choose age group and meal; selected catalog item appears in plan | Suggestions/planning | NOT RUN |
| E2E-08 | Report data exists | Export and upload; progress and download URL are visible | Export/upload | NOT RUN |
| E2E-09 | Remote Config console value changed | Refresh/fetch; configured suggestion limit changes visible list without rebuild | Remote Config | NOT RUN |
| E2E-10 | Signed in | Sign out; sign-in screen appears and private data is inaccessible | Sign-out/security | NOT RUN |
| E2E-11 | Android device | Use native back/permission interaction; app recovers without crash | Native interaction | NOT RUN |
| E2E-12 | Network/service failure can be induced | Retry action displays recovery or explicit error, never fake success | Error handling | NOT RUN |

Each case must be independent and run at least three times when the environment
allows. Record pass rate, flaky behavior, device/API level, and exploratory
findings only after actual execution.

