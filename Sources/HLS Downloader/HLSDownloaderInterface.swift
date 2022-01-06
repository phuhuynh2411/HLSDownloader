//
//  HLSDownloaderInterface.swift
//  background
//
//  Created by Huynh Tan Phu on 05/01/2022.
//

import Foundation
import AVFoundation

protocol HLSDownloaderInterface {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL, original url: URL)
}
