# SQLite Composer

## Setup

First, install the tools that are specified per OS below. Afterwards, run:

```bash
./control.sh setup
```

**Note:** you may be asked to enter your password to install packages.

**Note:** on Windows, `control.sh` is expected to be run using the shell provided by MozillaBuild.

### Linux

Tools:

- build-essentials (gcc, make, etc)
- curl or wget
- python2
- rust

### Mac

Tools:

- rust
- Xcode

If you just installed Xcode, make you sure you start it to finish the setup, and then run:

```bash
sudo xcode-select --switch /Applications/Xcode.app
```

### Windows

Tools:

- Visual Studio Community 2015 with Update 3 ([link](https://www.visualstudio.com/vs/older-downloads/))
	- Check "Programming Languages -> Visual C++ -> Common Tools for Visual C++ 2015" during install
	- Uncheck "Windows and Web Development -> (all)" during install
- Rust
- MozillaBuild ([direct link](https://ftp.mozilla.org/pub/mozilla.org/mozilla/libraries/win32/MozillaBuildSetup-Latest.exe))

## Building

To build:

```bash
./control.sh build
```

To package:

```bash
./control.sh package
```

The packaged app can be found in `build/`.

## Issues

- Any buttons that would normally open a webpage (like clicking the link within the help menu) doesn't do anything.
- Mac: the application is installed as "SQLiteComposer.app" instead of "SQLite Composer.app". `MOZ_MACBUNDLE_NAME` doesn't appear to have any effect.
- Mac: the installer background image is missing, despite it existing in ".background/" within the dmg. May have something to do with the "dsstore" in the branding directory.
