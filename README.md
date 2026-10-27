# Betterbird AppImage

AppImages for [Betterbird](https://www.betterbird.eu), a free and open-source email client. Built from the official release tarball and published as versioned GitHub Releases.

## Get it

Download the latest `Betterbird-<version>-x86_64.AppImage` from [Releases](https://github.com/erickCantu/betterbird-appimage/releases/latest), make it executable, and run it:

```sh
chmod +x Betterbird-*-x86_64.AppImage
./Betterbird-*-x86_64.AppImage
```

## Update

Each AppImage carries zsync update information pointing at this repository. Update with [AppImageUpdate](https://github.com/AppImage/appimageupdate):

```sh
./appimageupdate Betterbird-*-x86_64.AppImage
```

Your mail stays in the normal Betterbird profile (standard mbox/eml) — nothing is locked into the AppImage.
