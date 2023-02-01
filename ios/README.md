# iOS Coffee App

The coffee app is built and signed using the LS1 university account. To deploy the app on a device, the device needs
to be added to the account by an admin.

Visit [https://ls1-coffee.dse.cit.tum.de/app/index.html](https://ls1-coffee.dse.cit.tum.de/app/index.html) on the
device to install the app or an update.

## Building

```shell
git tag $version
fastlane build
git commit --amend --no-edit
git tag -f $version
```

Amending the previous commit and re-tagging it is necessary, as running `fastlane build` write the tag into `Info.plist`.
This is required so the app can check for updates and notify the user if there is one available.

## Releasing

Copy the app to `/srv/app/app.ipa` on the server and then update the `app_configuration.app_version` in the database.
