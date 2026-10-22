//
//  PhotoViewController.swift
//  catfact
//

import UIKit

class PhotoViewController: UIViewController {

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 12
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .tertiaryLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let fetchButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "New Cat Photo"
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        fetchButton.addTarget(self, action: #selector(didTapFetch), for: .touchUpInside)
    }

    private func setupLayout() {
        view.addSubview(imageView)
        view.addSubview(fetchButton)
        view.addSubview(spinner)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: guide.centerYAnchor, constant: -40),
            imageView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 24),
            imageView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            spinner.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),

            fetchButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            fetchButton.centerXAnchor.constraint(equalTo: guide.centerXAnchor)
        ])
    }

    @objc private func didTapFetch() {
        spinner.startAnimating()
        fetchButton.isEnabled = false
        imageView.alpha = 0.3

        Task {
            defer {
                spinner.stopAnimating()
                fetchButton.isEnabled = true
                imageView.alpha = 1
            }

            do {
                imageView.image = try await CatAPI.fetchCatImage()
            } catch {
                imageView.image = UIImage(systemName: "exclamationmark.triangle")
                print("Failed to load cat photo: \(error)")
            }
        }
    }
}

#Preview {
    PhotoViewController()
}
