import Foundation

public final class FileDownloader: NSObject, @unchecked Sendable {
    public static let shared = FileDownloader()
    
    private let fileManager: FileManager
    
    private override init() {
        fileManager = .default
    }
    
    private let lock = NSLock()
    
    private var tasks: [URL: Task<URL, Error>] = [:]
    
    @discardableResult
    public func downloadFile(from url: URL) async throws -> URL {
        let fileURL = fileURL(for: url)
        if isFileDownloaded(from: url) {
            return fileURL
        }
        
        if let task = lock.withLock({ tasks[url] }) {
            return try await task.value
        }
        
        let task = Task {
            let (tempURL, _) = try await URLSession.shared.download(from: url, delegate: self)
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileManager.moveItem(at: tempURL, to: fileURL)
            return fileURL
        }
        
        lock.withLock { tasks[url] = task }
        
        do {
            let fileURL = try await task.value
            lock.withLock { tasks[url] = nil }
            return fileURL
        } catch {
            lock.withLock { tasks[url] = nil }
            throw error
        }
    }
    
    public func isFileDownloaded(from url: URL) -> Bool {
        let fileURL = fileURL(for: url)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    public func fileURL(for url: URL) -> URL {
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("me.libei.FileDownloader", isDirectory: true)
            .appendingPathComponent(url.host!, isDirectory: true)
            .appendingPathComponent(url.path)
    }
}

// MARK: - URLSessionTaskDelegate

extension FileDownloader: URLSessionTaskDelegate {
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest: URLRequest
    ) async -> URLRequest? {
        return newRequest
    }
}
