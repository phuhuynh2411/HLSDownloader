//
//  MatchFileManager.swift
//  HLS Downloader
//
//  Created by Huynh Tan Phu on 05/01/2022.
//

import Foundation
import AVFoundation

/// Manage the downloaded video in the user's device
class DownloadFileManager: DownloadFileManagerInterface {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Returns `AVURLAsset` if the file was downloaded; otherwise `nil`
    /// - Parameter url: a url with a relative path to the file on user's device
    /// - Returns: `nil` or `AVURLAsset`
    func fileLocation(from url: URL) -> AVURLAsset? {
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(url.relativePath)

        let asset = AVURLAsset(url: assetURL)
        if let cache = asset.assetCache, cache.isPlayableOffline {
            // Set up player item and player and begin playback
            return asset
        } else {
            // Present Error: No playable version of this asset exists offline
            return nil
        }
    }

    /// Deletes a file at the url relative path
    /// - Parameter url: a url with a relative path to the file on user's device
    func deleteFile(at url: URL) throws {
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(url.relativePath)
        if fileManager.fileExists(atPath: assetURL.path) {
            try fileManager.removeItem(at: assetURL)
            print("[DownloadFileManager] deleted file at \(assetURL.absoluteString)")
        }
    }
}

protocol DownloadFileManagerInterface {
    func fileLocation(from url: URL) -> AVURLAsset?
    func deleteFile(at url: URL) throws
}
