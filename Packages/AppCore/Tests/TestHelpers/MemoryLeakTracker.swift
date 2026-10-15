import Testing

/// Swift Testing's stand-in for XCTest's `addTeardownBlock { [weak instance] in XCTAssertNil(instance) }`.
///
/// Hold one as a stored property of a `final class` suite. Swift Testing releases the suite
/// after each test, which deinitializes the tracker and checks that every tracked instance is gone.
public final class MemoryLeakTracker {
    private struct Entry {
        weak var instance: AnyObject?
        let sourceLocation: SourceLocation
    }

    private var entries = [Entry]()

    public init() {}

    public func track(_ instance: AnyObject, sourceLocation: SourceLocation = #_sourceLocation) {
        entries.append(Entry(instance: instance, sourceLocation: sourceLocation))
    }

    deinit {
        for entry in entries {
            #expect(
                entry.instance == nil,
                "Instance should have been deallocated. Potential memory leak.",
                sourceLocation: entry.sourceLocation
            )
        }
    }
}
