//
//  MatchFileManager.swift
//  HLS Downloader
//
//  Created by Huynh Tan Phu on 05/01/2022.
//

import Foundation
import AVFoundation

/// Manage the downloaded video in the user's device
public class DownloadFileManager: DownloadFileManagerInterface {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Returns `AVURLAsset` if the file was downloaded; otherwise `nil`
    /// - Parameter url: a url with a relative path to the file on user's device
    /// - Returns: `nil` or `AVURLAsset`
    public func fileLocation(from url: URL) -> AVURLAsset? {
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(url.relativePath)

        if fileManager.fileExists(atPath: assetURL.path) {
            let asset = AVURLAsset(url: assetURL)
            if let cache = asset.assetCache, cache.isPlayableOffline {
                // Set up player item and player and begin playback
                return asset
            } else {
                // Present Error: No playable version of this asset exists offline
                return nil
            }
        } else {
            return nil
        }
    }

    /// Deletes a file at the url relative path
    /// - Parameter url: a url with a relative path to the file on user's device
    public func deleteFile(at url: URL) throws {
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(url.relativePath)
        if fileManager.fileExists(atPath: assetURL.path) {
            try fileManager.removeItem(at: assetURL)
            print("[DownloadFileManager] deleted file at \(assetURL.absoluteString)")
        }
    }

    /// Returns a local url to a file in user's device that can be played by the AVPlayer.
    /// - Parameter url: the url returned from the server
    /// - Returns: a local url to the file in user's device or `nil`
    public func playableURL(from url: URL) -> URL? {
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(url.relativePath)

        if fileManager.fileExists(atPath: assetURL.path) {
            let asset = AVURLAsset(url: assetURL)
            if let cache = asset.assetCache, cache.isPlayableOffline {
                return assetURL
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

public protocol DownloadFileManagerInterface {
    func fileLocation(from url: URL) -> AVURLAsset?
    func deleteFile(at url: URL) throws
    func playableURL(from url: URL) -> URL?
}
