//
//  Model.swift
//  BigImageViewer
//
//  Created by  Ivan Ushakov on 22.02.2020.
//  Copyright © 2020 Lunar Key. All rights reserved.
//

import UIKit
import Foundation

struct ImageFile {
    var url: URL
    var thumbnailUrl: URL
    var hash: String
}

typealias ImageCache = NSCache<NSString, UIImage>

enum LoadImageResult {
    case image(UIImage)
    case operation(LoadImageOperation)
}

class Model: NSObject {

    enum Event {
        case loading(Bool)
        case update
    }
    var eventSignal: ((Event) -> Void)?

    var itemsCount: Int {
        return files.count
    }

    private let queue = OperationQueue()
    private let cache = ImageCache()

    private var files = [ImageFile]() {
        didSet {
            eventSignal?(.update)
        }
    }

    private var loading = false {
        didSet {
            eventSignal?(.loading(loading))
        }
    }

    override init() {
        super.init()

        queue.name = "ImageOperationQueue"
        cache.countLimit = 100
        cache.delegate = self
    }

    func refresh() {
        if loading {
            return
        }
        loading = true

        let operation = LoadFilesOperation()
        OperationQueue.main.addOperation(UIOperation(parent: operation) { [weak self] in
            guard let this = self else {
                return
            }
            this.loading = false
            this.files = $0.result
        })
        queue.addOperation(operation)
    }

    func loadImage(with index: Int) -> LoadImageResult {
        let file = files[index]

        if let image = cache.object(forKey: file.hash as NSString) {
            Log.debug("cache object found for key = \(file.hash)")
            return .image(image)
        }

        let operation = LoadImageOperation(file: file, cache: cache)
        queue.addOperation(operation)
        return .operation(operation)
    }

    func getFile(for index: Int) -> ImageFile {
        return files[index]
    }
}

extension Model: NSCacheDelegate {

    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        Log.debug("cache will evict object")
    }
}
