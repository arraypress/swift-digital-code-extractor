//
//  ExtractorConfiguration.swift
//  DigitalCodeExtractor
//
//  Created by David Sherlock on 9/17/25.
//

import Foundation

/// Configuration for the code extractor
public struct ExtractorConfiguration {
    /// Minimum confidence threshold for accepting a prediction (0.0 to 1.0)
    public var confidenceThreshold: Double
    
    /// Whether to check for multi-word combinations (e.g., "1234 5678")
    public var checkMultiWordCombinations: Bool
    
    /// Maximum number of words to combine when checking multi-word patterns
    public var maxCombinationLength: Int
    
    /// Whether to apply pre-filtering rules to avoid known false positives
    public var applyPreFiltering: Bool
    
    public init(
        confidenceThreshold: Double = 0.7,
        checkMultiWordCombinations: Bool = true,
        maxCombinationLength: Int = 4,
        applyPreFiltering: Bool = true
    ) {
        self.confidenceThreshold = confidenceThreshold
        self.checkMultiWordCombinations = checkMultiWordCombinations
        self.maxCombinationLength = maxCombinationLength
        self.applyPreFiltering = applyPreFiltering
    }
}
