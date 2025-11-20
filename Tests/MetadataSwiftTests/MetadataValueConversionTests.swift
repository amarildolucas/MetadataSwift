//
//  File.swift
//  MetadataSwift
//
//  Created by Amarildo Lucas on 20/11/25.
//

import Foundation
import Testing
@testable import MetadataSwift

@Suite("Metadata value conversion behaviours")
struct MetadataValueConversionBehaviourTests {
	@Test("Scalar inputs convert to primitive metadata cases")
	func scalarInputsConvertToPrimitiveCases() {
		#expect(MetadataValue("Voyager").stringValue == "Voyager")
		#expect(MetadataValue(true).boolValue == true)
		#expect(MetadataValue(42).intValue == 42)
		#expect(MetadataValue(3.75).doubleValue == 3.75)
		#expect(MetadataValue(Int8(8)).intValue == 8)
		#expect(MetadataValue(Int16(9)).intValue == 9)
		#expect(MetadataValue(UInt16(11)).intValue == 11)
		#expect(MetadataValue(UInt64(12)).intValue == 12)
		#expect(MetadataValue(Float(1.5)).doubleValue == 1.5)
	}
	
	@Test("Foundation numerics bridge to bool, double, and int cases")
	func foundationNumericsBridgeToStronglyTypedCases() {
		#expect(MetadataValue(NSNumber(value: true)).boolValue == true)
		#expect(MetadataValue(NSNumber(value: 27)).intValue == 27)
		#expect(MetadataValue(NSNumber(value: 2.5)).doubleValue == 2.5)
		
		let overflowingUnsigned = MetadataValue(UInt64.max)
		if case let .double(value) = overflowingUnsigned {
			#expect(value == Double(UInt64.max))
		} else {
			Issue.record("UInt64.max should produce a .double case")
		}
		
		#expect(MetadataValue(NSNull()).value is NSNull)
	}
	
	@Test("Recursive structures wrap nested metadata values")
	func recursiveStructuresWrapNestedMetadata() {
		let nestedArray: [Any] = ["title", 9, ["flag": true]]
		let arrayConversion = MetadataValue(nestedArray)
		guard case let .array(values) = arrayConversion else {
			Issue.record("Array conversion expectation not met.")
			return
		}
		#expect(values.count == 3)
		#expect(values[0].stringValue == "title")
		#expect(values[1].intValue == 9)
		if case let .object(nestedObject) = values[2] {
			#expect(nestedObject["flag"]?.boolValue == true)
		} else {
			Issue.record("Object conversion expectation not met.")
		}
		#expect(arrayConversion.arrayValue?.count == 3)
		if let unwoundArray = arrayConversion.value as? [Any] {
			#expect(unwoundArray.count == 3)
			#expect(unwoundArray[0] as? String == "title")
			#expect(unwoundArray[1] as? Int == 9)
			#expect((unwoundArray[2] as? [String: Any])?["flag"] as? Bool == true)
		} else {
			Issue.record("Array .value did not unwind to [Any].")
		}
		
		let nestedDictionary: [String: Any] = [
			"title": "Voyager",
			"details": ["episode": 7, "season": 3],
			"tags": ["series", "cinema"]
		]
		let dictionaryConversion = MetadataValue(nestedDictionary)
		guard case let .object(metadata) = dictionaryConversion else {
			Issue.record("Dictionary conversion expectation not met.")
			return
		}
		
		#expect(metadata["title"]?.stringValue == "Voyager")
		if case let .object(details)? = metadata["details"] {
			#expect(details["episode"]?.intValue == 7)
			#expect(details["season"]?.intValue == 3)
		} else {
			Issue.record("Object conversion expectation not met. (for 'details')")
		}
		if case let .array(tags)? = metadata["tags"] {
			#expect(tags.count == 2)
			#expect(tags[0].stringValue == "series")
			#expect(tags[1].stringValue == "cinema")
		} else {
			Issue.record("Array conversion expectation not met. (for 'tags')")
		}
		#expect(dictionaryConversion.objectValue?["title"]?.stringValue == "Voyager")
		if let unwoundDictionary = dictionaryConversion.value as? [String: Any] {
			#expect(unwoundDictionary["title"] as? String == "Voyager")
			if let details = unwoundDictionary["details"] as? [String: Any] {
				#expect(details["episode"] as? Int == 7)
				#expect(details["season"] as? Int == 3)
			} else {
				Issue.record("Details did not unwind to [String: Any].")
			}
			if let tags = unwoundDictionary["tags"] as? [String] {
				#expect(tags == ["series", "cinema"])
			} else {
				Issue.record("Tags did not unwind to [String].")
			}
		} else {
			Issue.record("Dictionary .value did not unwind to [String: Any].")
		}
		
		let foundationArray: NSArray = ["title", 9, ["flag": true]]
		if case let .array(foundationValues) = MetadataValue(foundationArray) {
			#expect(foundationValues.count == 3)
		} else {
			Issue.record("NSArray inputs should wrap as .array")
		}
		let foundationDictionary: NSDictionary = [
			"title": "Voyager",
			"details": ["episode": 7]
		]
		if case let .object(foundationObject) = MetadataValue(foundationDictionary) {
			#expect(foundationObject["title"]?.stringValue == "Voyager")
		} else {
			Issue.record("NSDictionary inputs should wrap as .object")
		}
	}

