# GI Bowl

Glycemic index lookup

## Layout

This is the iOS app; the repo root (`~/code/gi`) is the GI Lookup PWA and its data pipeline, and the app bundles the PWA's `../public/foods.json`.

- `factory.yml` — the factory's manifest: slug `gi`, scheme `GIBowl`, bundle id `com.mph.GIBowl`, the icon set.
- `project.yml` — the XcodeGen spec (iOS 27.0: the label reader uses FoundationModels image attachments). The `.xcodeproj` is generated from it (`xcodegen generate`, which every `factory build` and `factory release` runs first) and is committed: commit it with the `project.yml` change that regenerated it. Change settings here, never in Xcode.
- `GIBowl/` — the app target: `GIBowlApp.swift`, views, the label reader, the tip jar and `Assets.xcassets` (the app icon, from the PWA's `public/icon.svg`).
- `Package.swift`, `Sources/GIBowlCore/`, `Tests/GIBowlCoreTests/` — the app's logic as a Swift package (`swift test`).
- `GIBowlTests/`, `GIBowlUITests/` — the app's test targets.
- `docs/release.md` — how a release goes, and what to do when it doesn't.
- `build/` — factory output (derived data, archives, staged install pages); ignored.

## Commands

- `factory doctor` — toolchain, team and this app's release readiness; one fix per failing line.
- `factory build ios --run` — build and run in the simulator.
- `factory release ios [--skip-upload]` — build, sign and publish to https://dist.puddingtime.net/gi/ios/install.html; `--skip-upload` stages only.
- `swift test` — the GIBowlCore tests.

## Rules

- SF Symbols only for icons in the UI; no emoji anywhere in the UI or the code.
- Never print secrets: keys, passwords, tokens or the Sparkle private key, in output, logs or commits.
- Never add release scripts here — shipping is the factory's. A release problem is fixed in `~/code/factory`.
- `project.yml` is the source of truth for build settings, Info.plist keys and entitlements.

## Shipping

Build, run and release through `factory` (`~/code/factory`); see the `apple-factory` skill for the commands and the papercut ledger.
Releases are routine: after a feature lands, run `factory release all` (it bumps the build number; add `--version X.Y.Z` for a new version) without asking.
When the Mac target changed (entitlements, Sparkle, signing), run `factory release all --skip-upload` first and install the staged build before uploading.
Never add release scripts to this repo: shipping is the factory's job, and a fix belongs in `~/code/factory`.
