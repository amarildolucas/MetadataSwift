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
			case let dictionary as [String: Any]:
				self = .object(Metadata(dictionary))
			case let array as [Any]:
				self = .array(array.map(MetadataValue.init))
			case is NSNull:
				self = .nil
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
				self = .int(Int(int8))
			case let int16 as Int16:
				self = .int(Int(int16))
			case let int32 as Int32:
				self = .int(Int(int32))
			case let int64 as Int64:
				self = .int(Int(truncatingIfNeeded: int64))
			case let uint as UInt:
				self = .int(Int(truncatingIfNeeded: uint))
			case let uint8 as UInt8:
				self = .int(Int(uint8))
			case let uint16 as UInt16:
				self = .int(Int(uint16))
			case let uint32 as UInt32:
				self = .int(Int(truncatingIfNeeded: uint32))
			case let uint64 as UInt64:
				self = .double(Double(uint64))
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
		
		return .int(number.intValue)
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
		if let container = try? decoder.container(keyedBy: CodingKeys.self), !container.allKeys.isEmpty {
			if container.contains(.string) {
				self = .string(try container.decode(String.self, forKey: .string))
				return
			}
			if container.contains(.int) {
				self = .int(try container.decode(Int.self, forKey: .int))
				return
			}
			if container.contains(.double) {
				self = .double(try container.decode(Double.self, forKey: .double))
				return
			}
			if container.contains(.bool) {
				self = .bool(try container.decode(Bool.self, forKey: .bool))
				return
			}
			if container.contains(.array) {
				self = .array(try container.decode([MetadataValue].self, forKey: .array))
				return
			}
			if container.contains(.object) {
				self = .object(try container.decode(Metadata.self, forKey: .object))
				return
			}
			if container.contains(.nil) {
				_ = try container.decodeNil(forKey: .nil)
				self = .nil
				return
			}
		}
		
		let singleValue = try decoder.singleValueContainer()
		if singleValue.decodeNil() {
			self = .nil
			return
		}
		if let value = try? singleValue.decode(String.self) {
			self = .string(value)
			return
		}
		if let value = try? singleValue.decode(Bool.self) {
			self = .bool(value)
			return
		}
		if let value = try? singleValue.decode(Int.self) {
			self = .int(value)
			return
		}
		if let value = try? singleValue.decode(Double.self) {
			self = .double(value)
			return
		}
		if let array = try? singleValue.decode([MetadataValue].self) {
			self = .array(array)
			return
		}
		if let object = try? singleValue.decode([String: MetadataValue].self) {
			self = .object(Metadata(storage: object))
			return
		}
		
		throw DecodingError.typeMismatch(MetadataValue.self, .init(codingPath: decoder.codingPath, debugDescription: "Unsupported MetadataValue payload"))
	}
}
