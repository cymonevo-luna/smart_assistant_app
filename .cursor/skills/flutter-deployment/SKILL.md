---
name: flutter-deployment
description: Build and ship a Flutter app's Android .apk through the luna deploy pipeline (GitHub master push -> luna_jenkins webhook -> APK build on the host -> upload to the shared Nextcloud). Use whenever the user wants to deploy, release, build-and-ship, or wire up CI/CD for a Flutter app cloned from flutter_template, configure its Jenkins deploy job, or change how/where its APKs are uploaded.
---

# Flutter App Deployment (APK -> Nextcloud)

Every Flutter app in luna is cloned from `flutter_template` and ships its
Android `.apk` through the shared `luna_jenkins` deploy runner. This skill is the
single source of truth for that flow and works the same for local agents and
cloud Agents (it is committed in the template's `.cursor/skills/`, so every
clone inherits it).

## Pipeline at a glance

```
GitHub (push to master)
  └─ .github/workflows/deploy-webhook.yml   POST push payload + token
       └─ luna_jenkins  /generic-webhook-trigger/invoke?token=…
            └─ deploy-<app> job  (genericTrigger filters repo + refs/heads/master)
                 │   BUILD_TYPE defaults to "debug" on auto-trigger
                 └─ SSH to the deploy host  (flutter-build-on-host.sh)
                      └─ checkout ref + stage .env + rclone.conf
                           └─ <app>/scripts/deploy-apk.sh <build_type>
                                ├─ scripts/build-apk.sh   (flutter build apk)
                                └─ scripts/upload-apk-to-nextcloud.sh  (rclone -> Nextcloud)
```

### Deployment stages (the contract)

1. **Trigger from GitHub** — on merge/push to `master`, `deploy-webhook.yml`
   POSTs the push details to the Jenkins Generic Webhook Trigger (same pattern as
   the backend services).
2. **Receive in Jenkins** — the per-app `deploy-<app>` job matches on repo +
   `refs/heads/master` and starts a build.
3. **Build the `.apk`** — `flutter build apk` runs on the deploy host for the
   selected build type.
4. **Upload to Nextcloud** — the APK is uploaded with `rclone` (WebDAV) into the
   shared apps folder.

### Nextcloud layout

Uploads go to a `nextcloud` rclone WebDAV remote whose URL points at the target
account's files root (e.g. `https://cloud.example.com/remote.php/dav/files/USER`).
An optional `NEXTCLOUD_BASE_DIR` prefixes every app folder (e.g. `luna-apps`).

Each app gets its OWN folder named after the app (the pubspec `name`), and inside
it two folders:

```
<NEXTCLOUD_BASE_DIR>/<AppName>/
  debug/      # development APKs
  release/    # release APKs
```

