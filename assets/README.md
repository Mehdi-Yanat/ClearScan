# ClearScan - Design Handoff

Artboard: 390 x 800 dp (Android). Font: Poppins (400/500/700). Bottom nav 84dp with a 72dp center scan FAB.

## Folders
- `01_overview/`   all 16 screens + design system in one image (PNG + SVG)
- `02_screens/`    each screen on its own: `png@2x/` (780x1600), `png@3x/` (1170x2400), `svg/` (vector)
- `03_splash_assets/`  splash logos (light/dark), Android 12 icon, branding, wordmarks, app icon source, `flutter_native_splash.yaml` (see its README)
- `04_design_system/`  `design_tokens.json` and `app_theme.dart` (Flutter colors + theme starter)

## Screens
| # | Screen | File | Notes |
|---|--------|------|-------|
| 01 | Splash | `01_splash` | Native splash, then fade into app. Light/dark variants. |
| 02 | Onboarding | `02_onboarding` | First launch only. Skip + Get Started. |
| 03 | Home | `03_home` | Hero CTA, quick actions, recent docs, center scan FAB. |
| 04 | Documents | `04_documents` | Search, filter chips, folders, files, favorites. |
| 05 | Scanner | `05_scanner` | Live camera, auto edge detection, mode selector. |
| 06 | Crop / Adjust Edges | `06_crop_adjust_edges` | 4 corner + 4 edge handles, rotate, retake, add page. |
| 07 | Enhance & Save | `07_enhance_save` | Filters, brightness / contrast, name, format, save. |
| 08 | Folder (multi-select) | `08_folder_multi_select` | Select mode with bottom action bar. |
| 09 | Document Viewer | `09_document_viewer` | Page preview, thumbnails, share / sign / OCR / edit. |
| 10 | Workshop (Tools) | `10_workshop_tools` | Convert, Edit PDF grid, more tools list. |
| 11 | OCR Result | `11_ocr_result` | Editable text, language, copy & export TXT/DOCX/PDF. |
| 12 | Sign Document | `12_sign_document` | Draw / type / image signature, place & resize. |
| 13 | QR Scanner | `13_qr_scanner` | Scan + result sheet: copy, share, open, create. |
| 14 | Profile | `14_profile` | Account, storage meter, preferences list. |
| 15 | Settings | `15_settings` | Grouped toggles & value rows. |
| 16 | Share Sheet | `16_share_sheet` | Modal bottom sheet over viewer. |

## Notes for the developer
- Icons are 24dp outline icons, stroke 1.8 (Material Symbols Rounded / Lucide are close matches).
- Sample data (John Doe, INV-2387, etc.) is placeholder only.
- Corner radii: cards 18, buttons 14, chips pill, bottom sheets 28. Spacing: 8dp grid, 24dp screen padding.
