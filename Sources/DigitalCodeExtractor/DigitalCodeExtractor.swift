//
//  DigitalCodeExtractor.swift
//  DigitalCodeExtractor
//
//  Created by David Sherlock on 9/17/25.
//

import Foundation
import CoreML
import NaturalLanguage

/// Extracts digital codes (API keys, license keys, 2FA codes) from text using ML
///
/// This extractor is optimized for digital/software codes, not physical access codes
/// like door codes or PINs which are typically too short and ambiguous.
///
/// ## Usage Example:
/// ```swift
/// let extractor = DigitalCodeExtractor()
/// let codes = extractor.extractCodes(from: "Your API key is sk_test_4242424242")
/// print(codes.first?.text) // "sk_test_4242424242"
/// ```
public class DigitalCodeExtractor {
    
    // MARK: - Properties
    
    private let mlModel: NLModel?
    private let configuration: ExtractorConfiguration
    
    // Known API key prefixes
    private let apiKeyPrefixes = [
        "sk_test_", "sk_live_",  // Stripe
        "pk_test_", "pk_live_",  // Stripe public
        "api_key_", "api-key-",
        "ghp_",                  // GitHub personal access token
        "ghs_",                  // GitHub server token
        "github_pat_",           // GitHub PAT
        "xoxb-", "xoxp-",        // Slack
        "sq0",                   // Square
        "AKIA",                  // AWS
        "AIza",                  // Google API
    ]
    
    // Patterns that commonly cause false positives
    private let falsePositivePrefixes = [
        "ERROR-CODE-",
        "STATUS-CODE-",
        "HTTP-",
        "BUILD-",
        "DEBUG-",
        "PATCH-",
        "VERSION-",
        "RELEASE-",
        "TEST-ENV-"
    ]
    
    // MARK: - Initialization
    
    /// Initialize the code extractor with optional configuration
    /// - Parameter configuration: Configuration options for extraction behavior
    public init(configuration: ExtractorConfiguration = ExtractorConfiguration()) {
        self.configuration = configuration
        
        // Load model from bundle
        if let modelURL = Bundle.module.url(forResource: "DigitalCodeDetector", withExtension: "mlmodelc") {
            do {
                let mlModel = try MLModel(contentsOf: modelURL)
                self.mlModel = try NLModel(mlModel: mlModel)
            } catch {
                print("DigitalCodeExtractor: Failed to load ML model - \(error)")
                self.mlModel = nil
            }
        } else {
            print("DigitalCodeExtractor: Could not find CodeDetector.mlmodelc in bundle")
            self.mlModel = nil
        }
    }
    
    // MARK: - Public Methods
    
    /// Extract all potential codes from the given text
    /// - Parameter text: The text to analyze for codes
    /// - Returns: Array of extracted codes sorted by confidence
    public func extractCodes(from text: String) -> [ExtractedCode] {
        var results: [ExtractedCode] = []
        
        // First, extract codes using known patterns (high confidence)
        results.append(contentsOf: extractKnownPatterns(from: text))
        
        // Then use ML model for additional detection
        if mlModel != nil {
            results.append(contentsOf: extractUsingML(from: text))
        }
        
        // Deduplicate and sort by confidence
        return deduplicateAndSort(results)
    }
    
    /// Check if a single string is likely a code
    /// - Parameters:
    ///   - text: The text to check
    ///   - includeConfidence: Whether to calculate confidence score
    /// - Returns: Tuple of (isCode, confidence)
    public func isCode(_ text: String, includeConfidence: Bool = true) -> (Bool, Double) {
        // Check known patterns first
        if hasKnownCodePattern(text) {
            return (true, 1.0)
        }
        
        // Check false positives
        if configuration.applyPreFiltering && isLikelyFalsePositive(text) {
            return (false, 0.0)
        }
        
        // Use ML model
        guard let model = mlModel else {
            return (false, 0.0)
        }
        
        let prediction = model.predictedLabel(for: text)
        
        if includeConfidence {
            let hypotheses = model.predictedLabelHypotheses(for: text, maximumCount: 2)
            let confidence = hypotheses["code"] ?? 0.0
            return (prediction == "code" && confidence >= configuration.confidenceThreshold, confidence)
        } else {
            return (prediction == "code", 0.0)
        }
    }
    
    // MARK: - Private Methods
    
