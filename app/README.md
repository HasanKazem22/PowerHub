# PowerHub: mobile app

Electrical design calculators for Android and iOS (`com.beartech.powerhub`), by **Bear Tech**. Built on the
BearTrack codebase: the same design kit, page pattern, offline database and Google Drive backup.

Everything works offline with **no account and no server**. Projects are kept in a SQLite database on the phone
(Drift); the optional backup goes straight to the user's own Google Drive.

## Run

```
flutter pub get
flutter run            # on a connected phone or emulator
flutter test           # calculators, History, backup, every calculator screen and PDF report
flutter analyze
```

After changing tables in `lib/data/database.dart`: `dart run build_runner build`. Dates are stored as ISO text
with milliseconds (`build.yaml`); bump `schemaVersion` and add a migration when a released table changes.

### Google Drive backup (one step before it works)

The Web client ID in `lib/core/config/app_config.dart` is BearTrack's Google Cloud project. Google sign-in on
Android only works for a package + signing key registered in that project, so **add PowerHub once**:

1. Google Cloud console → the BearTrack project → **Credentials → Create OAuth client ID → Android**.
2. Package `com.beartech.powerhub`, and the SHA-1 of each signing key (`cd android; ./gradlew signingReport`:
   debug, release, and Google Play's app signing key). One Android client per SHA-1.
3. Optional: OAuth consent screen app name (it shows "BearTrack" on the Google consent page until changed), or
   use a separate PowerHub project and pass its Web client ID with `--dart-define-from-file=config/dev.json`.

Both apps can share the project safely: PowerHub's Drive files are named `powerhub-backup-*` and
`powerhub-key.json` (BearTrack's are `beartrack-*`), and each app refuses the other's backups.

## What it does

| Calculator | Sizes | From the web version's tabs |
|---|---|---|
| Building load | Units (3 stages) → FDBs → MDB breaker, cable, busbar → standby generator | Load, FDB, MDB, Generator |
| Substation sizing | Transformer, HV switchgear, LV incomer, fault level, CT/PT, relay, earthing, LA/SPD, PFC | Substation |
| Power factor | kVAR, plain / detuned bank, steps, fuses, contactors, incomer, CT | Power Factor |
| Solar PV | On-grid, off-grid, hybrid, net metering: array, strings, inverter, cables, protection, battery | Solar |
| Motor starter | FLC, overload relay, contactors, breaker, cable with voltage drop | Motor Selection |
| Motor rewinding | Winding layout, factors, turns, wire, phase start slots, resistance, copper | Motor Rewinding |
| Earthing & busbar | Electrodes, earth conductor, busbar | Earthing, Busbar |

Plus the **Guide** tab: the fault-finding and safety guide in Bangla (`assets/data/faults.json`, 14 equipment
groups, 46 faults), searchable.

**History:** Save on any calculator stores its inputs under a project name (`projects` table). Results are never
stored; they are worked out again when a project opens, so newer formulas apply to old projects. Work in progress
is kept per calculator (`drafts` table, this phone only, not backed up). Projects can be renamed, duplicated,
deleted and shared as a PDF report (designer: full working; customer: summary).

## Structure

```
lib/
  core/            config, constants, routing (app_routes, app_router, app_shell, app_actions), theme tokens
  data/            database.dart (projects, drafts, settings), providers.dart, backup/ (file + Google Drive)
  features/
    calc/
      domain/      calc_module.dart (fields, groups, CalcModule.run), calc_inputs.dart, calc_result.dart,
                   electrical_tables.dart (breakers, cables, derating, busbars, CTs)
      modules/     one file per calculator (+ load_editor.dart), modules.dart: the ordered list
      presentation calc_screen.dart: the one screen every calculator uses; widgets/ inputs and result cards
      report/      calc_report.dart (PDF on the phone), share_report.dart
    home/ history/ guide/ settings/ backup/ onboarding/ splash/
  shared/          the Bear Tech design kit (AppPage, cards, lists, sheets, inputs, glossy nav)
```

**Add a calculator**
1. `features/calc/modules/<id>_module.dart`: a `CalcModule` with its fields (grouped; long or rarely changed ones
   in an `advanced` group), `defaults` for every field, and a pure `compute` returning a `CalcResult` (headline,
   up to three metrics, sections, issues with optional one-tap `patch`, steps, `basis`). Mark inputs that are
   divided by as `positive: true`.
2. Add it to `calcModules` in `modules.dart`. Home, the "+" menu, History, routing and reports pick it up.
3. Add `test/<id>_module_test.dart` with hand-checked numbers. `calc_engine_test.dart` already checks that every
   field has a default and that no option, zero, negative or junk input throws; `calc_screens_test.dart` opens it.
4. Never change a released calculator's `id` or input keys: saved projects use them.

**Rules** (as in BearTrack): build screens from `shared/widgets`; use the tokens in `core/theme` instead of raw
numbers and colours; forms open in bottom sheets; up to about 5 options are chips, longer lists use the choice
sheet. The calculations follow the original web calculator (`../PowerHub.html`); confirm final designs with
manufacturer data and the utility.

## Design

BearTrack's look in PowerHub colours: electric blue (`#1656D6`) with spark amber (`#FFB627`) on a cool off-white
page, glossy cards and buttons, frosted top and bottom bars, and the drawn bottom-bar icon class (one rounded
stroke; the active tab fills solid with a white detail): Home · History · New · Guide · Settings. The logo is the
wordmark **Power**Hub; the launcher icon is rendered from it:

```
flutter test tool/render_logo_test.dart     # writes assets/images/*.png
dart run flutter_launcher_icons
```
