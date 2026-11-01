# Releasing GI Bowl

GI Bowl ships through the factory (`~/code/factory`) to https://dist.puddingtime.net/gi/. The routine is the same for every app, and it is routine: release after a feature lands. The `apple-factory` skill holds the details and the papercut ledger.

## The routine

**Check.** Run `factory doctor` from anywhere in this repo. It checks the toolchain, the team's signing keychain and secrets, and this app's manifest, profiles and Sparkle key, one line each. Fix every `FAIL` line before going on; each one names its fix.

**Build.** Run `factory build ios --run` to build and launch the app in the simulator, and `factory build mac` for the Mac app. This is the quick look that the feature works before anything is signed.

**Stage.** Run `factory release all --skip-upload`. It bumps the build number, archives, signs and exports each platform and stages the install pages under `build/`, but uploads nothing. Do this first whenever the Mac target changed (entitlements, Sparkle, signing), and install the staged DMG from `build/mac` to check it opens and updates.

**Publish.** Run `factory release all`. It does everything the staging run did, then uploads to the dist bucket, refreshes the dist front page and commits the version bump. Add `--version X.Y.Z` to start a new marketing version.

**Install.** Open https://dist.puddingtime.net/gi/ on the device (iOS) or the Mac and install from the page. Installed Mac copies update themselves through Sparkle from then on.

## What to do when

**The iOS install fails with "unable to install" (device not registered).** The device's UDID is not in the team's ad-hoc profile. Register the device in the developer portal, then release again so the IPA is signed with the refreshed profile. See the papercut ledger in the `apple-factory` skill.

**A Mac release stops on a profile (expired, missing, or the wrong certificate).** Run `factory profiles --check` to see which, then `factory profiles` to fetch fresh Developer ID profiles. `factory doctor` reports the same thing.

**The release says the build is "already published".** That version and build number are already on dist. Release again without `--no-bump` (the default bumps the build), or with `--version X.Y.Z`.

**A keychain prompt appears, or signing fails with errSecInternalComponent.** The signing keychain needs its one-time "Always Allow" step, or it is locked. Run `factory keychain` in Terminal (it is attended) and see the ledger in the `apple-factory` skill for the three causes of errSecInternalComponent.