    /// Extracts codes using known regex patterns with high confidence
    /// - Parameter text: The text to search for known code patterns
    /// - Returns: Array of extracted codes found using pattern matching
    /// - Note: This method has higher confidence than ML detection as it uses exact pattern matching
    private func extractKnownPatterns(from text: String) -> [ExtractedCode] {
        var results: [ExtractedCode] = []
        
        // API Key patterns
        for prefix in apiKeyPrefixes {
            let pattern = "\(NSRegularExpression.escapedPattern(for: prefix))[a-zA-Z0-9_-]{10,}"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let codeText = String(text[range])
                        results.append(ExtractedCode(
                            text: codeText,
                            confidence: 1.0,
                            range: range,
                            codeType: .apiKey
                        ))
                    }
                }
            }
        }
        
        // License key pattern (XXXX-XXXX-XXXX)
        let licensePattern = #"\b[A-Z0-9]{4,}(-[A-Z0-9]{4,}){1,4}\b"#
        if let regex = try? NSRegularExpression(pattern: licensePattern, options: []) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let codeText = String(text[range])
                    if !isLikelyFalsePositive(codeText) {
                        results.append(ExtractedCode(
                            text: codeText,
                            confidence: 0.95,
                            range: range,
                            codeType: .license
                        ))
                    }
                }
            }
        }
        
        // Backup code pattern (#### #### ####)
        let backupPattern = #"(?<!\d)\d{4}(?:\s+\d{4}){1,3}(?!\d)"#
        if let regex = try? NSRegularExpression(pattern: backupPattern, options: []) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let codeText = String(text[range])
                    results.append(ExtractedCode(
                        text: codeText,
                        confidence: 0.9,
                        range: range,
                        codeType: .backupCode
                    ))
                }
            }
        }
        
        return results
    }
    
    /// Uses the ML model to extract potential codes from text
    /// - Parameter text: The text to analyze using machine learning
    /// - Returns: Array of codes detected by the ML model
    /// - Note: This method handles both individual tokens and multi-word combinations
    private func extractUsingML(from text: String) -> [ExtractedCode] {
        guard let model = mlModel else { return [] }
        
        var results: [ExtractedCode] = []
        let tokens = tokenize(text)
        
        // Check individual tokens
        for token in tokens {
            if let code = checkWithML(token.text, model: model) {
                results.append(code)
            }
        }
        
        // Check multi-word combinations if enabled
        if configuration.checkMultiWordCombinations {
            results.append(contentsOf: checkMultiWordCombinations(tokens: tokens, model: model))
        }
        
        return results
    }
    
    /// Tokenizes text into individual words for processing
    /// - Parameter text: The text to tokenize
    /// - Returns: Array of tuples containing the token text and optional range
    /// - Note: Splits on whitespace and newlines, filtering empty strings
    private func tokenize(_ text: String) -> [(text: String, range: Range<String.Index>?)] {
        var tokens: [(String, Range<String.Index>?)] = []
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        
        for word in words {
            if !word.isEmpty {
                tokens.append((word, nil))
            }
        }
        
        return tokens
    }
    
    /// Checks multi-word combinations for potential codes
    /// - Parameters:
    ///   - tokens: Array of tokenized words from the text
    ///   - model: The NLModel to use for classification
    /// - Returns: Array of codes found in multi-word combinations
    /// - Note: Checks combinations from 2 words up to maxCombinationLength
    private func checkMultiWordCombinations(
        tokens: [(text: String, range: Range<String.Index>?)],
        model: NLModel
    ) -> [ExtractedCode] {
        var results: [ExtractedCode] = []
        
        // Guard against not enough tokens
        guard tokens.count >= 2 else {
            return results
        }
        
        // Fix the range to handle edge cases
        let maxLength = min(configuration.maxCombinationLength, tokens.count)
        
        for length in 2...maxLength {
            for i in 0...(tokens.count - length) where i >= 0 {
                let combined = tokens[i..<i+length].map { $0.text }.joined(separator: " ")
                
                // Skip if it's an obvious false positive
                if configuration.applyPreFiltering && isLikelyFalsePositive(combined) {
                    continue
                }
                
                if let code = checkWithML(combined, model: model) {
                    results.append(code)
                }
            }
        }
        
        return results
    }
    
    /// Checks a single text string with the ML model
    /// - Parameters:
    ///   - text: The text to classify
    ///   - model: The NLModel to use for classification
    /// - Returns: An ExtractedCode if the text is classified as a code with sufficient confidence, nil otherwise
    private func checkWithML(_ text: String, model: NLModel) -> ExtractedCode? {
        // Skip known false positives
        if configuration.applyPreFiltering && isLikelyFalsePositive(text) {
            return nil
        }
        
        let prediction = model.predictedLabel(for: text)
        if prediction == "code" {
            let hypotheses = model.predictedLabelHypotheses(for: text, maximumCount: 2)
            let confidence = hypotheses["code"] ?? 0.0
            
            if confidence >= configuration.confidenceThreshold {
                return ExtractedCode(
                    text: text,
                    confidence: confidence,
                    range: nil,
                    codeType: detectCodeType(text)
                )
            }
        }
        
        return nil
    }
    
    /// Checks if text matches any known code pattern
    /// - Parameter text: The text to check against known patterns
    /// - Returns: true if the text matches a known code pattern, false otherwise
    private func hasKnownCodePattern(_ text: String) -> Bool {
        // Check for API key prefixes
        for prefix in apiKeyPrefixes {
            if text.lowercased().hasPrefix(prefix.lowercased()) {
                return true
            }
        }
        
        // Check for license key format
        let licenseRegex = try? NSRegularExpression(pattern: #"^[A-Z0-9]{4,}(-[A-Z0-9]{4,}){1,4}$"#)
        if let regex = licenseRegex {
            let range = NSRange(text.startIndex..., in: text)
            if regex.firstMatch(in: text, range: range) != nil {
                return true
            }
        }

        // Check for backup code format (#### #### ####)
        let backupRegex = try? NSRegularExpression(pattern: #"^\d{4}(?:\s+\d{4}){1,3}$"#)
        if let regex = backupRegex {
            let range = NSRange(text.startIndex..., in: text)
            if regex.firstMatch(in: text, range: range) != nil {
                return true
            }
        }

        return false
    }
    
    /// Determines if text is likely a false positive based on known patterns
    /// - Parameter text: The text to check for false positive patterns
    /// - Returns: true if the text matches known false positive patterns, false otherwise
    /// - Note: Checks against common prefixes like ERROR-CODE-, STATUS-CODE-, etc.
    private func isLikelyFalsePositive(_ text: String) -> Bool {
        let upperText = text.uppercased()
        for prefix in falsePositivePrefixes {
            if upperText.hasPrefix(prefix) {
                return true
            }
        }
        return false
    }
    
    /// Analyzes text to determine the specific type of code
    /// - Parameter text: The code text to analyze
    /// - Returns: The detected CodeType based on pattern analysis
    /// - Note: Returns .unknown if no specific pattern is matched
    private func detectCodeType(_ text: String) -> CodeType {
        let lowerText = text.lowercased()
        
        // Check for API key patterns
        for prefix in apiKeyPrefixes {
            if lowerText.hasPrefix(prefix.lowercased()) {
                return .apiKey
            }
        }
        
        // Check for backup code pattern (space-separated numbers)
        if text.range(of: #"^\d{4}(\s+\d{4}){1,3}$"#, options: .regularExpression) != nil {
            return .backupCode
        }
        
        // Check for license key pattern
        if text.range(of: #"^[A-Z0-9]{4,}(-[A-Z0-9]{4,}){1,4}$"#, options: .regularExpression) != nil {
            return .license
        }
        
        return .unknown
    }
    
    /// Removes duplicate codes and sorts by confidence
    /// - Parameter codes: Array of potentially duplicate codes
    /// - Returns: Array of unique codes sorted by confidence (highest first)
    /// - Note: Also removes codes that are substrings of other codes
    private func deduplicateAndSort(_ codes: [ExtractedCode]) -> [ExtractedCode] {
        var uniqueCodes: [ExtractedCode] = []
        var seenTexts = Set<String>()
        
        // Sort by confidence descending
        let sorted = codes.sorted { $0.confidence > $1.confidence }
        
        for code in sorted {
            // Skip if we've seen this exact text
            if seenTexts.contains(code.text) {
                continue
            }
            
            // Skip if this is a substring of an already added code
            let isSubstring = uniqueCodes.contains { existing in
                existing.text.contains(code.text) && existing.text != code.text
            }
            
            if !isSubstring {
                uniqueCodes.append(code)
                seenTexts.insert(code.text)
            }
        }
        
        return uniqueCodes
    }
    
}
