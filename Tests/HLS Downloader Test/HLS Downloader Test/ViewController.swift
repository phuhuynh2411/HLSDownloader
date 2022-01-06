//
//  ViewController.swift
//  HLS Downloader Test
//
//  Created by Huynh Tan Phu on 06/01/2022.
//

import UIKit
import Combine
import HLS_Downloader

class ViewController: UIViewController {
    var cancelables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        let hlsFile = HLSFile(url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!)
        hlsFile.fileStatusPublisher.sink { status in
            print("Offline match status: \(status)")
        }
        .store(in: &cancelables)

        hlsFile.download { isDownloading in
            print("File is downloading \(isDownloading)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            hlsFile.pause { success in
                print("Dowloading is paused: \(success)")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            hlsFile.resume { success in
                print("Dowloading is resumed: \(success)")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
            hlsFile.cancel { success in
                print("Dowloading is cancel: \(success)")
            }
        }
    }
}
