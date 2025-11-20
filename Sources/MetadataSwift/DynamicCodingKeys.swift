//
//  DynamicCodingKeys.swift
//  MetadataSwift
//
//  Created by Amarildo Lucas on 19/11/25.
//

import Foundation

/// CodingKey implementation that lets `Metadata` encode/decode arbitrary user-provided keys.
public struct DynamicCodingKeys: CodingKey, Hashable, Sendable {
    public let stringValue: String
    public let intValue: Int?
    
    /// Builds a key from a string. This initializer never fails; the optional return type
    /// exists only because `CodingKey` requires it.
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    /// Builds a key from an integer coding value.
    /// - Parameter intValue: Integer representation used for coding paths.
    public init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
