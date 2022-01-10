import Foundation
import Combine
import AVFoundation

public enum FileStatus {
    /// The match file has been downloaded and stored in local device
    case downloaded
    /// The file is being downloading from the server with percent
    case downloading(Double)
    /// The default status for the match file
    case unspecified
    /// An error occurs when downloading the file
    case error(Error)
}

public class HLSFile {
    public let fileStatusPublisher = CurrentValueSubject<FileStatus, Never>(.unspecified)
    let fileDownloader: HLSDownloaderSession
    let fileUserDefault: FileUserDefault

    public typealias CompletionClosure = (_ success: Bool) -> Void
    public typealias StatusClosure = (_ status: FileStatus) -> Void

    /// A URL from the server. It will be used to downloaded the file
    let url: URL
    private var cancelables = Set<AnyCancellable>()
    private(set) var lastDownloadedPercent: Double = 0.0

    public init(
        url: URL,
        fileDownloader: HLSDownloaderSession = .fileUserDefault,
        fileUserDefault: FileUserDefault = .shared
    ) {
        self.url = url
        self.fileDownloader = fileDownloader
        self.fileUserDefault = fileUserDefault
        // Load the status of the match file
        fileStatusPublisher.send(anotherStatus())
        observeStatus()
    }

    public func anotherStatus() -> FileStatus {
        if avAssetURL() != nil {
            return .downloaded
        } else {
            return .unspecified
        }
    }

    public func status(completionHandler: @escaping StatusClosure) {
        let percent = lastDownloadedPercent
        let anotherStatus = anotherStatus()
        fileDownloader.isDownloading(url: url) { isDownloading in
            if isDownloading {
                completionHandler(.downloading(percent))
            } else {
                completionHandler(anotherStatus)
            }
        }
    }

    private func observeStatus() {
        // Do not observe the status if it is downloaded.
        if case .downloaded = anotherStatus() { return }
        // Observes downloaded percent
        NotificationCenter
            .default
            .publisher(for: .downloadedPercent)
            .compactMap { $0.object as? HLSDownloaderSession.PercentNotification }
            .sink { percentNotification in
                guard percentNotification.url == self.url else { return }
                self.lastDownloadedPercent = percentNotification.percent
                self.fileStatusPublisher.send(.downloading(percentNotification.percent))
            }
            .store(in: &cancelables)
        // Observes the downloaded status
        NotificationCenter
            .default
            .publisher(for: .downloadCompleted)
            .compactMap { $0.object as? HLSDownloaderSession.DownloadCompletedNotification }
            .sink { downloadCompleted in
                guard downloadCompleted.url == self.url else { return }
                self.fileStatusPublisher.send(.downloaded)
            }
            .store(in: &cancelables)
        // Observes the error status
        NotificationCenter
            .default
            .publisher(for: .downloadError)
            .compactMap { $0.object as? HLSDownloaderSession.DownloadErrorNotification }
            .sink { downloadError in
                guard downloadError.url == self.url else { return }
                self.fileStatusPublisher.send(.error(downloadError.error))
            }
            .store(in: &cancelables)
    }

    /// Downloads the HLS file by providing a url
    /// - Parameters:
    ///   - title: a title of the file
    ///   - completionHandler: `true` if the file is being downloaded; otherwise `false`
    public func download(title: String = "", completionHandler: CompletionClosure? = nil) {
        // Do not download the file if it was download or downloading
        if case .downloaded = anotherStatus() {
            completionHandler?(false)
            return
        }

        // If the file is downloading, we should do nothing
        fileDownloader.isDownloading(url: url) { [unowned self] isDownloading in
            if !isDownloading {
                fileDownloader.download(url: url, title: title)
                completionHandler?(true)
                return
            }
            completionHandler?(false)
        }
    }

    /// Asynchronously pauses the download task
    /// - Parameter completionHandler: `true` if the download task is paused successfully; otherwise `false`
    public func pause(completionHandler: CompletionClosure? = nil) {
        fileDownloader.pause(url: url) { success in
            completionHandler?(success)
        }
    }

    /// Asynchronously resumes the download task
    /// - Parameter completionHandler: `true` if the download task is resumed successfully; otherwise `false`
    public func resume(completionHandler: CompletionClosure? = nil) {
        fileDownloader.resume(url: url) { success in
            completionHandler?(success)
        }
    }

    /// Asynchronously cancels the download task
    /// - Parameter completionHandler: `true` if the download task is cancels successfully; otherwise `false`
    public func cancel(completionHandler: CompletionClosure? = nil) {
        fileDownloader.cancel(url: url) { success in
            completionHandler?(success)
        }
    }

    /// Returns `AVURLAsset` for the current url
    /// Use this AVURLAsset to play the HLS file offline on a AVPlayer
    public func avAssetURL() -> AVURLAsset? {
        return fileUserDefault.fileLocation(from: url)
    }

    /// Delete the downloaded HLS file in user's local device
    public func delete() throws {
        try fileUserDefault.deleteFile(at: url)
    }

    /// Returns the playable url in user's device
    public func playableURL() -> URL? {
        fileUserDefault.playableURL(from: url)
    }

    deinit {
        print("\(self) deinit")
    }
}
