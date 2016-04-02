# dryrun 
[![Build Status](https://travis-ci.org/cesarferreira/dryrun.svg?branch=master)](https://travis-ci.org/cesarferreira/dryrun) [![Gem Version](https://badge.fury.io/rb/dryrun.svg)](http://badge.fury.io/rb/dryrun)

**Try** any **android library** hosted online **directly** from the **command line**

> A dry run is a testing process where the effects of a possible failure are intentionally mitigated. For example, an aerospace company may conduct a "dry run" test of a jet's new pilot ejection seat while the jet is parked on the ground, rather than while it is in flight.

<p align="center">
<img src="https://raw.githubusercontent.com/cesarferreira/dryrun/master/extras/usage_v2.gif" width="100%" />
</p>

## Usage
```bash
dryrun https://github.com/cesarferreira/android-helloworld
```

Wait a few seconds and the app is now opened on your phone :smiley:

### Advanced usage
```bash
$ dryrun -h                                                                                       
Usage: dryrun GIT_URL [OPTIONS]

Options
    -m, --module MODULE_NAME         Custom module to run
    -f, --flavour FLAVOUR            Specifies the flavour (e.g. dev, qa, prod)
    -p, --path PATH                  Custom path to android project
    -t, --tag TAG                    Specifies a custom tag to clone (e.g. "v0.4.5", "6f7dd4b")
    -h, --help                       Displays help
    -v, --version                    Displays version
```

## Installation

    $ gem install dryrun

## Goodies

- Private repos can be tested too :smiley:
```
  $ dryrun git@github.com:cesarferreira/android-helloworld.git
```

- No need to cleanup after you test the library.

- No need to wait for **Android Studio** to load.

## Alternative scenario (if you don't use `dryrun`)

1. Find the github's repository url
2. Click the `download zip`
3. Extract the `zip file`
4. Open Android Studio
5. Import the project you just downloaded
6. Sync gradle
7. Run the project
8. Choose the device you want to run
9. Test all you want
10. Delete the `project folder` and the `zip file` when you don't want it anymore

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cesarferreira/dryrun.
