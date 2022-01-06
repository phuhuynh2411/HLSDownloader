import Foundation
import AVFoundation

/// A class to manage the downloaded match videos in the user defaults
public class FileUserDefault: DownloadFileManagerInterface {
    /// A strong referecen to user defaults
    private let userDefaults: UserDefaults
    /// A dictionary of the downloaded matches.
    /// The key would be the url returned from the server.
    /// The value is the relative path of the file in the user device
    private var downloadedFiles = [String: String]()
    /// A key to store the downloaded matches in the user defaults
    private let downloadedFilesKey = "downloadedFilesKey"
    public static let shared = FileUserDefault()
    let matchFileManager: DownloadFileManagerInterface

    init(
        userDefaults: UserDefaults = .standard,
        matchFileManager: DownloadFileManagerInterface = DownloadFileManager()
    ) {
        self.userDefaults = userDefaults
        self.matchFileManager = matchFileManager
        load()
    }

    /// Load the downloaded matches from the user defaults
    private func load() {
        downloadedFiles = userDefaults.object(forKey: downloadedFilesKey) as? [String: String] ?? [: ]
    }

    /// Save downloaded matches to user defaults
    private func save() {
        userDefaults.set(downloadedFiles, forKey: downloadedFilesKey)
        print("[MatchUserDefault] Match UserDefaults has been updated \(downloadedFiles)")
    }

    /// Append a newly downloaded match to the dictionary and save to user defaults
    /// - Parameters:
    ///   - location: a relative path where the downloaded file located
    ///   - url: a url returned from the server
    func append(location: URL, url: URL) {
        downloadedFiles[url.absoluteString] = location.relativePath
        save()
    }

    /// Returns an `AVURLAsset`
    /// - Parameter url: the url returned from the server
    /// - Returns: an `AVURLAsset` if the file has been downloaded and contains in the dictionary or `nil`
    func fileLocation(from url: URL) -> AVURLAsset? {

        guard let filePath = downloadedFiles[url.absoluteString] else { return nil }
        let fileURL = URL(fileURLWithPath: filePath)
        return matchFileManager.fileLocation(from: fileURL)
    }

    /// Delete a file at url
    /// - Parameter url: the url returned from the server
    func deleteFile(at url: URL) throws {
        guard let filePath = downloadedFiles[url.absoluteString] else { return }
        let fileURL = URL(fileURLWithPath: filePath)
        try matchFileManager.deleteFile(at: fileURL)
        // Remove the key and value in the downloaded matches dictionary
        downloadedFiles.removeValue(forKey: url.absoluteString)
    }

    deinit {
        print("\(self) deinit")
    }
}

// MARK: - HLSDownloaderInterface
extension FileUserDefault: HLSDownloaderInterface {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL, original url: URL) {
        append(location: location, url: url)
    }
}
