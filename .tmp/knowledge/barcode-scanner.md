# Flutter Barcode/QR Code Scanner Packages Research

**Topic**: Flutter barcode/QR code scanning packages comparison
**Researched**: 2026-05-02
**Researcher**: ResearchAgent

---

## Summary

Three packages were researched for barcode/QR code scanning in Flutter: `mobile_scanner` (recommended), `flutter_barcode_scanner` (legacy, has issues), and `quick_barcode_scanner` (not found on pub.dev).

---

## Package Comparison

| Feature | mobile_scanner | flutter_barcode_scanner |
|---------|---------------|------------------------|
| **Latest Version** | 7.2.0 | 2.0.0 |
| **Published** | 2 months ago | 5 years ago |
| **Pub Points** | 160/160 (满分) | 130/160 |
| **Weekly Downloads** | ~781k | ~4.5k |
| **Likes** | 2.26k | 1.4k |
| **License** | BSD-3-Clause | MIT |
| **Publisher** | Verified (steenbakker.dev) | Unverified |

### Platform Support

| Platform | mobile_scanner | flutter_barcode_scanner |
|----------|---------------|------------------------|
| Android | ✅ Full support | ✅ Full support |
| iOS | ✅ Full support | ✅ Full support |
| macOS | ✅ Full support | ❌ Not supported |
| Web | ✅ Full support | ❌ Not supported |
| Windows | ❌ | ❌ |
| Linux | ❌ | ❌ |

### Feature Matrix (mobile_scanner)

| Feature | Android | iOS | macOS | Web |
|---------|---------|-----|-------|-----|
| analyzeImage | ✅ | ✅ | ✅ | ❌ |
| returnImage | ✅ | ✅ | ✅ | ❌ |
| scanWindow | ✅ | ✅ | ✅ | ❌ |
| autoZoom | ✅ | ❌ | ❌ | ❌ |
| lensType (multiple cameras) | ✅ | ✅ | ❌ | ❌ |

---

## mobile_scanner (Recommended)

### Pros
- ✅ **Modern & Active Development**: Latest version 7.2.0, published 2 months ago
- ✅ **Full Platform Support**: Android, iOS, macOS, Web
- ✅ **Excellent Pub Score**: 160/160 pub points
- ✅ **High Popularity**: 781k weekly downloads, 2.26k likes
- ✅ **Verified Publisher**: From steenbakker.dev
- ✅ **Real-time Detection**: Stream-based barcode scanning
- ✅ **Customizable**: scanWindow, autoZoom, lensType switching, torch control
- ✅ **Well Documented**: 99.4% API documentation coverage
- ✅ **ML Kit + Apple Vision**: Best-in-class scanning technology

### Cons
- ❌ **rawBytes limitation on iOS**: Apple Vision doesn't provide raw payload bytes for all formats
  - Byte mode: Correct
  - Numeric/Alphanumeric: Correct via Latin-1 fallback
  - Kanji mode: null (can't round-trip through Latin-1)
  - 0x80-0x9F range: null on Apple platforms

### Code Example

```dart
import 'package:mobile_scanner/mobile_scanner.dart';

// Simple usage
MobileScanner(
  onDetect: (result) {
    print(result.barcodes.first.rawValue);
  },
)

// Advanced usage with controller
final controller = MobileScannerController(
  cameraResolution: CameraResolution.high,
  detectionSpeed: DetectionSpeed.normal,
  formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
  torchEnabled: true,
);

MobileScanner(
  controller: controller,
  onDetect: (result) {
    final barcode = result.barcodes.first;
    print('Type: ${barcode.format}');
    print('Value: ${barcode.rawValue}');
  },
)
```

### Android Configuration
- Bundled MLKit: +3-10MB app size (immediate availability)
- Unbundled MLKit: +600KB (downloaded on first use via Play Services)
- To use unbundled, add to `/android/gradle.properties`:
  ```
  dev.steenbakker.mobile_scanner.useUnbundled=true
  ```

### iOS Configuration
Add to Info.plist:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photos access to get QR code from photo library</string>
```

---

## flutter_barcode_scanner (Legacy - Not Recommended)

### Pros
- ✅ Simple API for one-time scanning
- ✅ Supports Android and iOS

### Cons
- ❌ **Abandoned/Warning**: GitHub issue #380 states "ABANDONED PACKAGE"
- ❌ **Outdated**: Published 5 years ago, v2.0.0
- ❌ **Low Downloads**: Only 4.5k weekly vs 781k for mobile_scanner
- ❌ **Unverified Publisher**: No verified publisher
- ❌ **Limited Platform**: Only Android and iOS
- ❌ **No SPM Support**: Doesn't support Swift Package Manager
- ❌ **Known Issues** (from GitHub):
  - App crash on some Android devices (#379, #378)
  - Does not compile with Flutter 3.29 (#375)
  - compileSdk warning (#367)
  - Cannot customize UI (#374)
  - iOS SafeArea issues (#373)

### Code Example

```dart
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
  '#ff6666',          // COLOR_CODE
  'Cancel',           // CANCEL_BUTTON_TEXT
  true,               // isShowFlashIcon
  ScanMode.QR,        // scanMode
);

// For continuous scanning
FlutterBarcodeScanner.getBarcodeStreamReceiver(
  '#ff6666', 'Cancel', false, ScanMode.DEFAULT
).listen((barcode) {
  // Handle barcode
});
```

### Verdict: **Avoid** - Use mobile_scanner instead

---

## quick_barcode_scanner

**Status**: Not found on pub.dev. Package does not exist.

---

## Recommendations

### For Mobile-Only (Android + iOS)
Use **`mobile_scanner`**: Best choice with active maintenance, excellent documentation, and full feature set.

```yaml
dependencies:
  mobile_scanner: ^7.2.0
```

### For Cross-Platform (Including Web)
Use **`mobile_scanner`**: Only option with web support in this comparison.

### For Legacy Support Only
If you must use `flutter_barcode_scanner` (not recommended):
```yaml
dependencies:
  flutter_barcode_scanner: ^2.0.0
```
But plan migration to mobile_scanner.

---

## Related Systems
- Google ML Kit Barcode Scanning (Android backend)
- Apple Vision Framework (iOS/macOS backend)
- ZXing (Web backend)

---

## Links
- [mobile_scanner on pub.dev](https://pub.dev/packages/mobile_scanner)
- [flutter_barcode_scanner on pub.dev](https://pub.dev/packages/flutter_barcode_scanner)
