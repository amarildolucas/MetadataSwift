import Foundation
import Testing
@testable import MetadataSwift

@Suite("Metadata null semantics")
struct MetadataNullSemanticsBehaviourTests {
    @Test("Metadata surfaces explicit and inferred nulls through dictionary and Codable views")
    func metadataSurfacesNulls() throws {
        var metadata = Metadata()
        metadata["explicitNull"] = .nil
        metadata["fromUnsupported"] = MetadataValue(Date())
        metadata["nested"] = .object(Metadata(["child": NSNull()]))

        let dictionary = metadata.dictionary
        #expect(dictionary["explicitNull"] is NSNull)
        #expect(dictionary["fromUnsupported"] is NSNull)
        if let nested = dictionary["nested"] as? [String: Any] {
            #expect(nested["child"] is NSNull)
        } else {
            Issue.record("Nested dictionary should surface NSNull child")
        }

        let data = try JSONEncoder().encode(metadata)
        let decoded = try JSONDecoder().decode(Metadata.self, from: data)

        if case .nil? = decoded["explicitNull"] {
            // expected
        } else {
            Issue.record("Decoded metadata should preserve explicit null")
        }
        if case .nil? = decoded["fromUnsupported"] {
            // expected
        } else {
            Issue.record("Decoded metadata should preserve inferred null")
        }
        if case let .object(nestedMetadata)? = decoded["nested"] {
            if case .nil? = nestedMetadata["child"] {
                // expected
            } else {
                Issue.record("Nested metadata should preserve child null")
            }
        } else {
            Issue.record("Nested metadata should rehydrate as object")
        }
    }

    @Test("MetadataValue encodes and decodes the null case explicitly")
    func metadataValueNullRoundTrip() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(MetadataValue.nil)
        let decoded = try JSONDecoder().decode(MetadataValue.self, from: data)

        if case .nil = decoded {
            #expect(decoded.value is NSNull)
        } else {
            Issue.record("Decoded value should be the .nil case")
        }
    }
}
