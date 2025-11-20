# MetadataSwift

MetadataSwift is a tiny utility library that replaces untyped `[String: Any]` with a pair of `Metadata` and `MetadataValue` types. It keeps hierarchical metadata predictable, makes it easy to serialize with `Codable`, and is marked `Sendable` so you can move values across Swift concurrency domains safely.

*Note:* It was developed to simplify the process of working with deeply nested JSON objects or function calls and tools (LLMs), while also extracting information in a more structured format.

## Highlights
- Store heterogeneous values behind `[String: MetadataValue]` without losing type information.
- Initialize from `[String: Any]`, `NSArray`, or `NSDictionary` inputs and recursively wrap nested arrays/objects.
- Convert back to legacy representations via `Metadata.dictionary` and `MetadataValue.value`, including explicit `NSNull` handling.
- Encode and decode Metadata through `JSONEncoder`/`JSONDecoder` while preserving arbitrary user-provided keys.
- Leverage typed accessors on `MetadataValue` (`stringValue`, `intValue`, `doubleValue`, `boolValue`) plus convenience types such as `.arrayValue` and `.objectValue`.

## Usage
Import the package wherever you need to shuttle untyped metadata through a strongly typed layer.

```shell
dependencies: [
    .package(url: "https://github.com/amarildolucas/metadata-swift", from: "1.0.0")
]
```


```swift
import MetadataSwift

var metadata = Metadata()
metadata["model"] = MetadataValue("orca-mini")
metadata["maxTokens"] = MetadataValue(1024)
metadata["config"] = MetadataValue([
    "temperature": 0.2,
    "tools": ["search", "execute"],
])
metadata["notes"] = .nil

print(metadata.dictionary)
// ["config": ["temperature": 0.2, "tools": ["search", "execute"]], "model": "orca-mini", "maxTokens": 1024, "notes": <null>]
```

### Bridging from `[String: Any]`
If you already receive metadata as `[String: Any]`, pass it directly to the initializer. Every entry gets converted to the right `enum case`, including deeply nested dictionaries and arrays.

```swift
let raw: [String: Any] = [
    "session": ["id": UUID().uuidString, "retry": 1],
    "features": ["tools", "function_calls"],
    "nullSentinel": NSNull()
]

let bridged = Metadata(raw)
print(bridged["session"]?.objectValue?.dictionary ?? [:])
// ["id": "...", "retry": 1]
```

### Working with `MetadataValue`
`MetadataValue` exposes convenience accessors so you can pull primitive scalars without switching on the `enum` manually.

```swift
let source = MetadataValue(NSNumber(value: true))
print(source.boolValue)    // true
print(source.intValue)     // nil because it was treated as a Bool

if case let .array(values) = MetadataValue(["search", 2, ["enabled": true]]) {
    print(values.map(\.value))
    // ["search", 2, ["enabled": true]]
}
```

### Codable round-trips
Both `Metadata` and `MetadataValue` adopt `Codable`, so you can persist them inside your own models.

```swift
struct Run: Codable {
    var name: String
    var metadata: Metadata
}

let run = Run(name: "Phase3", metadata: metadata)
let data = try JSONEncoder().encode(run)
let decoded = try JSONDecoder().decode(Run.self, from: data)

if let model = decoded.metadata["model"]?.stringValue {
    print("Decoded model:", model)
}
```

## Testing
Run the full suite (BDD-style scenarios) before submitting patches:

```
swift test
```
