fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Archive and upload to TestFlight (no App Store submission)

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload metadata (descriptions, keywords, screenshots) to App Store Connect — no binary

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and upload a new release to App Store Connect (TestFlight / review)

### ios finalize

```sh
[bundle exec] fastlane ios finalize
```

Submit the already-uploaded build for review (no rebuild) — clears export compliance

### ios submit_ipa

```sh
[bundle exec] fastlane ios submit_ipa
```

Upload an already-built IPA + localized metadata. Pass submit:true to also send it for review.

### ios store

```sh
[bundle exec] fastlane ios store
```

Build, upload the binary and localized metadata — but do NOT submit for review

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Generate localized screenshots (no upload). Validate them before shipping.

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload the screenshot sets only — no binary, no metadata

----


## Mac

### mac store

```sh
[bundle exec] fastlane mac store
```

Archive the Mac Catalyst app and upload it to App Store Connect (binary only, no review submission)

### mac upload_metadata

```sh
[bundle exec] fastlane mac upload_metadata
```

Upload the Mac listing's localized metadata (no binary)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
