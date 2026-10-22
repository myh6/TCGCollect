import Foundation

/// Loads the bytes of an image. Implemented by the network (download) and by the disk cache.
public protocol ImageDataLoader {
    func loadImageData(from url: URL) async throws -> Data
}
