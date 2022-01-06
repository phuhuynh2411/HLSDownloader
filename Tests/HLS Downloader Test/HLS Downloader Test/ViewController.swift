//
//  ViewController.swift
//  HLS Downloader Test
//
//  Created by Huynh Tan Phu on 06/01/2022.
//

import UIKit
import HLS_Downloader

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        let hlsFile = HLSFile(url: URL(string: "")!)
        hlsFile.download()
    }
}
