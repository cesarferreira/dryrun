<!--<p align="center">
  <a href="https://github.com/cesarferreira/dryrun" target="_blank">
    <img width="200"src="extras/gift.gif">
  </a>
</p>-->
<h1 align="center">dryrun</h1>
<p align="center"><strong>Try any android library</strong> hosted online <strong>directly</strong> from the <strong>command line</strong></p>
<p align="center">
 <a href="https://github.com/cesarferreira/dryrun"> <img alt="Gem Total Downloads" src="https://img.shields.io/gem/dt/dryrun"></a>
  <a href="https://github.com/cesarferreira/dryrun"><img src="https://badge.fury.io/rb/dryrun.svg" alt="npm"></a>
  <a href="http://androidweekly.net/issues/issue-200"><img src="https://img.shields.io/badge/Android%20Weekly-%23200-blue.svg" alt="Android Weekly"></a>
<a href="https://github.com/cesarferreira/dryrun/issues?q=is%3Aissue+is%3Aclosed"><img src="https://img.shields.io/github/issues-closed-raw/cesarferreira/dryrun.svg?color=%23FF69B4" alt="Closed"></a>

</p>

<p align="center">
  <img src="extras/ss.gif" width="100%" />
</p>

## Install

```sh
gem install dryrun
```

## Usage

```bash
dryrun https://github.com/cesarferreira/android-helloworld
```

Wait a few seconds and the app is now opened on your phone :smiley:

```bash
$ dryrun -h
Usage: dryrun GIT_URL [OPTIONS]

Options
    -m, --module MODULE_NAME         Custom module to run
    -b, --branch BRANCH_NAME         Checkout custom branch to run
    -f, --flavour FLAVOUR            Custom flavour (e.g. dev, qa, prod)
    -p, --path PATH                  Custom path to android project
    -t, --tag TAG                    Checkout tag/commit hash to clone (e.g. "v0.4.5", "6f7dd4b")
    -c, --cleanup                    Clean the temporary folder before cloning the project
    -w, --wipe                       Wipe the temporary dryrun folder
    -h, --help                       Displays help
    -v, --version                    Displays the version
    -a, --android-test               Execute android tests
```

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

## Goodies

- Private repos can be tested too :smiley:
```
  $ dryrun git@github.com:cesarferreira/android-helloworld.git
```
- No need to cleanup after you test the library.
- No need to wait for **Android Studio** to load.


## Notes

Be aware that `$ANDROID_SDK_ROOT` environment variable needs to be set. See more in [here](https://developer.android.com/studio/command-line/variables#set)

Additionally, on windows in order to use git commands, the following path should be on the environment variable
  - ```...\Git\cmd ```

## Created by
[Cesar Ferreira](https://cesarferreira.com)

## License
MIT © [Cesar Ferreira](http://cesarferreira.com)
