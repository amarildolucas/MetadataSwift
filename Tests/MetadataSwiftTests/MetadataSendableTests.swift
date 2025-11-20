import Foundation
import Testing
@testable import MetadataSwift

@Suite("Metadata sendable assurance")
struct MetadataSendableBehaviourTests {
    @Test("Metadata and MetadataValue satisfy Sendable constraints")
    func typesConformToSendable() {
        func requireSendable<T: Sendable>(_ value: T) {
            _ = value
        }

        let metadata = Metadata(["title": "Voyager"])
        requireSendable(metadata)

        let metadataValue = MetadataValue(["season": 3])
        requireSendable(metadataValue)
    }

    @Test("Metadata travels across Task boundaries without Sendable diagnostics")
    func metadataTravelsAcrossTasks() async throws {
        let metadata = Metadata(["title": "Voyager", "details": ["episode": 7]])

        let task = Task.detached { metadata }
        let result = await task.value

        #expect(result["title"]?.stringValue == "Voyager")
        if let details = result["details"]?.objectValue {
            #expect(details["episode"]?.intValue == 7)
        } else {
            Issue.record("Details should rehydrate as nested metadata")
        }
    }
}
