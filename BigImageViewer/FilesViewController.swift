//
//  FilesViewController.swift
//  BigImageViewer
//
//  Created by  Ivan Ushakov on 21.02.2020.
//  Copyright © 2020 Lunar Key. All rights reserved.
//

import UIKit

final class FilesViewController: UIViewController {

    private let model = Model()

    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.identifier)
        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
            layout.itemSize = CGSize(width: 64, height: 64)
        }
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 5),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5)
        ])

        model.eventSignal = { [weak self] event in
            self?.handleEvent(event)
        }
        model.refresh()
    }

    private func handleEvent(_ event: Model.Event) {
        switch event {
        case .loading(let value):
            if value {
                if collectionView.refreshControl?.isRefreshing == false {
                    collectionView.refreshControl?.beginRefreshing()
                }
            } else {
                collectionView.refreshControl?.endRefreshing()
            }
        case .update:
            title = "\(model.itemsCount) files"
            collectionView.reloadData()
        }
    }

    @objc private func handleRefreshControl() {
        model.refresh()
    }
}

extension FilesViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.itemsCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as? ImageCell else {
            fatalError()
        }
        cell.setup(model.loadImage(with: indexPath.item))
        return cell
    }
}

extension FilesViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = ImageViewController(file: model.getFile(for: indexPath.item))
        navigationController?.pushViewController(controller, animated: true)
    }
}

private class ImageCell: UICollectionViewCell {

    static let identifier = String(describing: ImageCell.self)

    private let imageView = UIImageView()
    private weak var operation: LoadImageOperation?

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(_ result: LoadImageResult) {
        switch result {
        case .image(let image):
            imageView.image = image
        case .operation(let operation):
            OperationQueue.main.addOperation(UIOperation(parent: operation) { [weak self] in
                if let this = self, this.operation === $0 {
                    this.imageView.image = $0.result
                }
            })
            self.operation = operation
        }
    }

    override func prepareForReuse() {
        operation?.cancel()
        operation = nil

        imageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView.frame = bounds
    }
}
