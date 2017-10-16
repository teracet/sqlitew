# SQLite Composer

## Setup

On Linux, make sure you have:

- curl
- build-essentials (gcc, make, etc)
- python2

On Mac, make sure have:

- brew
- Xcode (make sure you've started it at least once)

On Windows, make sure have:

TODO

Once you've installed those tools, run:

```bash
./control.sh setup
```

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
