# 📄 ClearScan

**A modern, premium document scanner designed to be free for all users**

ClearScan transforms your mobile device into a powerful document scanner. It combines a seamless user experience with professional-grade image processing to ensure your documents are captured, enhanced, and exported with precision.

<p align="center">
  <img src="https://github.com/Mehdi-Yanat/ClearScan/blob/main/AppIcons/appstore.png?raw=true" alt="ClearScan App Icon" width="250">
</p> 

## ✨ Features

- **📸 Intelligent Capture**: Quickly capture documents using your camera or import high-resolution images from your gallery.
- **✂️ Precision Cropping**: An intuitive cropping tool allows you to refine the document boundaries, ensuring only the relevant content is kept.
- **🪄 Scan-Style Enhancement**: Automatic grayscale conversion and contrast optimization to produce a clean, high-contrast "scanned" look.
- **📄 Professional PDF Export**: Export your processed documents into true A4-sized PDFs, ready for professional sharing and archiving.
- **🚀 Instant Preview**: Open your exported PDFs immediately after generation for quick verification.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Image Processing**: `image` package for advanced pixel manipulation and filters.
- **PDF Generation**: `pdf` package for professional document layout and export.
- **Camera & Gallery**: `image_picker` for seamless media acquisition.
- **Cropping**: `image_cropper` for precision document framing.
- **Storage**: `path_provider` for secure local file management.

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel recommended)
- Android Studio / Android SDK
- A physical Android device or an Android Emulator

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/clear_scan.git
   cd clear_scan
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

### Troubleshooting

If you encounter DDS or service protocol issues on Windows, run the app with the following flag:
```bash
flutter run --no-dds
```

## CI/CD and Android releases

GitHub Actions runs static analysis, Flutter tests, an Android emulator-backed end-to-end test, and a debug APK build for pushes and pull requests targeting `main`.

To publish a signed Android release, add these repository Actions secrets:

- `ANDROID_KEYSTORE_BASE64`: Base64-encoded upload keystore (PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('android/app/upload-keystore.jks'))`; Linux: `base64 -w 0 android/app/upload-keystore.jks`).
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password.
- `ANDROID_KEY_ALIAS`: Signing key alias.
- `ANDROID_KEY_PASSWORD`: Signing key password.

Add these repository Actions variables so release builds include the app's client-side Supabase configuration:

- `SUPABASE_PROJECT_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `GOOGLE_ID_CLIENT` (optional; omit to disable Google sign-in)

To release without creating a tag manually, open **Actions → Release → Run workflow** on `main` and enter a semantic version such as `1.0.1-beta.1`. The workflow creates the corresponding `v1.0.1-beta.1` tag, runs analysis, Flutter tests, and the Android emulator end-to-end test, then builds and attaches a signed APK and Android App Bundle to a GitHub Release. Versions containing a prerelease suffix (for example, `-beta.1`) are published as GitHub prereleases. Pushing a `v*` tag manually also triggers a release. The Android version code uses the GitHub Actions run number.

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and collaborate. Any contributions that help improve the project are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---
*Developed with ❤️ for the open-source community.*
