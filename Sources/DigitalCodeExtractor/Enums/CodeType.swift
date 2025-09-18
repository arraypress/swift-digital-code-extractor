//
//  CodeType.swift
//  DigitalCodeExtractor
//
//  Created by David Sherlock on 9/17/25.
//

import Foundation

/// Types of codes that can be detected
public enum CodeType: String, CaseIterable {
    /// API keys (sk_test_xxx, pk_live_xxx, api_key_xxx)
    case apiKey = "api_key"
    
    /// Software license keys (ABCD-1234-EFGH-5678)
    case license = "license"
    
    /// 2FA backup codes (1234 5678 9012)
    case backupCode = "backup_code"
    
    /// Gift cards, promo codes
    case giftCard = "gift_card"
    
    /// Unknown code type
    case unknown = "unknown"
}
