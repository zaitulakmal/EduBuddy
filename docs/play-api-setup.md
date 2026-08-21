# Google Play Developer API — service account setup

Lets tools (fastlane, GitHub Actions, `gradle-play-publisher`) upload builds to
Play instead of dragging the `.aab` into the Console by hand.

The key is created in Google Cloud Console and authorised in Play Console. Both
need a browser login — nothing here can be generated locally.

## 1. Link a Cloud project

Play Console → **Settings** (gear, top right) → **Developer account** → **API access**.

Accept the terms, then either create a new Google Cloud project or link an
existing one. One project per developer account is fine.

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

## Verifying it works

With fastlane installed:

```sh
cd android
fastlane run validate_play_store_json_key json_key:play-service-account.json
```

Prints the account and confirms the key authenticates.

## Rotating / revoking

Cloud Console → the service account → **Keys** → delete the old key after adding
a new one. Revoking access entirely: Play Console → **Users and permissions** →
remove the service account.
