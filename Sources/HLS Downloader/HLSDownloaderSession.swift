//
//  HLSDownloader.swift
//  HLS Downloader
//
//  Created by Huynh Tan Phu on 04/01/2022.
//

import Foundation
import AVFoundation

/// A HLSDownloader session
class HLSDownloaderSession: NSObject {
    /// The background identifier
    private let downloadIndentifier = "filesoft.co.background"
    /// A notification center
    private let notification: NotificationCenter
    /// A downloader interface
    public var downloaderInterface: HLSDownloaderInterface?

    public static let shared = HLSDownloaderSession()

    let fileManager: DownloadFileManagerInterface

    public init(
        notification: NotificationCenter = .default,
        downloaderInterface: HLSDownloaderInterface? = nil,
        fileManager: DownloadFileManagerInterface = DownloadFileManager()
    ) {
        self.notification = notification
        self.downloaderInterface = downloaderInterface
        self.fileManager = fileManager
    }

    /// An asset download url session
    private lazy var session: AVAssetDownloadURLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: downloadIndentifier)
        return AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
    }()

    /// Downloads HLS file at a url
    /// - Parameters:
    ///   - url: a url to the .m3u8 file for example: https://dtsprhs5m8oca.cloudfront.net/0/314/fullMatch.m3u8
    ///   - title: an asset title
    public func download(url: URL, title: String = "") {
        let asset = AVURLAsset(url: url, options: nil)
        // Create new AVAssetDownloadTask for the desired asset
        let downloadTask = session.makeAssetDownloadTask(
            asset: asset,
            assetTitle: title,
            assetArtworkData: nil,
            options: nil
        )
        downloadTask?.taskDescription = url.absoluteString
        // Start task and begin download
        downloadTask?.resume()
    }

    /// Checks if the current url is being downloaded
    /// - Parameters:
    ///   - url: a url that is being downloaded
    ///   - completionHandler: `true` if the file is being downloaded; otherwise `false`
    public func isDownloading(url: URL, _ completionHandler: @escaping (_ isDownloading: Bool) -> Void) {
        downloadTask(for: url) { downloadTask in
            downloadTask != nil ? completionHandler(true) : completionHandler(false)
        }
    }

    deinit {
        print("\(self) denint")
    }

    public func restorePendingDownloads() {
        // Grab all the pending tasks associated with the downloadSession
        session.getAllTasks { tasksArray in
            // For each task, restore the state in the app
            for task in tasksArray {
                guard let downloadTask = task as? AVAssetDownloadTask else { break }
                downloadTask.resume()
                print("[HLSDownloader] Resume downloading task \(downloadTask.urlAsset)")
            }
        }
    }

    /// Pauses the download task for a specific url
    /// - Parameters:
    ///   - url: the url that is being downloaded
    ///   - completionHandler: `true` if the download task is paused successfully; otherwise `false`
    public func pause(url: URL, _ completionHandler: @escaping (_ success: Bool) -> Void) {
        downloadTask(for: url) { downloadTask in
            if let task = downloadTask {
                task.suspend()
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }

    /// Resumes the paused task
    /// - Parameters:
    ///   - url: a url that is being downloaded
    ///   - completionHandler: `true` if the task has been resumed; otherwise `false`
    public func resume(url: URL, _ completionHandler: @escaping (_ success: Bool) -> Void) {
        downloadTask(for: url) { downloadTask in
            if let task = downloadTask {
                task.resume()
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }

    /// Cancels a download task
    /// - Parameters:
    ///   - url: a url that is being downloaded
    ///   - completionHandler: `true` if the download task is cancelled; otherwise `false`
    public func cancel(url: URL, _ completionHandler: @escaping (_ success: Bool) -> Void) {
        downloadTask(for: url) { downloadTask in
            if let task = downloadTask {
                task.cancel()
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }

    /// Searchs for a download task for a specific url
    /// - Parameters:
    ///   - url: a url that is being downloaded
    ///   - completionHandler: a `AVAssetDownloadTask` if any; otherwise `nil`
    private func downloadTask(for url: URL, completionHandler: @escaping (_ downloadTask: AVAssetDownloadTask?) -> Void) {
        session.getAllTasks { tasksArray in
            // For each task, restore the state in the app
            for task in tasksArray {
                guard let downloadTask = task as? AVAssetDownloadTask else { break }
                if downloadTask.taskDescription == url.absoluteString {
                    completionHandler(downloadTask)
                    return
                }
            }
            completionHandler(nil)
        }
    }

    /// A type of posting percent notification by using Notification Center
    public class PercentNotification {
        let url: URL
        let percent: Double

        init(url: URL, percent: Double) {
            self.url = url
            self.percent = percent
        }
    }

    public class DownloadCompletedNotification {
        let url: URL
        let location: URL

        init(url: URL, location: URL) {
            self.url = url
            self.location = location
        }
    }

    public class DownloadErrorNotification {
        let url: URL
        let error: Error

        init(url: URL, error: Error) {
            self.url = url
            self.error = error
        }
    }
}

extension HLSDownloaderSession: AVAssetDownloadDelegate {
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        var percentComplete = 0.0
        // Iterate through the loaded time ranges
        for value in loadedTimeRanges {
            // Unwrap the CMTimeRange from the NSValue
            let loadedTimeRange = value.timeRangeValue
            // Calculate the percentage of the total expected asset duration
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        percentComplete *= 100

        // Post the completed percent to the notification center
        let url = assetDownloadTask.urlAsset.url
        print("[HLSDownloader] \(url) -> \(percentComplete)")
        notification.post(name: .downloadedPercent, object: PercentNotification(url: url, percent: percentComplete))
    }

    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        print("[HLSDownloader] Location: \(location.relativePath)")

        // If the task was completed with an error,
        // delete the partial download file
        if assetDownloadTask.error != nil {
            do {
                let fileURL = URL(fileURLWithPath: location.relativePath)
                try fileManager.deleteFile(at: fileURL)
            } catch {
                print("[HLSDownloader] delete partial download file with error \(error)")
            }
        } else {
            // If the task completed successfully without any errors
            let url = assetDownloadTask.urlAsset.url
            notification.post(name: .downloadCompleted, object: DownloadCompletedNotification(url: url, location: location))
            // Pass the result to the interface if any
            downloaderInterface?.urlSession(session, assetDownloadTask: assetDownloadTask, didFinishDownloadingTo: location, original: url)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        print("[HLSDownloader] Error: \(error.localizedDescription)")
        if let taskDescription = task.taskDescription,
           let url = URL(string: taskDescription) {
            notification.post(name: .downloadError, object: DownloadErrorNotification(url: url, error: error))
        }
    }
}


extension Notification.Name {
    static let downloadedPercent = Notification.Name("downloadedPercent")
    static let downloadCompleted = Notification.Name("downloadCompleted")
    static let downloadError = Notification.Name("downloadError")
}

extension HLSDownloaderSession {
    public static let fileUserDefault: HLSDownloaderSession = {
        let session: HLSDownloaderSession = .shared
        session.downloaderInterface = FileUserDefault.shared
        return session
    }()
}