- **debug/** holds development builds. **Auto-deploys (master push) always go
  here** — the Jenkins `BUILD_TYPE` defaults to `debug`.
- **release/** holds release builds — produced only when someone manually runs
  the Jenkins job and picks `release` from the **BUILD_TYPE** dropdown.

`rclone` creates the `<AppName>/<debug|release>/` folders automatically. Uploaded
file name: `<AppName>-v<version>-<buildType>-<shortSha>-<UTCstamp>.apk`.

## Files this flow depends on

In the Flutter app (inherited from `flutter_template`):

- `.github/workflows/deploy-webhook.yml` — fires the Jenkins webhook on master.
- `scripts/build-apk.sh` — `flutter pub get` + `build_runner` codegen +
  `flutter build apk --<type>`. Prints the APK path on its last stdout line.
- `scripts/upload-apk-to-nextcloud.sh` — uploads one APK to `<AppName>/<type>/`
  via `rclone` (WebDAV). Honors `NEXTCLOUD_REMOTE`, `NEXTCLOUD_BASE_DIR`,
  `APP_NAME`, `RCLONE_CONFIG`.
- `scripts/deploy-apk.sh <debug|release>` — the single entry point Jenkins calls;
  builds then uploads.

In `luna_jenkins` (the shared deploy runner):

- `pipelines/flutter-deploy.Jenkinsfile` — the shared Flutter deploy pipeline
  (`BUILD_TYPE` + `GIT_REF` params; SSHes to the host and runs the build script).
- `jobs/flutter-deploy.groovy` — Job DSL seed; generates one `deploy-<app>` job
  per entry in its `flutterServices` list.
- `scripts/flutter-build-on-host.sh` — runs on the deploy host: clones/checks out
  the app, stages `.env` + `rclone.conf`, runs the app's `scripts/deploy-apk.sh`.
- `casc/jenkins.yaml` — credentials (`<APP>-env`, `nextcloud-rclone-conf`,
  `github-ssh`, `deploy-host-ssh`, `webhook-token`) + registers the seed.

## Enable deployment for a NEW Flutter app

Assume the app repo `cymonevo-luna/<app>` was cloned from `flutter_template`.

1. **GitHub repo secrets** (Settings -> Secrets and variables -> Actions):
   - `LUNA_DEPLOY_WEBHOOK_URL` = `https://<jenkins-host>/generic-webhook-trigger/invoke`
   - `LUNA_DEPLOY_WEBHOOK_TOKEN` = the same value as `WEBHOOK_TOKEN` on luna_jenkins.
   The inherited `deploy-webhook.yml` needs nothing else.

2. **Register the app in luna_jenkins** — add the repo name to the
   `flutterServices` list in `luna_jenkins/jobs/flutter-deploy.groovy`:
   ```groovy
   def flutterServices = ['<app>']
   ```

3. **Add the app's env credential** in `luna_jenkins/casc/jenkins.yaml` (so the
   build gets the right `.env`):
   - add a `string` credential `id: "<app>-env"` reading `${<APP>_ENV}`,
   - add `<APP>_ENV` to the `SECRET_FILES` list in
     `luna_jenkins/scripts/refresh-daemon.sh`,
   - drop the real `.env` contents in `luna_jenkins/secrets/<APP>_ENV`
     (uppercased, never committed; keep a `*.example` placeholder).

4. **Nextcloud credential** (once for all apps): configure an `rclone` WebDAV
   remote named `nextcloud` with access to the target account and store its
   `rclone.conf` as the `nextcloud-rclone-conf` Jenkins credential (file
   `luna_jenkins/secrets/NEXTCLOUD_RCLONE_CONF`). See "Nextcloud / rclone" below.

5. **Deploy host prerequisites** (one-time): the host must have the Flutter SDK,
   the Android SDK/`ANDROID_HOME` (+ a JDK), and `rclone` on the deploy user's
   PATH. Verify with `flutter doctor` and `rclone version`.

6. **Apply the Jenkins changes**: rebuild/restart the controller via
   `luna_jenkins/scripts/refresh-daemon.sh` so the seed regenerates the
   `deploy-<app>` job.

After this, a push to `master` auto-builds and uploads a **debug** APK; running
the job manually lets you pick **debug** or **release**.

## Triggering a release (debug vs release)

- **Auto (master push):** always `debug` -> `<AppName>/debug/`.
- **Manual:** open the `deploy-<app>` job in Jenkins -> **Build with Parameters**
  -> set **BUILD_TYPE** = `release` (or `debug`) and optionally **GIT_REF**
  (branch or tag) -> Build. A `release` build lands in `<AppName>/release/`.

## Nextcloud / rclone setup

`rclone` uploads to Nextcloud over WebDAV. Recommended: a dedicated Nextcloud
user with an **app password** (Settings -> Security -> Devices & sessions ->
Create new app password), so the real account password is never used on CI.

1. Find the account's WebDAV files root:
   `https://<nextcloud-host>/remote.php/dav/files/<username>`.
2. Build an `rclone.conf` with a `[nextcloud]` WebDAV remote, e.g.:
   ```ini
   [nextcloud]
   type = webdav
   url = https://cloud.example.com/remote.php/dav/files/deploybot
   vendor = nextcloud
   user = deploybot
   pass = <obscured>   # produce with: rclone obscure '<app-password>'
   ```
   The `pass` value MUST be obscured with `rclone obscure` — rclone does not
   accept a plaintext WebDAV password in its config.
3. Store that `rclone.conf` as the `nextcloud-rclone-conf` Jenkins credential. The
   pipeline stages it to the host and exports `RCLONE_CONFIG` before building.

The upload script targets `<NEXTCLOUD_BASE_DIR>/<AppName>/<type>/<file>.apk`
relative to the remote's root. Set `NEXTCLOUD_BASE_DIR` (pipeline env, default
`luna-apps`) to group every app under one folder; leave it empty to upload at the
remote root.

## Local build / manual upload

```bash
scripts/build-apk.sh debug                 # build only; prints the .apk path
scripts/deploy-apk.sh release              # build + upload (needs rclone + nextcloud remote)
APK=$(scripts/build-apk.sh release | tail -n1)
scripts/upload-apk-to-nextcloud.sh "$APK" release
```

## Conventions & gotchas

- **Template-first:** this deployment is core functionality. Change the scripts,
  workflow, or this skill in `flutter_template` first (PR to its repo), then
  propagate to the cloned apps. Per-app one-offs (e.g. release signing config)
  may live in the app.
- **`.env` is a bundled asset** (`pubspec.yaml` -> `assets: - .env`), so a build
  fails without one. Jenkins stages the per-app `.env` from the `<app>-env`
  credential; `build-apk.sh` falls back to `.env.example` for local builds.
  Upload credentials are NOT kept in this `.env` (it ships inside the APK); they
  live server-side in the `nextcloud-rclone-conf` Jenkins credential.
- **Code generation runs before the build** (`build_runner`) because the
  template uses `freezed`/`json_serializable`. Set `SKIP_CODEGEN=1` to skip.
- **Release signing** is app-specific. Without an Android signing config,
  `flutter build apk --release` falls back to debug signing. Add a real
  `signingConfig` in `android/app/build.gradle.kts` (keystore via the app's
  `.env`/credential) before distributing real releases.
- **No new GitHub webhook + native webhook at once** — use the Action workflow OR
  a native repo webhook, not both.
