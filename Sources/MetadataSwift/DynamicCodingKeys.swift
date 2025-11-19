//
//  DynamicCodingKeys.swift
//  MetadataSwift
//
//  Created by Amarildo Lucas on 19/11/25.
//

import Foundation

public struct DynamicCodingKeys: CodingKey {
	public let stringValue: String
	public let intValue: Int?
	
	public init?(stringValue: String) {
		self.stringValue = stringValue
		self.intValue = nil
	}
	
	public init?(intValue: Int) {
		self.stringValue = String(intValue)
		self.intValue = intValue
	}
}
