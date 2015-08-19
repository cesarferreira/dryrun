# dryrun
[![Gem Version](https://badge.fury.io/rb/dryrun.svg)](http://badge.fury.io/rb/dryrun)

**Try** an **android** library on your **smartphone** **directly** from the **command line**


> A dry run (or a practice run) is a testing process where the effects of a possible failure are intentionally mitigated. For example, an aerospace company may conduct a "dry run" test of a jet's new pilot ejection seat while the jet is parked on the ground, rather than while it is in flight.


## Typical scenario

1. Find the github url (lets say `https://github.com/cesarferreira/android-helloworld`)
2. Click the `download zip`
3. Extract the `zipfile`
4. Open Android Studio
5. Import the project you just downloaded
6. Sync gradle
7. Run the project
8. Choose the device you want to run

... or you can use `dryrun`:

## Usage
```bash
dryrun https://github.com/cesarferreira/android-helloworld
```

Wait a few seconds... and `voilà`! The app is installed and opened on your phone :smiley:


## Installation

    $ gem install dryrun

**Requirements `(if you haven't already)`:**

> $ANDROID_HOME defined on the environment variables [how-to](http://stackoverflow.com/questions/5526470/trying-to-add-adb-to-path-variable-osx)

**hint:** in your `~/.bashrc` add `export ANDROID_HOME="/Users/cesarferreira/Library/Android/sdk/"`

> Android SDK defined on the environment variables [how-to](http://stackoverflow.com/questions/19986214/setting-android-home-enviromental-variable-on-mac-os-x)

**hint:** in your `~/.bashrc` add `export PATH="/Users/cesarferreira/.rvm/bin:/Users/cesarferreira/Library/Android/sdk/platform-tools/:$PATH"`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cesarferreira/dryrun.
