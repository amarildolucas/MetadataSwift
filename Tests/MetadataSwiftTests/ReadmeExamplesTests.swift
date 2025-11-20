import Foundation
import Testing
@testable import MetadataSwift

@Suite("README examples")
struct ReadmeExamplesTests {
    @Test("Building metadata mirrors the documentation snippet")
    func usageSnippetMatchesReadme() {
        var metadata = Metadata()
        metadata["model"] = MetadataValue("orca-mini")
        metadata["maxTokens"] = MetadataValue(1024)
        metadata["config"] = MetadataValue([
            "temperature": 0.2,
            "tools": ["search", "execute"],
        ])
        metadata["notes"] = .nil

        let dictionary = metadata.dictionary
        let config = dictionary["config"] as? [String: Any]

        #expect(dictionary["model"] as? String == "orca-mini")
        #expect(dictionary["maxTokens"] as? Int == 1024)
        #expect(config?["temperature"] as? Double == 0.2)
        #expect(config?["tools"] as? [String] == ["search", "execute"])
        #expect(dictionary["notes"] is NSNull)
    }

    @Test("Bridging from [String: Any] mirrors README")
    func bridgingSnippetMatchesReadme() {
        let raw: [String: Any] = [
            "session": ["id": "abc", "retry": 1],
            "features": ["tools", "function_calls"],
            "nullSentinel": NSNull(),
        ]

        let metadata = Metadata(raw)
        let sessionDictionary = metadata["session"]?.objectValue?.dictionary

        #expect(sessionDictionary?["id"] as? String == "abc")
        #expect(sessionDictionary?["retry"] as? Int == 1)
        #expect(metadata["features"]?.arrayValue?.first?.stringValue == "tools")
        #expect(metadata["features"]?.arrayValue?.last?.stringValue == "function_calls")
        #expect(metadata["nullSentinel"]?.value is NSNull)
    }

    @Test("MetadataValue convenience accessors mirror README")
    func metadataValueSnippetMatchesReadme() {
        let source = MetadataValue(NSNumber(value: true))

        #expect(source.boolValue == true)
        #expect(source.intValue == nil)

        if case let .array(values) = MetadataValue(["search", 2, ["enabled": true]]) {
            let bridgedValues = values.map(\.value)
            #expect(bridgedValues[0] as? String == "search")
            #expect(bridgedValues[1] as? Int == 2)
            #expect((bridgedValues[2] as? [String: Any])?["enabled"] as? Bool == true)
        } else {
            Issue.record("README array example failed to produce an array case")
        }
    }

    @Test("Codable round-trip mirrors README")
    func codableSnippetMatchesReadme() throws {
        struct Run: Codable {
            var name: String
            var metadata: Metadata
        }

        var metadata = Metadata()
        metadata["model"] = MetadataValue("orca-mini")

        let run = Run(name: "Phase3", metadata: metadata)
        let data = try JSONEncoder().encode(run)
        let decoded = try JSONDecoder().decode(Run.self, from: data)

        #expect(decoded.metadata["model"]?.stringValue == "orca-mini")
    }
}
