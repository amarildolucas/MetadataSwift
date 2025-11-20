//
//  MetadataValue.swift
//  MetadataSwift
//
//  Created by Amarildo Lucas on 19/11/25.
//

import Foundation

/// Represents a metadata value with recursive wrapping for arrays and objects.
public enum MetadataValue: Sendable, Codable {
	case string(String)
	case int(Int)
	case double(Double)
	case bool(Bool)
	case array([MetadataValue])
	case object(Metadata)
	case `nil`
	
	public init(_ value: Any) {
		switch value {
		case let metadataValue as MetadataValue:
			self = metadataValue
		case let metadata as Metadata:
			self = .object(metadata)
		case let metadataDictionary as [String: MetadataValue]:
			self = .object(Metadata(storage: metadataDictionary))
		case let metadataArray as [MetadataValue]:
			self = .array(metadataArray)
		case let dictionary as [String: Any]:
			self = .object(Metadata(dictionary))
		case let array as [Any]:
			self = .array(array.map(MetadataValue.init))
		case is NSNull:
			self = .nil
		case let nsDictionary as NSDictionary:
			self = .object(MetadataValue.metadata(from: nsDictionary))
		case let nsArray as NSArray:
			self = .array(MetadataValue.array(from: nsArray))
		case let number as NSNumber:
			self = MetadataValue.convert(number: number)
		case let string as String:
			self = .string(string)
		case let bool as Bool:
			self = .bool(bool)
		case let int as Int:
			self = .int(int)
		case let double as Double:
			self = .double(double)
		case let float as Float:
			self = .double(Double(float))
		case let int8 as Int8:
			self = MetadataValue.convertSignedInteger(int8)
		case let int16 as Int16:
			self = MetadataValue.convertSignedInteger(int16)
		case let int32 as Int32:
			self = MetadataValue.convertSignedInteger(int32)
		case let int64 as Int64:
			self = MetadataValue.convertSignedInteger(int64)
		case let uint as UInt:
			self = MetadataValue.convertUnsignedInteger(uint)
		case let uint8 as UInt8:
			self = MetadataValue.convertUnsignedInteger(uint8)
		case let uint16 as UInt16:
			self = MetadataValue.convertUnsignedInteger(uint16)
		case let uint32 as UInt32:
			self = MetadataValue.convertUnsignedInteger(uint32)
		case let uint64 as UInt64:
			self = MetadataValue.convertUnsignedInteger(uint64)
		default:
			self = .nil
		}
	}
	
	private static func convert(number: NSNumber) -> MetadataValue {
		if CFGetTypeID(number) == CFBooleanGetTypeID() {
			return .bool(number.boolValue)
		}
		
		if CFNumberIsFloatType(number) {
			return .double(number.doubleValue)
		}
		
		let signedValue = number.int64Value
		let signedNumber = NSNumber(value: signedValue)
		if signedNumber.compare(number) == .orderedSame {
			return MetadataValue.convertSignedInteger(signedValue)
		}
		
		let unsignedValue = number.uint64Value
		let unsignedNumber = NSNumber(value: unsignedValue)
		if unsignedNumber.compare(number) == .orderedSame {
			return MetadataValue.convertUnsignedInteger(unsignedValue)
		}
		
		return .double(number.doubleValue)
	}

	private static func convertSignedInteger<T: SignedInteger>(_ value: T) -> MetadataValue {
		if let intValue = Int(exactly: value) {
			return .int(intValue)
		}
		return .double(Double(value))
	}

	private static func convertUnsignedInteger<T: UnsignedInteger>(_ value: T) -> MetadataValue {
		if let intValue = Int(exactly: value) {
			return .int(intValue)
		}
		return .double(Double(value))
	}

	private static func metadata(from dictionary: NSDictionary) -> Metadata {
		var storage: [String: MetadataValue] = [:]
		storage.reserveCapacity(dictionary.count)
		for case let (key as String, value) in dictionary {
			storage[key] = MetadataValue(value)
		}
		return Metadata(storage: storage)
	}

