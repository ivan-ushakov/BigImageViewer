//
//  ImageScrollView.swift
//  BigImageViewer
//
//  Created by  Ivan Ushakov on 24.02.2020.
//  Copyright © 2020 Lunar Key. All rights reserved.
//

import UIKit

/// Based on Apple's project LargeImageDownsizing
final class ImageScrollView: UIScrollView {

    private let backgroundImageView = UIImageView()

    private var frontTiledView: TiledImageView?
    private var backTiledView: TiledImageView?

    private var minimumScale: CGFloat = 0
    private var imageScale: CGFloat = 0

    private var image = UIImage()
    private var imageSize = CGSize.zero
    private var lastSize = CGSize.zero

    override init(frame: CGRect) {
        super.init(frame: frame)

        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = .fast
        delegate = self
        maximumZoomScale = 5.0
        minimumZoomScale = 0.25
        backgroundColor = UIColor.white

        addSubview(backgroundImageView)
        sendSubviewToBack(backgroundImageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image: UIImage) {
        self.image = image
        self.imageSize = CGSize(width: image.cgImage?.width ?? 0, height: image.cgImage?.height ?? 0)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if bounds.size != .zero, lastSize != bounds.size {
            lastSize = bounds.size
            update()
        }

        var frameToCenter = frontTiledView?.frame ?? CGRect.zero
        if frameToCenter.size.width < lastSize.width {
            frameToCenter.origin.x = round((lastSize.width - frameToCenter.size.width) / 2)
        } else {
            frameToCenter.origin.x = 0
        }

        if frameToCenter.size.height < lastSize.height {
            frameToCenter.origin.y = round((lastSize.height - frameToCenter.size.height) / 2)
        } else {
            frameToCenter.origin.y = 0
        }

        frontTiledView?.frame = frameToCenter
        backgroundImageView.frame = frameToCenter
        frontTiledView?.contentScaleFactor = 1
    }

    private func update() {
        imageScale = frame.size.width / imageSize.width
        minimumScale = imageScale * 0.75
        let imageFrame = CGRect(
            x: 0,
            y: 0,
            width: round(imageSize.width * imageScale),
            height: round(imageSize.height * imageScale)
        )

        UIGraphicsBeginImageContext(imageFrame.size)
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState()
            image.draw(in: imageFrame)
            context.restoreGState()
        }
        backgroundImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let view = TiledImageView(frame: imageFrame, image: image, scale: imageScale)
        addSubview(view)
        frontTiledView?.removeFromSuperview()
        frontTiledView = view
    }
}

extension ImageScrollView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return frontTiledView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        backTiledView?.removeFromSuperview()
        backTiledView = frontTiledView
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        imageScale *= scale
        imageScale = max(imageScale, minimumScale)

        let imageFrame = CGRect(
            x: 0,
            y: 0,
            width: round(imageSize.width * imageScale),
            height: round(imageSize.height * imageScale)
        )
        let view = TiledImageView(frame: imageFrame, image: image, scale: imageScale)
        addSubview(view)
        frontTiledView = view
    }
}

private class TiledImageView: UIView {

    override class var layerClass: AnyClass {
        return CATiledLayer.self
    }

    private let image: UIImage
    private let scale: CGFloat
    private let imageFrame: CGRect

    init(frame: CGRect, image: UIImage, scale: CGFloat) {
        self.image = image
        self.scale = scale
        self.imageFrame = CGRect(
            x: 0,
            y: 0,
            width: image.cgImage?.width ?? 0,
            height: image.cgImage?.height ?? 0
        )
        super.init(frame: frame)

        if let tiledLayer = layer as? CATiledLayer {
            tiledLayer.levelsOfDetail = 4
            tiledLayer.levelsOfDetailBias = 4
            tiledLayer.tileSize = CGSize(width: 512.0, height: 512.0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        context.saveGState()
        context.scaleBy(x: scale, y: scale)
        image.draw(in: imageFrame)
        context.restoreGState()
    }
}
