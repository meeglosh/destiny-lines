# HANDOFF — Destiny Lines session state

Last updated: 2026-08-25 (after commit `dec691c`). Read alongside `CLAUDE.md` (the spec, which this file does not repeat).

## Where things stand

- **App is feature-complete for beta**: full pipeline (capture → gates → reading), history, share card, paywall UI, settings, global nav. Backend (Supabase Edge Functions + R2 + OpenAI) is deployed and verified end-to-end.
- **App Store account**: migrated to **GAPCO Limited Liability Company** — team `XM2SC5YZ8C`, bundle `com.destiny-lines.app` (commit `548a4ea`). Build numbering restarted at **1** on the new app record; build 1 was uploaded to TestFlight under GAPCO. The earlier Kenzora Games identifiers (`7K9WY5T49S`, `com.kenzoragames.Destiny-Lines`, builds 1–16) are historical.
- **UI consistency overhaul landed** (`dec691c`): all screens share one layout rule (per-asset baked-margin registry `ArtInsets.measured` in `ArtScreen.swift`; content width-fill, top-pinned via `ArtLayout.standardFrame`), nav bar flush to the physical bottom on all 5 tabs, READ is a resting Capture tab, back/close buttons at one fixed position via `ArtChrome`, Share/Reading-overview/Capture scroll instead of clipping, share insight rows re-paired to their icon wells, paywall full-bleeds its foot, and camera captures now crop to the viewfinder region (WYSIWYG) before Gate 1.
- **Tests**: full suite green (iPhone 17 destination). Local StoreKit testing is **broken at the toolchain level** on this machine (proven with a from-scratch control project) — `StoreManagerTests` is `.disabled` with evidence in comments; purchase UI tests self-skip. Not fixable locally.

## Open items (in rough priority order)

1. **TestFlight upload from a new session needs the GAPCO Issuer ID.** API key `AuthKey_9P25T9UA6L.p8` is in `~/.appstoreconnect/private_keys/` (user-confirmed as the GAPCO key), but its Issuer ID was never recorded. Ask the owner (App Store Connect → Users and Access → Integrations). Do not use `657V374P5H` / issuer `69a6de72-...` — that's the old Kenzora key.
2. **Subscriptions not yet created in App Store Connect** (owner task). Until then, purchases can't be tested anywhere (local StoreKit is broken, sandbox needs ASC products). Product IDs are in the constants file per CLAUDE.md §7.6.
3. **Art re-exports needed (owner/Photoshop)**: `bg_capture`, `bg_reading`, `bg_share`, `bg_paywall` have circular button wells baked in that now show as faint ghost rings near the standardized chrome. `bg_history`, `bg_list`, `bg_message` imagesets are unreferenced (delete or repurpose). After any re-export, re-measure margins and update `ArtInsets.measured` (method documented at the registry).
4. **Device test of the camera flow**: the viewfinder WYSIWYG crop fix (`ImageProcessor.crop(_:toAspect:)`, `PalmSubmission.submit(_:croppedToAspect:)`) can't be exercised in the simulator (no live camera). Verify on hardware once a GAPCO build is on TestFlight.
5. **`FREE_TIER_CEILING = 20`** in `supabase/functions/analyze-palm/index.ts` is a TEMPORARY beta override — **revert to 1 before public launch** (CLAUDE.md §6.5).
6. **Accessibility + Dynamic Type pass** (CLAUDE.md §13 step 14) — not started.
7. **Gate 1/Gate 3 threshold calibration** blocked on the owner's 200+ labeled photo set (CLAUDE.md §6.2a).

## Working conventions (established, follow these)

- **Never edit `project.pbxproj`** — change `project.yml`, run `xcodegen generate` (a `postGenCommand` patches the StoreKit config onto the test scheme).
- **Verify visually**: build, install to simulator, launch with `SIMCTL_CHILD_DEBUG_ROUTE=<route>` (routes incl. `home, read, capture, align, analyzing, rejection, reading, reading-indepth, reading-lines, share, history, history-empty, insights, settings, paywall` — see `RootView.applyDebugRoute`), screenshot via `xcrun simctl io ... screenshot`. Two verification sims: iPhone 17 `DB8808FC-92F7-408F-98E6-9FDCDCBDF048`, iPhone 17e `6ADFA513-CBC2-4561-BF54-25F7522AAE72`.
- **Overlay calibration** is done by pixel-measuring the art PNGs with python3/PIL/numpy (luminance scans + gridline crops), not by eye. `art.rect(...)` fractions are always relative to the **full raw image**, regardless of how the screen crops it.
- **Ship flow**: bump `CURRENT_PROJECT_VERSION` in `project.yml` → `xcodegen generate` → `xcodebuild archive` → `-exportArchive` (ExportOptions: `app-store-connect`, team `XM2SC5YZ8C`) → `xcrun altool --upload-app` with the GAPCO key.
- Reference screenshots for every screen live in `screenshots/` and are refreshed on each UI change.