	private static func array(from nsArray: NSArray) -> [MetadataValue] {
		var values: [MetadataValue] = []
		values.reserveCapacity(nsArray.count)
		for element in nsArray {
			values.append(MetadataValue(element))
		}
		return values
	}
	
	public var value: Any {
		switch self {
		case let .string(value):
			return value
		case let .int(value):
			return value
		case let .double(value):
			return value
		case let .bool(value):
			return value
		case let .array(values):
			return values.map(\.value)
		case let .object(metadata):
			return metadata.dictionary
		case .nil:
			return NSNull()
		}
	}
	
	public var stringValue: String? {
		if case let .string(value) = self {
			return value
		}
		return nil
	}
	
	public var intValue: Int? {
		if case let .int(value) = self {
			return value
		}
		return nil
	}
	
	public var doubleValue: Double? {
		switch self {
		case let .double(value):
			return value
		case let .int(value):
			return Double(value)
		default:
			return nil
		}
	}
	
	public var boolValue: Bool? {
		if case let .bool(value) = self {
			return value
		}
		return nil
	}
	
	public var arrayValue: [MetadataValue]? {
		if case let .array(values) = self {
			return values
		}
		return nil
	}
	
	public var objectValue: Metadata? {
		if case let .object(metadata) = self {
			return metadata
		}
		return nil
	}
	
	private enum CodingKeys: String, CodingKey {
		case string
		case int
		case double
		case bool
		case array
		case object
		case `nil`
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .string(value):
			try container.encode(value, forKey: .string)
		case let .int(value):
			try container.encode(value, forKey: .int)
		case let .double(value):
			try container.encode(value, forKey: .double)
		case let .bool(value):
			try container.encode(value, forKey: .bool)
		case let .array(values):
			try container.encode(values, forKey: .array)
		case let .object(metadata):
			try container.encode(metadata, forKey: .object)
		case .nil:
			try container.encodeNil(forKey: .nil)
		}
	}
	
	public init(from decoder: Decoder) throws {
		if let container = try? decoder.container(keyedBy: CodingKeys.self),
		   !container.allKeys.isEmpty,
		   let discriminated = try MetadataValue.decode(from: container) {
			self = discriminated
			return
		}
		
		var singleValue = try decoder.singleValueContainer()
		if let fallback = try MetadataValue.decode(from: &singleValue) {
			self = fallback
			return
		}
		
		throw DecodingError.typeMismatch(
			MetadataValue.self,
			.init(
				codingPath: decoder.codingPath,
				debugDescription: "Unsupported MetadataValue payload"
			)
		)
	}

	private static func decode(from container: KeyedDecodingContainer<CodingKeys>) throws -> MetadataValue? {
		if container.contains(.string) {
			return .string(try container.decode(String.self, forKey: .string))
		}
		if container.contains(.int) {
			return .int(try container.decode(Int.self, forKey: .int))
		}
		if container.contains(.double) {
			return .double(try container.decode(Double.self, forKey: .double))
		}
		if container.contains(.bool) {
			return .bool(try container.decode(Bool.self, forKey: .bool))
		}
		if container.contains(.array) {
			return .array(try container.decode([MetadataValue].self, forKey: .array))
		}
		if container.contains(.object) {
			return .object(try container.decode(Metadata.self, forKey: .object))
		}
		if container.contains(.nil) {
			_ = try container.decodeNil(forKey: .nil)
			return .nil
		}
		return nil
	}

	private static func decode(from container: inout SingleValueDecodingContainer) throws -> MetadataValue? {
		if container.decodeNil() {
			return .nil
		}
		if let value = try? container.decode(String.self) {
			return .string(value)
		}
		if let value = try? container.decode(Bool.self) {
			return .bool(value)
		}
		if let value = try? container.decode(Int.self) {
			return .int(value)
		}
		if let value = try? container.decode(Double.self) {
			return .double(value)
		}
		if let array = try? container.decode([MetadataValue].self) {
			return .array(array)
		}
		if let object = try? container.decode([String: MetadataValue].self) {
			return .object(Metadata(storage: object))
		}
		return nil
	}
}
