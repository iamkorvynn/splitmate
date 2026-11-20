# SplitMate

Split bills with friends and groups — a complete, real Flutter app.

## What it does

- **Groups** — create groups with members (add/remove members; members with
  expenses or settlements can't be removed).
- **Expenses** — add expenses with a payer and amount; split **equally**
  (remainder paise distributed one by one) or by **custom shares** with
  sum validation.
- **Balances** — automatic per-member balances, with a **suggested settle-up
  plan** (greedy minimum-cash-flow) so the fewest payments clear the group.
- **Settle up** — record payments (single or settle-all), with full history.
- **History** — every expense and settlement per group, with totals per
  member and per group.
- **Edit groups** — rename a group, add/remove members from the group screen.

## Data

Local SQLite only (sqflite). The app starts **empty** — no demo or sample
data, no network calls, no AI, no accounts.

## Tech

- Flutter 3.50, Dart, Material 3 (light + dark).
- Storage: `sqflite` (`sqflite_common_ffi` for tests).
- Money stored as integer paise — no floating-point rounding errors.

## Tests

```sh
flutter analyze   # 0 issues
flutter test      # unit + widget tests: money math, balance calculator,
                  # database CRUD, models, home/group UI
```

## Build

```sh
flutter build apk --release
```
