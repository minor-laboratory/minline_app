fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android internal

```sh
[bundle exec] fastlane android internal
```

Deploy to internal testing track

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Deploy to production

### android metadata

```sh
[bundle exec] fastlane android metadata
```

Update metadata only

### android screenshots

```sh
[bundle exec] fastlane android screenshots
```

Update screenshots only

### android promote_internal

```sh
[bundle exec] fastlane android promote_internal
```

Promote latest draft release to completed on internal track

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
