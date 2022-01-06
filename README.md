# HLS Downloader

Downloads a HLS (m3u8 file format) to the user's device
## Supporting functions
- Download, pause, resume and cancel a download task

## Usage
Declare a set of cancelable objects to subcribe to a Combine publisher
```swift
var cancelables = Set<AnyCancellable>()
```
Subscribe to the file status
```swift
let hlsFile = HLSFile(url: URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!)
hlsFile.fileStatusPublisher.sink { status in
    print("Offline match status: \(status)")
}
.store(in: &cancelables)
````
### Download the file
```swift
hlsFile.download()
```
You can check whether the file is being download as below
```swift
hlsFile.download { isDownloading in
    print("File is downloading \(isDownloading)")
}
```
### Pause the download task
```swift
hlsFile.pause()
```

### Resume the download task
```swift
hlsFile.resume()
```

### Cancel the download task
```swift
hlsFile.cancel()
```
