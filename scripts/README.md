# Scripts

This directory contains the various scripts that power the `control.sh` script in the project root.

- `bootstrap.sh` downloads/installs the various libraries and tools required to build the app. See the section below for details.
- `common.sh` contains common functions and variables used across all the scripts. If you're trying to find variables to tweak the build the build system, this would be a good place to start.
- `compile.sh` compiles the (patched) Firefox source code.
- `detect-os.sh` detects the operating system using the bash variable `$OSTYPE`.
- `download.sh` downloads and extracts the Firefox source code.
- `package.sh` packages the app after it's been compiled and puts the package in the build directory.
- `patch-build.sh` patches the Firefox build (after compilation), which basically involves installing SQLite Manager and the app launcher.
- `patch-source.sh` patches the Firefox source (before compilation), which includes things like setting the build flags, replacing brand names, and replacing icons.
- `patch-sqlite-manager.sh` patches the SQLite Manager extension. See the section below for details.

## bootstrap.sh

This script downloads/installs the various libraries and tools required to build the app. It used only by `control.sh setup`.

**Note:** this script expects some tools to be installed already. These instructions differ per OS. See the readme in the root of the repo.

## patch-sqlite-manager.sh

The unmodified source code for the SQLite Manager extension is stored in the repo. This script makes a few changes to that code, including brand and version changes.

This script can be used without `control.sh` to patch the extension:

```bash
cp -R sqlite-manager sqlite-manager-patched
scripts/patch-sqlite-manager.sh sqlite-manager-patched
```

**Why not store the modified source code in the repo instead of the original?**

Using a script to patch the source code makes it easy to tell what has been changed from the original, and more importantly, it makes it easy to upgrade the extension in the future.

**Okay, then why not download the code for the extension during the build, like what happens with the Firefox code?**

The Firefox source code is downloaded during the build because it would grow the size of this repo immensly. Not only that, but Firefox isn't going anywhere; the code is going to be available to download for a long time, whereas the extension could disappear.
