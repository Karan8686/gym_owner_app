# SKILL.md — Build Conventions for FitTrack Owner App

Read this before writing or generating any code for this project. It defines *how* things get built, not *what* — see GOAL.md for scope.

## Folder architecture: feature-first
Mirror the structure already used in Let's Enterprise. Do not use a type-first structure (no top-level `screens/`, `widgets/`, `models/` folders holding everything).

```
lib/
  core/
    config/           # Supabase client init, env keys, theme tokens
    router/           # go_router routes
    widgets/          # truly generic shared widgets (buttons, hairline divider, etc.)
    utils/            # date formatting, currency formatting, validators
  features/
    auth/
      data/           # Supabase auth calls
      domain/         # models (Owner)
      presentation/   # login screen, PIN setup, controllers (Riverpod)
    dashboard/
      data/
      domain/
      presentation/
    members/
      data/           # member + membership Supabase queries
      domain/         # Member, Membership models
      presentation/   # list, detail, add, edit, renew screens
    payments/
      data/
      domain/
      presentation/   # pending list, verification detail
    workouts/
      data/
      domain/
      presentation/   # template library, editor, assign screen
    pricing/
      data/
      domain/
      presentation/
    analytics/
      data/
      presentation/
    settings/
      presentation/
  main.dart
```
Each feature is self-contained: its own data/domain/presentation. Shared code only goes in `core/` if at least two features need it — don't pre-emptively abstract.

## State management
Riverpod throughout. Conventions:
- One `Notifier`/`AsyncNotifier` per screen-level concern (e.g. `MemberListNotifier`, `PendingPaymentsNotifier`), not one giant app-wide state object.
- Supabase queries go in the feature's `data/` layer as repository classes (e.g. `MembersRepository`), injected via `Provider`. Screens never call `Supabase.instance.client` directly — always through a repository.
- Use `AsyncValue` and its `.when(data:, loading:, error:)` pattern for anything hitting the network — every list/detail screen needs a visible loading and error state, not just a happy path.

## Design system enforcement
All screens must pull from a single `AppTheme`/`AppColors` file in `core/config/theme.dart` — never hardcode hex values in a widget. Tokens (must match the Stitch spec exactly):
```dart
background: #F6F6F4
surface: #FFFFFF
border: #E4E4E1
inkPrimary: #161616
inkSecondary: #7A7A76
signal: #D6321F   // ONLY for expired/overdue/destructive states — never decorative
cornerRadius: 8
```
Typography: a monospace font family (JetBrains Mono or IBM Plex Mono, bundled as an asset) for every numeral — days remaining, prices, dates, counts. A grotesk sans (Inter or General Sans) for everything else. Enforce this via two `TextStyle` constants (`AppText.numeral`, `AppText.body`) rather than repeating font family strings.

No `BoxShadow` anywhere. Cards are `Container` with a `Border.all(color: AppColors.border, width: 1)`, not `Card` widget defaults (which add elevation/shadow) — override or avoid `Card` entirely.

## Naming conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Riverpod providers: `camelCaseProvider` (e.g. `pendingPaymentsProvider`)
- Supabase table/column names stay `snake_case` end-to-end — don't translate to camelCase in Dart models; use `json_serializable` with explicit `@JsonKey(name: 'due_date')` mapping only where Dart requires camelCase field names.

## Business logic placement
Anything in the "business rules" section of GOAL.md (renewal date math, payment confirmation triggering `due_date` extension) lives in the `domain/` layer as pure functions or repository methods — never inline inside a widget's `onPressed`. This keeps it testable and keeps the member app's equivalent logic (if duplicated) easy to compare against.

## Error handling & empty states
Every list screen (`Member List`, `Pending Payments`, `Workout Templates`) needs an explicit empty-state widget with plain grey text (per the Stitch spec's copy, e.g. "No pending payments.") — never leave a blank white screen if a query returns zero rows.

Supabase errors surface as a plain-text banner or inline message using `inkSecondary` grey text, in the interface's own voice ("Couldn't load members. Check your connection and try again.") — no raw exception text, no apologetic tone.

## Testing expectations
- Unit tests required for: renewal date calculation logic, price lookup logic (plan + duration → price).
- Widget tests optional for v1 given solo-dev timeline — prioritize the business logic tests above over UI tests.

## Git conventions
- Conventional commits (`feat:`, `fix:`, `chore:`, `refactor:`) scoped by feature, e.g. `feat(payments): add UTR verification screen`.
- One feature folder = one PR/branch where practical, matching the build order in GOAL.md's phased plan.
