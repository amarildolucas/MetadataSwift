import Foundation

/// Type-safe metadata container backed by `[String: MetadataValue]`.
public struct Metadata: Sendable, Codable {
    private var storage: [String: MetadataValue]

    public init() {
        self.storage = [:]
    }

    /// Creates metadata from a heterogeneous dictionary, recursively wrapping values
    /// into `MetadataValue` so nested structures remain strongly typed.
    public init(_ dictionary: [String: Any]) {
        var converted: [String: MetadataValue] = [:]
        converted.reserveCapacity(dictionary.count)
        for (key, value) in dictionary {
            converted[key] = MetadataValue(value)
        }
        self.storage = converted
    }

    init(storage: [String: MetadataValue]) {
        self.storage = storage
    }

    public var dictionary: [String: Any] {
        var result: [String: Any] = [:]
        result.reserveCapacity(storage.count)
        for (key, value) in storage {
            result[key] = value.value
        }
        return result
    }

    public var keys: Dictionary<String, MetadataValue>.Keys {
        storage.keys
    }

    public var values: Dictionary<String, MetadataValue>.Values {
        storage.values
    }

    public var isEmpty: Bool {
        storage.isEmpty
    }

    public subscript(key: String) -> MetadataValue? {
        get { storage[key] }
        set {
            if let newValue {
                storage[key] = newValue
            } else {
                storage.removeValue(forKey: key)
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        for (key, value) in storage {
            guard let codingKey = DynamicCodingKeys(stringValue: key) else {
                preconditionFailure("DynamicCodingKeys should always produce a key for \(key)")
            }
            try container.encode(value, forKey: codingKey)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var decoded: [String: MetadataValue] = [:]
        decoded.reserveCapacity(container.allKeys.count)
        for key in container.allKeys {
            decoded[key.stringValue] = try container.decode(MetadataValue.self, forKey: key)
        }
        self.storage = decoded
    }
}
