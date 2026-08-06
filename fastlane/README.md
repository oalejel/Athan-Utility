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

Upload an already-built IPA + localized metadata and submit for review

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Generate new localized screenshots

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
