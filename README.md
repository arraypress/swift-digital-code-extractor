# DigitalCodeExtractor

A Swift package for detecting and extracting digital codes (API keys, license keys, 2FA backup codes) from text using Core ML.

## Features

- 🔍 **ML-Powered Detection**: Uses a trained Core ML model to identify codes with high accuracy
- 🎯 **Pattern Recognition**: Built-in detection for common code formats (API keys, licenses, backup codes)
- 🛡️ **False Positive Filtering**: Automatically filters out error codes, status codes, and common text patterns
- ⚡ **High Performance**: Optimized for both accuracy and speed
- 🔧 **Configurable**: Adjust confidence thresholds and detection behaviors
- 📦 **Self-Contained**: Includes the ML model in the package

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-digital-code-extractor.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select version requirements

## Usage

### Basic Usage

```swift
import DigitalCodeExtractor

let extractor = DigitalCodeExtractor()
let text = "Your API key is sk_test_4242424242424242"
let codes = extractor.extractCodes(from: text)

for code in codes {
    print("Found: \(code.text)")
    print("Type: \(code.codeType)")
    print("Confidence: \(code.confidence)")
}
```

### Checking Individual Strings

```swift
let (isCode, confidence) = extractor.isCode("ABCD-1234-EFGH-5678")
if isCode {
    print("This is a code with \(confidence * 100)% confidence")
}
```

### Custom Configuration

```swift
let config = ExtractorConfiguration(
    confidenceThreshold: 0.8,              // Higher threshold for fewer false positives
    checkMultiWordCombinations: true,       // Detect space-separated codes
    maxCombinationLength: 3,                // Check up to 3-word combinations
    applyPreFiltering: true                 // Filter known false positives
)

let extractor = DigitalCodeExtractor(configuration: config)
```

## Supported Code Types

### ✅ Detected with High Accuracy

| Type | Example | Detection Method |
|------|---------|-----------------|
| **API Keys** | `sk_test_4242424242424242` | Pattern + ML |
| **License Keys** | `ABCD-1234-EFGH-5678` | Pattern + ML |
| **2FA Backup Codes** | `1234 5678 9012` | Pattern + ML |
| **GitHub Tokens** | `ghp_1234567890abcdef` | Pattern |
| **Steam Keys** | `XXXXX-XXXXX-XXXXX` | ML |
| **Generic Tokens** | `eyJhbGciOiJIUzI1NiIs...` | ML |

### ❌ Intentionally Not Detected

- Error codes (`ERROR-CODE-404`)
- Status codes (`HTTP-200`, `STATUS-500`)
- Build/version numbers (`BUILD-12345`, `v2.0.1`)
- IP addresses (`192.168.1.1`)
- Email addresses (`user@example.com`)
- Phone numbers (`555-123-4567`)
- URLs (`www.example.com`)

### ⚠️ Limited Detection

- **Short PIN codes** (4-6 digits): Too ambiguous, many false positives
- **Physical access codes**: Designed for digital codes, not door/gate codes

## Code Types

```swift
public enum CodeType {
    case apiKey      // API keys with known prefixes
    case license     // Software license keys
    case backupCode  // 2FA backup codes
    case giftCard    // Gift/promo codes
    case unknown     // Detected but type unclear
}
```

## Extracted Code Structure

```swift
public struct ExtractedCode {
    let text: String                    // The extracted code
    let confidence: Double               // ML confidence (0.0-1.0)
    let range: Range<String.Index>?     // Position in original text
    let codeType: CodeType               // Type of code detected
}
```

## Performance

- **Short text** (<100 chars): ~5ms
- **Long text** (1000+ chars): ~50ms
- **Memory usage**: ~20MB (including ML model)

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.9+
- Core ML framework

## Model Training

The included ML model was trained on:
- 10,000+ examples of various code formats
- Targeted negative examples for common false positives
- Balanced dataset of codes vs non-codes

Model accuracy:
- **Precision**: ~95% (few false positives)
- **Recall**: ~92% (catches most codes)
- **F1 Score**: ~93.5%

## Advanced Usage

### Processing Camera Text

```swift
// Ideal for OCR/camera text extraction
let cameraText = "Gate Code: 1234\nAPI Key: sk_test_abc123"
let codes = extractor.extractCodes(from: cameraText)
// Returns only the API key, not the short gate code
```

### Batch Processing

```swift
let documents = ["doc1 text", "doc2 text", "doc3 text"]
let allCodes = documents.flatMap { extractor.extractCodes(from: $0) }
```

### Integration with Text Recognition

```swift
import Vision

// After VNRecognizeTextRequest
let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
let codes = extractor.extractCodes(from: recognizedText)
```

## Testing

Run the test suite:

```bash
swift test
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

## Acknowledgments

Built with Core ML and Natural Language frameworks by Apple.
