# AGENTS.md — SASID App (Espectra CDMX)

Flutter app for NTC-CDMX seismic design spectra (NTC 2017/2023 & 2004). Engine: `lib/services/seismic_engine.dart`, models: `lib/models/seismic_models.dart`, GIS + chart + export in `lib/ui/`.

## Setup & Build

```bash
flutter pub get
flutter run -d windows   # Desktop primary target
flutter run -d chrome    # Web
flutter run              # Android/iOS device
flutter build windows
flutter build web
```

SDK: `^3.12.2` (Flutter >=3.20). Deps: `flutter_map`, `fl_chart`, `pdf`/`printing`, `http`, `intl`, `path_provider` (`pubspec.yaml`).

## Lint & Format

- Lints: `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`.
- No custom overrides; keep recommended rules enabled. Suppress per-line with `// ignore: name` only when justified.
- Formatter: `dart format` (2-space, 80/100 char Dart default). Run before commit.

```bash
flutter analyze
dart format lib/ test/
dart fix --dry-run
```

No Cursor (`.cursor/rules/`, `.cursorrules`) or Copilot (`.github/copilot-instructions.md`) rules present — follow this file.

## Test

```bash
flutter test                          # all tests
flutter test test/seismic_engine_test.dart          # single file
flutter test --name "Calculate Lomas Zone"         # single test by name
flutter test --name "Compute Spectrum"              # substring match
flutter test test/widget_test.dart                  # widget smoke test
flutter test --plain-name "Export Service generates" # exact name
```

Tests use `flutter_test` + `expect`. Widget test sets `tester.view.physicalSize = Size(1280,800)`. Engine tests in `test/seismic_engine_test.dart` cover: Lomas vs Lago zonation, `computeSpectrum` inelastic reduction (`elastic >= design`), NTC-2004 companions, `ExportService` SAP2000/CSV strings.

## Project Structure

```
lib/
  main.dart                 # SasidApp (MaterialApp, AppTheme.lightTheme)
  models/
    seismic_models.dart     # GeotechnicalZone, ImportanceGroup, IrregularityFactor, SeismicFactors, SiteParameters, SpectrumPoint, SpectrumResult
    cdmx_preset.dart        # CdmxPreset, CdmxPresets.landmarks/alcaldias
  services/
    seismic_engine.dart     # SeismicEngine.calculateSiteParameters / computeSpectrum
    geocoding_service.dart  # Nominatim + local catalog (4s timeout, dedup)
    export_service.dart     # generateSap2000Txt / generateCsv / exportPdfReport
  ui/
    theme/app_theme.dart    # AppColors, AppTheme.lightTheme
    screens/home_screen.dart
    widgets/{cdmx_map_view,factors_panel,parameters_card,spectrum_chart,comparison_grid,data_table_view,location_selector}.dart
test/
  seismic_engine_test.dart
  widget_test.dart
```

## Code Style

**Imports**: `dart:*` first, then `package:flutter/*` / `package:sasid_app/*`, then relative `../../`. Prefer `package:sasid_app/...` for cross-feature; relative only within same folder. Group and sort alphabetically.

**Formatting**: `dart format`; no semicolon-less style. Trailing commas for multiline params. `const` constructors wherever possible (`const SeismicFactors()`).

**Types & Null Safety**: Strong typing; avoid `dynamic`. Use `required` named params. Use `final`/`const` by default. Null-aware: `double.tryParse`, `as String? ??`, `?.`. Enums carry fields (see `GeotechnicalZone` with `name/shortName/color/description`). Data classes are immutable with `copyWith`.

**Naming**:
- Classes/enums: `PascalCase` (`SeismicEngine`, `GeotechnicalZone`).
- Files: `snake_case.dart`.
- Variables/params/methods: `camelCase`; booleans `showEpu`, `showComparison2004`.
- Enum values: `camelCase` (`zonaI`, `grupoB`, `regular`).
- Constants: `camelCase` or `lowerCamel` (`AppColors.spectrumDesign`).

