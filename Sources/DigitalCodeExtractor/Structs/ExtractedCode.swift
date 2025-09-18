//
//  ExtractedCode.swift
//  DigitalCodeExtractor
//
//  Created by David Sherlock on 9/17/25.
//

import Foundation

/// Represents an extracted code from text
public struct ExtractedCode: Equatable, Hashable {
    /// The extracted code text
    public let text: String
    
    /// Confidence score from the ML model (0.0 to 1.0)
    public let confidence: Double
    
    /// The range of the code in the original text (if available)
    public let range: Range<String.Index>?
    
    /// The type of code detected (based on pattern analysis)
    public let codeType: CodeType
    
    public init(text: String, confidence: Double, range: Range<String.Index>? = nil, codeType: CodeType = .unknown) {
        self.text = text
        self.confidence = confidence
        self.range = range
        self.codeType = codeType
    }
}
