//
//  Operations.swift
//  BigImageViewer
//
//  Created by  Ivan Ushakov on 21.02.2020.
//  Copyright © 2020 Lunar Key. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

final class UIOperation<T: Operation>: Operation {

    private let parent: T
    private let callback: (T) -> Void

    init(parent: T, callback: @escaping (T) -> Void) {
        self.parent = parent
        self.callback = callback
        super.init()

        addDependency(parent)
    }

    override func main() {
        if !parent.isCancelled {
            callback(parent)
        }
    }
}

final class LoadFilesOperation: Operation {

    var result = [ImageFile]()

    private let allowedExtensions = ["jpeg", "jpg", "tif", "tiff", "png"]

    override func main() {
        if isCancelled {
            return
        }

        let manager = FileManager.default
        guard let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        guard let files = try? manager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return
        }

        Log.debug("image files count = \(files.count)")

        result = files.compactMap { file in
            if allowedExtensions.contains(file.pathExtension.lowercased()) {
                if let hash = MD5(string: file.lastPathComponent) {
                    let thumbnailUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(hash)
                    return ImageFile(url: file, thumbnailUrl: thumbnailUrl, hash: hash)
                }
            }
            return nil
        }
    }
}

final class LoadImageOperation: Operation {

    var result: UIImage?

    private let thumbnailMaxPixelSize = 128

    private let file: ImageFile
    private let cache: ImageCache

    init(file: ImageFile, cache: ImageCache) {
        self.file = file
        self.cache = cache
        super.init()
    }

    override func main() {
        if isCancelled {
            return
        }

        if let image = getImage() {
            cache.setObject(image, forKey: file.hash as NSString)
            result = image
        }
    }

    private func getImage() -> UIImage? {
        if FileManager.default.isReadableFile(atPath: file.thumbnailUrl.path) {
            Log.debug("thumbnail file found for key = \(file.hash)")
            return UIImage(contentsOfFile: file.thumbnailUrl.path)
        }

        guard let source = CGImageSourceCreateWithURL(file.url as CFURL, nil) else {
            Log.error("create image source")
            return nil
        }

        if !needThumbnail(source) {
            guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                Log.error("create original image")
                return nil
            }
            return UIImage(cgImage: image)
        }

        let options = [kCGImageSourceThumbnailMaxPixelSize: thumbnailMaxPixelSize]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            Log.error("create thumbnail")
            return nil
        }

        if let destination = CGImageDestinationCreateWithURL(file.thumbnailUrl as CFURL, kUTTypeJPEG, 1, nil) {
            CGImageDestinationAddImage(destination, image, nil)
            if !CGImageDestinationFinalize(destination) {
                Log.error("write thumbnail to disk")
            }
        }

        return UIImage(cgImage: image)
    }

    private func needThumbnail(_ source: CGImageSource) -> Bool {
        guard let properties: NSDictionary = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else {
            return true
        }

        guard let width = properties[kCGImagePropertyPixelWidth] as? NSNumber else {
            return true
        }
        guard let height = properties[kCGImagePropertyPixelHeight] as? NSNumber else {
            return true
        }

        return max(width.intValue, height.intValue) > thumbnailMaxPixelSize
    }
}
