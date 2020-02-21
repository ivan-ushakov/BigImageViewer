//
//  ImageViewController.swift
//  BigImageViewer
//
//  Created by  Ivan Ushakov on 24.02.2020.
//  Copyright © 2020 Lunar Key. All rights reserved.
//

import UIKit

final class ImageViewController: UIViewController {

    private let imageScrollView = ImageScrollView()
    private let file: ImageFile

    init(file: ImageFile) {
        self.file = file
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        title = file.url.lastPathComponent

        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageScrollView)

        NSLayoutConstraint.activate([
            imageScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageScrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            imageScrollView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])

        if let image = UIImage(contentsOfFile: file.url.path) {
            imageScrollView.setImage(image)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
