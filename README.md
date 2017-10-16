# SQLite Composer

## Setup

First, install the tools that specified per OS below. Afterwards, run:

```bash
./control.sh setup
```

**Note:** you may be asked to enter your password to install the packages.

Once the setup completes successfully, restart your shell.

### Linux

Tools:

- curl
- build-essentials (gcc, make, etc)
- python2

### Mac

Tools:

- brew
- Xcode (make sure you've started it at least once)

If you just installed Xcode, make you sure you start it to finish the setup, and then run:

```bash
sudo xcode-select --switch '/Applications/Xcode.app'
```

### Windows

TODO

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

- Linux: the directory "~/.sqlitecomposer" is created automatically when running the program. This seems to be related to the crash reporter being disabled.
