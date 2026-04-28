# Publishing the Dart SDK

The release workflow at [`.github/workflows/release.yml`](.github/workflows/release.yml) runs on every `v*` tag, validates version parity, runs the test suite, and creates a GitHub Release. **It does not currently publish to pub.dev** — the publish step is commented out at the bottom of the workflow because pub.dev's automated publishing requires a trusted-publisher relationship that has to be configured *after* the package exists on pub.dev.

That's a chicken-and-egg situation: trusted publishing needs the package to exist; publishing the first version is a one-time manual step. Once that's done, every future tag publishes automatically.

## One-time bootstrap (manual)

Pre-requisites:

- A pub.dev account (sign in at <https://pub.dev> with a Google account that has admin authority over the `cryptohopper` namespace, or accept whatever email Cryptohopper uses for package management).
- Dart 3.0+ installed locally.
- Push access to this repo (you already have it if you can read this file in CI).

### 1. Sync to the tag you want to ship

```bash
git fetch --tags
git checkout v0.1.0-alpha.1
```

### 2. Validate the package

```bash
dart pub get
dart pub publish --dry-run
```

`--dry-run` runs every check pub.dev runs server-side. Fix any warnings before continuing — pub.dev rejects packages that fail dry-run validation.

### 3. Publish

```bash
dart pub publish
```

This opens a browser to `https://pub.dev/auth/...` and asks you to confirm the publish. Confirm it. The first publish creates the package page at <https://pub.dev/packages/cryptohopper>.

### 4. Set up trusted publishing for future releases

Visit <https://pub.dev/packages/cryptohopper/admin> → **Automated publishing** → **Enable publishing from GitHub Actions**.

Configure:

- **Repository:** `cryptohopper/cryptohopper-dart-sdk`
- **Tag pattern:** `v{{version}}` (so a tag `v0.1.0-alpha.2` publishes version `0.1.0-alpha.2`)
- **Environment:** leave blank, or set to `production` if you want to gate pub.dev publishes on a GitHub environment review.

### 5. Wire the publish step in CI

Edit [`.github/workflows/release.yml`](.github/workflows/release.yml) and uncomment the final block:

```yaml
- name: Publish to pub.dev
  uses: dart-lang/setup-dart/.github/workflows/publish.yml@v1
```

(Or, if you prefer to keep it as a step rather than a reusable workflow, see <https://dart.dev/tools/pub/automated-publishing> for the `dart pub publish` step variant. The reusable workflow is preferred — it handles OIDC token retrieval automatically.)

Push the change to `main`. The next `v*` tag will publish automatically.

## Verifying it worked

After a tag push, watch the release workflow run on GitHub Actions. The Publish step should succeed in under a minute. Then check:

```bash
curl -fsSL https://pub.dev/api/packages/cryptohopper/versions | jq '.versions[].version'
```

The new version should be listed. The package page (<https://pub.dev/packages/cryptohopper>) updates within a couple of minutes.

## Troubleshooting

**`dart pub publish` says "no credentials"** — run `dart pub login` first. It opens a browser to authenticate with Google.

**Dry-run complains about the version** — make sure `pubspec.yaml`, `lib/src/version.dart`, and the git tag all agree. The release workflow's "Tag parity check" step does the same validation in CI.

**Trusted publishing rejects the OIDC token** — confirm the **Tag pattern** on pub.dev exactly matches the tag you're pushing (`v{{version}}` matches `v0.1.0-alpha.2`, not `release-0.1.0`).

**Pre-release tags (`v0.1.0-alpha.1`) won't publish** — pub.dev accepts SemVer pre-release identifiers, but they're flagged as "prereleases" and don't satisfy the default `^0.1.0-alpha.1` constraint cleanly. Consumers need to pin the exact pre-release version. This is a pub.dev convention, not a release-workflow issue.
