# Google Play Developer API — service account setup

Lets tools (fastlane, GitHub Actions, `gradle-play-publisher`) upload builds to
Play instead of dragging the `.aab` into the Console by hand.

The key is created in Google Cloud Console and authorised in Play Console. Both
need a browser login — nothing here can be generated locally.

## 1. Link a Cloud project

Play Console → **Settings** (gear, top right) → **Developer account** → **API access**.

Accept the terms, then either create a new Google Cloud project or link an
existing one. One project per developer account is fine.

### Reusing an existing service account

If another of your apps already publishes through a service account, you do not
need a new key — reuse it and skip to step 4. Play permissions are granted
**per app**, so an account authorised for one app has no rights over EduBuddy
until you add it there explicitly.

## 2. Create the service account

Still on the **API access** page, under *Service accounts*, click
**Create new service account**. This opens Google Cloud Console.

In Cloud Console:

1. **IAM & Admin → Service Accounts → Create service account**
2. Name: `play-publisher` (anything works)
3. **Skip** the "Grant this service account access to project" step — permissions
   are granted on the Play side, not here.
4. **Done**

## 3. Download the JSON key

Open the new service account → **Keys** tab → **Add key** → **Create new key** →
choose **JSON** → **Create**.

The file downloads immediately. Google keeps no copy — lose it and you create a
new one.

Move it to:

```
android/play-service-account.json
```

That path is already gitignored (`.gitignore:55`). Never commit it — it grants
upload rights to the live listing.

## 4. Grant it access in Play Console

Back on Play Console → **API access** → **Refresh service accounts**. The new
account appears. Click **Manage Play Console permissions** → **Grant access**.

- **App permissions**: restrict to **EduBuddy** only, not the whole account.
- **Releases**: tick *Release apps to testing tracks* and *Release to production,
  exclude devices, and use Play App Signing*.
- **Invite user** → **Send invite**.

Permissions can take a few minutes to propagate; occasionally longer.

## Important: this does not cover your first production release

The API uploads builds to an app that already has a production release. Your
**first** production release must be created manually in the Console, and it also
has to clear Google's review. Use the API for releases after that.

## Publishing

Uploads go through [Gradle Play Publisher][gpp], wired into the Android build.
No Ruby or fastlane — macOS ships Ruby 2.6 and fastlane needs 2.7+.

Build the bundle, then publish:

```sh
flutter build appbundle --release
cd android
./gradlew publishReleaseBundle                     # internal track
./gradlew publishReleaseBundle -Ptrack=production  # production
```

Two deliberate safety defaults in `app/build.gradle.kts`:

- **track defaults to `internal`**, so a bare `publishReleaseBundle` cannot
  reach real users by accident. Production requires `-Ptrack=production`.
- **`releaseStatus` is `DRAFT`**, so uploads appear in Console for review and do
  not roll out until you press the button.

Remember to bump `version:` in `pubspec.yaml` first — Play rejects a versionCode
that has already been uploaded.

If `android/play-service-account.json` is missing, the build still works
normally; only the publish tasks fail, and they tell you why.

`./gradlew` needs a JDK on `PATH`. Flutter finds its own when you run
`flutter build`, but a bare gradlew call does not — set `JAVA_HOME`, or run
through Android Studio's terminal.

[gpp]: https://github.com/Triple-T/gradle-play-publisher

## Rotating / revoking

Cloud Console → the service account → **Keys** → delete the old key after adding
a new one. Revoking access entirely: Play Console → **Users and permissions** →
remove the service account.
