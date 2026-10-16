# ClearScan

ClearScan is an open-source document scanner and PDF utility app built with Flutter. Capture or import documents, clean up scans, and organize, export, and share your files from one place.

<p align="center">
  <img src="https://raw.githubusercontent.com/Mehdi-Yanat/ClearScan/main/AppIcons/appstore.png" alt="ClearScan app icon" width="180">
</p>

## Features

- **Scan documents** with the camera or import images from your device.
- **Crop and enhance scans** for cleaner, more readable documents.
- **Manage documents** and export or share them as PDFs.
- **Work with PDFs** using tools for conversion, merging, splitting, rotation, and text extraction.
- **Use OCR and QR tools** for text recognition and QR code generation.
- **Personalize the app** with account, language, theme, and app-lock settings.

## Tech stack

- [Flutter](https://flutter.dev) and Dart
- Camera, image import, cropping, and image processing
- PDF creation, viewing, editing, and conversion
- OCR, local storage, and optional Supabase authentication

## Getting started

### Requirements

- Flutter SDK on the stable channel
- Android Studio with the Android SDK, or another configured Android development environment
- An Android device or emulator

### Run locally

```bash
git clone https://github.com/Mehdi-Yanat/ClearScan.git
cd ClearScan
flutter pub get
flutter run
```

The app can launch without backend configuration. To enable Supabase-backed features, provide the project URL and publishable key as Dart defines:

```bash
flutter run \
  --dart-define="supabase_project_url=YOUR_SUPABASE_PROJECT_URL" \
  --dart-define="supabase_publishable_key=YOUR_SUPABASE_PUBLISHABLE_KEY" \
  --dart-define="google_ID_client=YOUR_GOOGLE_CLIENT_ID"
```

`google_ID_client` is optional. Do not commit private credentials to the repository.

### Verify a local change

```bash
flutter analyze
flutter test
```

The Android integration tests require a running emulator:

```bash
flutter test integration_test/app_test.dart -d emulator-5554
```

## Continuous integration and releases

The **CI** workflow runs on pushes and pull requests targeting `main`. It installs dependencies, runs `flutter analyze` and `flutter test`, and builds a debug APK.

The **Release** workflow runs when a `v*` tag is pushed or when manually dispatched from GitHub Actions. It runs static analysis and Flutter tests, then builds a signed APK and Android App Bundle and attaches them to a GitHub Release.

Before publishing a signed release, configure the following repository **Actions secrets**:

| Secret | Description |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded Android upload keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Signing key alias |
| `ANDROID_KEY_PASSWORD` | Signing key password |

Encode the keystore locally without adding it to source control:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks"))
```

The release workflow also requires these repository **Actions variables**:

| Variable | Required | Description |
| --- | --- | --- |
| `SUPABASE_PROJECT_URL` | Yes | Supabase project URL |
| `SUPABASE_PUBLISHABLE_KEY` | Yes | Supabase publishable key |
| `GOOGLE_ID_CLIENT` | No | Google sign-in client ID |

To create a release without pushing a tag manually, open **Actions → Release → Run workflow** on `main` and enter a semantic version, for example `1.0.1-beta.1`. The workflow creates the corresponding `v1.0.1-beta.1` release tag. Versions containing a prerelease suffix are published as GitHub prereleases. You can also push a `v*` tag to start the release workflow.

## Contributing

Contributions are welcome. Fork the repository, create a feature branch, make and test your changes, then open a pull request against `main`.

## License

ClearScan is distributed under the MIT License. See [LICENSE](LICENSE) for details.
