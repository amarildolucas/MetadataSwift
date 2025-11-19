import Testing
@testable import MetadataSwift

@Suite("Metadata dictionary behaviours")
struct MetadataDictionaryBehaviourTests {
    @Test("Empty init surfaces empty views")
    func emptyInitSurfacesEmptyViews() {
        let metadata = Metadata()

        #expect(metadata.dictionary.isEmpty)
        #expect(Array(metadata.keys).isEmpty)
        #expect(Array(metadata.values).isEmpty)
        #expect(metadata.isEmpty)
    }

    @Test("Dictionary init bridges nested structures through public views")
    func dictionaryInitializationBridgesNestedStructures() {
        let source: [String: Any] = [
            "title": "Voyager",
            "duration": 42,
            "details": ["season": 3, "episode": 7],
            "tags": ["series", "cinema"],
            "isFeatured": true
        ]

        let metadata = Metadata(source)
        let dictionary = metadata.dictionary

        #expect(dictionary["title"] as? String == "Voyager")
        #expect(dictionary["duration"] as? Int == 42)
        #expect((dictionary["details"] as? [String: Any])?["season"] as? Int == 3)
        #expect((dictionary["details"] as? [String: Any])?["episode"] as? Int == 7)
        #expect(dictionary["tags"] as? [String] == ["series", "cinema"])
        #expect(dictionary["isFeatured"] as? Bool == true)

        #expect(Set(metadata.keys) == Set(source.keys))
        #expect(Array(metadata.values).count == source.count)
        #expect(metadata.isEmpty == false)
    }

    @Test("Subscript mutation and removal reflect through all observable views")
    func subscriptMutationAndRemovalReflectThroughViews() {
        var metadata = Metadata(["role": "observer"])

        metadata["role"] = .string("author")
        metadata["visits"] = .int(2)

        #expect(metadata.dictionary["role"] as? String == "author")
        #expect(metadata.dictionary["visits"] as? Int == 2)
        #expect(Set(metadata.keys) == Set(["role", "visits"]))
        #expect(Array(metadata.values).count == 2)
        #expect(metadata.isEmpty == false)

        metadata["role"] = nil
        #expect(metadata.dictionary["role"] == nil)
        #expect(Set(metadata.keys) == Set(["visits"]))
        #expect(Array(metadata.values).count == 1)

        metadata["visits"] = nil
        #expect(metadata.dictionary.isEmpty)
        #expect(Array(metadata.keys).isEmpty)
        #expect(Array(metadata.values).isEmpty)
        #expect(metadata.isEmpty)
    }
}
