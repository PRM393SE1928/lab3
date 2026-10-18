# Member 2: Meal Evaluation & Suggestions

## Scope and integration

Implementation lives in `lib/features/meal_evaluation`. Member 1 and Member 3
screens/models are unchanged. Shared changes are limited to delegation of the
score rule in AppState, reading a saved evaluation by meal ID, latest-result
ordering, and optional Meal route data for suggestions.

- Member 1 supplies an existing Meal in AppState and opens
  `context.push('/meal-result', extra: meal)`.
- The existing Add Meal screen returns to the diary; tap the saved meal to evaluate.
  Member 1 can use the route above for direct navigation after creating a meal.
- Member 2 evaluates a snapshot and calls AppState.recordEvaluation only after
  success. Editing uses AppState.updateMeal, preserves ID/date/type, then records
  the new result. Cancellation/failure leaves the original meal/result intact.
- Member 3 reads `savedEvaluationFor(mealId)` for a completed result, or uses the
  existing `evaluationFor`, weeklyScores and weeklyScore contracts. No persistence
  or statistics UI was added. The existing statistics aggregation is unchanged.
- `/suggestions` accepts optional `extra: Meal`. It uses that meal's saved result,
  never another meal's result. Without extra, it pins the latest completed meal
  when opened. An edited/deleted/missing result produces an empty state.

## Scoring v1 (proposed app rules)

No approved nutrition formula or nutrient/portion data was supplied. This is an
explainable qualitative app score, not a validated health/longevity score. The UI
states this limitation. All rule definitions and catalog tags live in
`services/meal_evaluator.dart`; future API evaluators implement MealEvaluator.

Each criterion awards at most 25 points; sum is 0..100:

| Criterion | Rule |
|---|---|
| Group diversity | floor(groups * 25 / 3), capped at 25 |
| Plant groups | zero = 0; one = 12; at least two = 25 |
| Whole grains | present = 25, absent = 0 |
| Protein group | legumes, fish or nuts present = 25, otherwise 0 |

Recipe tags for the current five demo IDs:

- oats: whole grains + fruit
- salad: vegetables + legumes
- salmon: fish (rice is not assumed to be whole grain)
- nuts: nuts + fruit
- soup: vegetables

Groups are a set: repeating dishes never increases points. Category is currently
meal time, not nutrition; names/category strings are never used to guess nutrients.
Unknown IDs earn no group credit and produce an explicit provisional-score warning.
New catalog IDs require metadata here. Empty meals produce a recoverable error.
Suggestions reflect missing criteria; a 100-point meal has an empty suggestion
list and is not prompted to add food.
The same rules currently apply to snacks; there is no portion-aware assessment.

## Async behavior

Loading -> Result, or Error -> Retry -> Result. Pending controls prevent duplicate
submissions. Retry preserves the proposed foods after evaluator failure. If the
source meal changes during evaluation or before retry, the stale draft/result is
rejected. Deleted meals cannot be resurrected. Leaving the page or switching to a
different meal prevents late results from being saved. No random failures, forced
network requests, or artificial scoring delays are used. Tests inject a controlled
async evaluator to exercise failures and races deterministically.

## Test manually

1. Add a meal through the existing diary, then tap it to open evaluation.
2. Confirm loading, Meal Score, per-criterion points/explanations and suggestions.
3. A single soup scores 20; oats scores 66; oats plus bean salad scores 100.
4. Choose “Đổi món và đánh giá lại”, change selections, and apply. Verify the new
   score, previous-score comparison, updated diary meal and shared evaluation.
5. Reopen the editor, deselect all: submit is disabled. Cancel: no changes.
6. Open suggestions for two different meals; each must retain its own content.

Automated tests cover scoring combinations, duplicates, unknown foods, empty input,
immutable results, result invalidation, loading/error/retry, draft preservation,
cancel, stale/deleted meals, leaving during evaluation, and meal-specific suggestions.
Run `flutter pub get`, `flutter analyze`, and `flutter test`.

## Verified implementation

- `flutter pub get`: passed.
- `flutter analyze --no-pub`: no issues.
- `flutter test`: all 40 tests passed, including existing app/state tests.
- The result-to-suggestions route was tested at 360 x 800 logical pixels.
- No new packages and no changes to Member 1/3 screens were required.