**Widgets**: `StatelessWidget`/`StatefulWidget` with `const` ctor `super.key`. Keep `build` pure; state in `HomeScreen` holds `_currentLat/_currentLon/_factors/_result` and calls `_recalculate()`. Use `AppColors`/`AppTheme` — no hardcoded theme colors.

**Models**: River-like spectra discretized `T ∈ [0,5.0]` with `dt=0.02` (251 points), rounded via `double.parse(x.toStringAsFixed(3))`. Preserve that rounding.

## Error Handling

- Clamp inputs: `lat.clamp(19.05,19.65)`, `lon.clamp(-99.40,-98.85)`, `lakeIndex.clamp(0,1)`.
- HTTP: `http.get(...).timeout(Duration(seconds:4))`; empty `catch (_) {}` = transparent offline mode — keep it.
- Geocoding dedup: `(lat-lon).abs() < 0.001`.
- Spectrum: `ad = max(ad, aMin)` where `aMin = a0*I/(2*R0*α)`; never return `NaN`.

## Domain Rules

- Keep NTC formulas intact (`a_e(T)` piecewise, `a_d = I·a_e/(Q'·R'·α)`). `Q'/R'` interpolate for `T < Ta`.
- `R0` from `Q`: `Q>=3→2.0*k1`, `Q>=2→1.75*k1`, `Q>=1.5→1.5*k1`, else `1.0`.
- EPU = `1.10 * I * ae`. NTC-2004 companions only when `showComparison2004`.
- Exports: SAP2000 `$`-header + `\t` TSV; CSV `"Propiedad","Valor"` UTF-8; PDF via `pdf`/`printing` letter, `PdfColor.fromHex('0F172A')`.

## Additional Commands

```bash
flutter pub outdated             # check upgrades
flutter pub upgrade --major-versions
flutter clean && flutter pub get # reset build
dart run build_runner --delete-conflicting-outputs # if codegen added
```

Coverage (excluded by `.gitignore:/coverage/`):

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Style Details

- **Line length / docs**: Follow `flutter_lints` defaults. Doc comments use `///` Spanish (e.g., `/// Obtiene los parámetros del sitio`). Keep them.
- **Const & keys**: Widgets always `const` when possible; use `super.key` shorthand.
- **Color constants**: Use `AppColors` (e.g., `primary 0xFF0F172A`, `accent 0xFF2563EB`, `spectrumDesign 0xFF2563EB`). Never duplicate hex.
- **State**: `HomeScreen` is source of truth; prefer `setState` + `_recalculate()`. Factors updated via `copyWith`.
- **Async**: `GeocodingService.searchAddress` and `ExportService.exportPdfReport` are `Future`; always `await` and handle empty results gracefully.
- **Intl/numbers**: Use `NumberFormat`/`DateFormat` from `intl` for display; store raw `double` with `toStringAsFixed(3/4/6)` only at export boundary.

## Anti-Patterns

- Do not add new lints without team approval; `analysis_options.yaml` is intentionally minimal.
- Do not use `print`/`debugPrint` in production — use `debugPrint` guarded or remove before commit (`avoid_print` lint).
- Do not change `dt=0.02` or rounding without updating tests and export snapshots.
- Do not hardcode CDMX viewbox; reuse `-99.38,19.05,-98.88,19.60` and Nominatim `User-Agent: SASID_Flutter_App/1.0`.

## Language & Comments

UI strings, PDF, and most doc-comments are Spanish. Keep Spanish for user-facing text; code identifiers remain English. No added comments unless requested — match existing Spanish `///` style.

## Git & Workflow

- Branch from `main`; run `flutter analyze && flutter test` before PR.
- Commit message: Spanish or English, imperative (`feat: add EPU toggle`).
- Do not commit `.dart_tool/`, `build/`, `*.log`, `coverage/`, `.pub-cache/`. Do not edit `generated_plugin_registrant.*`, `GeneratedPluginRegistrant.swift`, or `.flutter-plugins-dependencies`.
- For new deps: `flutter pub add <pkg>` then commit `pubspec.yaml` + `pubspec.lock`.
