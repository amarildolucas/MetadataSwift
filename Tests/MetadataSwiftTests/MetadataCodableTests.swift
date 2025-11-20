import Foundation
import Testing
@testable import MetadataSwift

@Suite("Metadata Codable behaviours")
struct MetadataCodableBehaviourTests {
    @Test("Metadata encodes and decodes through JSON round-trips")
    func metadataEncodesAndDecodesThroughJSONRoundTrips() throws {
        let source: [String: Any] = [
            "title": "Voyager",
            "details": ["season": 3, "episode": 7],
            "tags": ["series", "cinema"],
            "ratings": [
                ["source": "imdb", "score": 8.7],
                ["source": "rt", "score": 90]
            ],
            "isFeatured": true
        ]

        let metadata = Metadata(source)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(metadata)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Metadata.self, from: data)

        #expect(decoded.dictionary["title"] as? String == "Voyager")
        let decodedDetails = decoded.dictionary["details"] as? [String: Any]
        #expect(decodedDetails?["season"] as? Int == 3)
        #expect(decodedDetails?["episode"] as? Int == 7)
        #expect(decoded.dictionary["tags"] as? [String] == ["series", "cinema"])
        if let ratings = decoded.dictionary["ratings"] as? [[String: Any]] {
            #expect(ratings.count == 2)
            #expect(ratings[0]["source"] as? String == "imdb")
            #expect(ratings[1]["source"] as? String == "rt")
        } else {
            Issue.record("Ratings should decode as array of dictionaries")
        }
    }

    @Test("MetadataValue decodes plain JSON fragments through fallback path")
    func metadataValueDecodesPlainJSONFragments() throws {
        let decoder = JSONDecoder()

        let stringValue = try decoder.decode(MetadataValue.self, from: Data("\"Voyager\"".utf8))
        #expect(stringValue.stringValue == "Voyager")

        let arrayPayload = Data("[\"Voyager\", 7, {\"flag\": true}]".utf8)
        let arrayValue = try decoder.decode(MetadataValue.self, from: arrayPayload)
        if case let .array(values) = arrayValue {
            #expect(values.count == 3)
            #expect(values[0].stringValue == "Voyager")
            #expect(values[1].intValue == 7)
            if case let .object(object) = values[2] {
                #expect(object["flag"]?.boolValue == true)
            } else {
                Issue.record("Third entry should decode as object")
            }
        } else {
            Issue.record("Array payload should decode as .array")
        }

        let objectPayload = Data("{\"title\": \"Voyager\", \"count\": 7}".utf8)
        let objectValue = try decoder.decode(MetadataValue.self, from: objectPayload)
        if case let .object(metadata) = objectValue {
            #expect(metadata["title"]?.stringValue == "Voyager")
            #expect(metadata["count"]?.intValue == 7)
        } else {
            Issue.record("Object payload should decode as .object")
        }
    }

    @Test("MetadataValue decoding surfaces the type mismatch error for unsupported payloads")
    func metadataValueDecodingSurfacesTypeMismatchError() {
        let decoder = JSONDecoder()
        let invalidPayload = Data("{\"string\": 1}".utf8)

        do {
            _ = try decoder.decode(MetadataValue.self, from: invalidPayload)
            Issue.record("Decoding should fail for mismatched discriminated payload")
        } catch let error as DecodingError {
            switch error {
            case .typeMismatch:
                break
            default:
                Issue.record("Unexpected error: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
