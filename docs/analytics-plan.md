# LONGEVA analytics plan

Instrumentation is not yet enabled. This contract must be reviewed before
adding a Firebase Analytics dependency. Parameters must not contain email,
name, raw notes, free-form article text, or other direct personal data.

| Event | Trigger | Parameters and types | Product question | Lab 2 flow |
|---|---|---|---|---|
| `login` | Auth success | `method:string` | Which sign-in method succeeds? | Entry |
| `logout` | Auth success | none | Do users sign out? | Session |
| `meal_logged` | Meal saved | `meal_type:string`, `item_count:int`, `source:string` | Which entry path is used? | Flow 1 |
| `meal_detail_opened` | Detail route opens | `meal_type:string`, `has_evaluation:bool` | Are logged meals reviewed? | Flow 1 |
| `meal_evaluated` | Evaluation saved | `score_band:string`, `rule_version:string` | Is evaluation completed? | Flow 1 |
| `knowledge_searched` | Search submitted | `query_length:int`, `result_count:int` | Which searches find content? | Flow 3 |
| `article_opened` | Article detail opens | `topic:string`, `read_minutes:int` | Which topics are opened? | Flow 3 |
| `plan_meal_added` | Plan mutation succeeds | `meal_type:string`, `age_group:string` | Are age-aware suggestions useful? | Planner |
| `export_report` | Export starts/succeeds | `format:string`, `record_count:int` | Is export used? | Lab 3 |
| `file_uploaded` | Storage upload succeeds | `file_type:string`, `byte_count:int` | Does report upload complete? | Lab 3 |

Verification must be performed in Firebase DebugView with a test account and
recorded as evidence. Calling `logEvent` in code alone is not verification.

