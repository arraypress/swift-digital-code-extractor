# Swift Digital Code Extractor

A Swift package for detecting and extracting digital codes — API keys, license keys, and 2FA backup codes — from arbitrary text. It combines high-confidence regex patterns for known formats (Stripe, GitHub, Slack, AWS, Google, and more) with a bundled Core ML classifier for additional detection, while pre-filtering common false positives like error and status codes.

## Features

- 🤖 **Bundled Core ML classifier** — a precompiled `NLModel` (`DigitalCodeDetector.mlmodelc`) augments pattern matching with ML-based detection
- 🔑 **API key detection** — recognizes Stripe, GitHub, Slack, Square, AWS, and Google key prefixes
- 📜 **License key detection** — matches grouped `XXXX-XXXX-XXXX` style keys
- 🔢 **Backup code detection** — matches space-separated numeric 2FA codes
- 📊 **Confidence scoring** — every result carries a 0.0–1.0 confidence value
- 🧹 **False-positive filtering** — pre-filters prefixes like `ERROR-CODE-`, `STATUS-CODE-`, and `HTTP-`
- 🔗 **Multi-word detection** — optionally checks word combinations for split codes
- 🧪 **Single-string check** — `isCode(_:)` returns whether one string is likely a code
- 🗂️ **Typed results** — extracted codes are classified by `CodeType` with their text range
- ⚙️ **Configurable** — tune the confidence threshold, combination length, and filtering

## Requirements

- iOS 15.0+ / macOS 14.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-digital-code-extractor.git", from: "1.0.0")
]
```

## Usage

### Extract Codes

```swift
import DigitalCodeExtractor

let extractor = DigitalCodeExtractor()
let codes = extractor.extractCodes(from: "Your API key is sk_test_4242424242")

for code in codes {
    print(code.text, code.confidence, code.codeType)
}
// "sk_test_4242424242", 1.0, .apiKey
```

### Check a Single String

```swift
import DigitalCodeExtractor

let extractor = DigitalCodeExtractor()
let (isCode, confidence) = extractor.isCode("ghp_1234567890abcdef")
// (true, 1.0)
```

### Custom Configuration

```swift
import DigitalCodeExtractor

let config = ExtractorConfiguration(
    confidenceThreshold: 0.8,
    checkMultiWordCombinations: true,
    maxCombinationLength: 4,
    applyPreFiltering: true
)

let extractor = DigitalCodeExtractor(configuration: config)
let codes = extractor.extractCodes(from: "License: ABCD-1234-EFGH-5678")
```

## How It Works

`extractCodes(from:)` first applies high-confidence regex patterns for known API-key prefixes, license-key formats, and backup-code formats, then runs the bundled Core ML `NLModel` over individual tokens (and optional multi-word combinations) to catch codes that don't match a known pattern. Results are filtered against known false-positive prefixes, deduplicated (including substring removal), and sorted by confidence.

## Models

### `ExtractedCode`

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | The extracted code text |
| `confidence` | `Double` | Confidence score (0.0–1.0) |
| `range` | `Range<String.Index>?` | Location in the source text, if available |
| `codeType` | `CodeType` | Detected code type |

### `ExtractorConfiguration`

| Property | Type | Description |
|----------|------|-------------|
| `confidenceThreshold` | `Double` | Minimum confidence to accept a prediction (default `0.7`) |
| `checkMultiWordCombinations` | `Bool` | Check word combinations (default `true`) |
| `maxCombinationLength` | `Int` | Max words to combine (default `4`) |
| `applyPreFiltering` | `Bool` | Filter known false positives (default `true`) |

`CodeType` cases are `.apiKey`, `.license`, `.backupCode`, `.giftCard`, and `.unknown`.

## Use Cases

- Secret scanning and leak detection in text or logs
- Auto-detecting codes pasted into chat or support tools
- Extracting license keys and 2FA backup codes from messages
- Redaction and data-classification pipelines

## Testing

```bash
swift test
```

The test suite covers known-pattern extraction (API keys, license keys, backup codes), ML-based detection, false-positive filtering, confidence thresholds, and deduplication.

## License

MIT License — see LICENSE file for details.

## Author

Created by David Sherlock ([ArrayPress](https://github.com/arraypress)) in 2026.
