# LONGEVA design decisions

## Retained decisions

- Provider remains the state-management choice because the Lab 2 codebase
  already uses constructor-injected repositories and `ChangeNotifier`.
- The five-tab navigation remains Home, Nhật ký, Kiến thức, Tiến trình and Kế
  hoạch. The diary does not gain a separate add button; meal capture remains
  reachable from Home/planning flows.
- The proposed score remains a transparent 0-100 qualitative app indicator.
  It is not a medical assessment, nutrient calculation, or longevity
  prediction.
- Unknown food metadata contributes no invented nutrition or food-group credit.
- Age filtering only returns catalog items explicitly annotated for that age
  group. Missing metadata is treated as unknown.

## Lab 3 decisions

- Firebase adapters will be behind interfaces and injected into state/services.
  This keeps widget tests deterministic and prevents SDK calls in `build()`.
- Firestore documents are scoped below the authenticated UID. UI visibility is
  not treated as a security boundary; rules enforce ownership.
- Analytics parameters use aggregate, non-PII values only.
- External integrations are reported as blocked until real project/device
  evidence exists. No fake screenshots, URLs, dashboard findings, or pass
  rates are created.

## Design comparison

The existing theme already matches the requested LONGEVA tokens: deep green
`#245C4A`, sage `#9BBFA8`, cream `#FFFCF6`, orange `#E88D52`, charcoal
`#24312D`, 20dp cards and 16dp inputs. The app uses Georgia with screen-level
Material styles; typography centralization is a follow-up, not a visual
redesign.