	@Test("Metadata value arrays and objects wrap existing metadata collections")
	func metadataCollectionsWrapExistingMetadata() {
		let metadataArray: [MetadataValue] = [
			.string("voyager"),
			.int(7),
			.object(Metadata(["flag": true]))
		]
		let arrayConversion = MetadataValue(metadataArray)
		guard case let .array(values) = arrayConversion else {
			Issue.record("[MetadataValue] should remain in the .array case")
			return
		}
		#expect(values.count == 3)
		#expect(values[0].stringValue == "voyager")
		#expect(values[1].intValue == 7)
		if case let .object(metadata) = values[2] {
			#expect(metadata["flag"]?.boolValue == true)
		} else {
			Issue.record("Array entry should remain an object")
		}
		#expect(arrayConversion.arrayValue?.count == 3)
		if let unwoundArray = arrayConversion.value as? [Any] {
			#expect(unwoundArray.count == 3)
			#expect(unwoundArray[0] as? String == "voyager")
			#expect(unwoundArray[1] as? Int == 7)
			#expect((unwoundArray[2] as? [String: Any])?["flag"] as? Bool == true)
		}
		
		let metadataDictionary: [String: MetadataValue] = [
			"title": .string("Voyager"),
			"details": .object(Metadata(["episode": 7]))
		]
		let dictionaryConversion = MetadataValue(metadataDictionary)
		guard case let .object(metadata) = dictionaryConversion else {
			Issue.record("[String: MetadataValue] should wrap into .object")
			return
		}
		#expect(metadata["title"]?.stringValue == "Voyager")
		if case let .object(details)? = metadata["details"] {
			#expect(details["episode"]?.intValue == 7)
		}
		#expect(dictionaryConversion.objectValue?["title"]?.stringValue == "Voyager")
		if let unwoundDictionary = dictionaryConversion.value as? [String: Any] {
			#expect(unwoundDictionary["title"] as? String == "Voyager")
			#expect((unwoundDictionary["details"] as? [String: Any])?["episode"] as? Int == 7)
		} else {
			Issue.record("Dictionary .value did not unwind to [String: Any] from typed metadata input")
		}
	}
	
	@Test("Metadata and unsupported sentinels default appropriately")
	func metadataAndUnsupportedSentinelsDefaultAppropriately() {
		let metadata = Metadata(["status": "ok", "count": 2])
		let metadataWrapping = MetadataValue(metadata)
		if case let .object(wrappedMetadata) = metadataWrapping {
			#expect(wrappedMetadata["status"]?.stringValue == "ok")
			#expect(wrappedMetadata["count"]?.intValue == 2)
		} else {
			Issue.record("Metadata was not unwrapped as an object.")
		}
		
		let existing: MetadataValue = .string("prewrapped")
		#expect(MetadataValue(existing).stringValue == "prewrapped")
		
		let unsupported = MetadataValue(Date())
		#expect(unsupported.value is NSNull)
	}
}
