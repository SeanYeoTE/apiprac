//
//  CatViewController.swift
//  catfact
//

import UIKit

class CatViewController: UIViewController {

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 12
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .tertiaryLabel
        return imageView
    }()

    private let factLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap the button for a cat fact and photo 🐱"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title3)
        return label
    }()

    private let fetchButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "New Cat"
        return UIButton(configuration: config)
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
        let stack = UIStackView(arrangedSubviews: [imageView, factLabel, fetchButton])
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        view.addSubview(spinner)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(greaterThanOrEqualTo: guide.topAnchor, constant: 16),

            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            spinner.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
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

            async let fact = CatAPI.fetchFact()
            async let image = CatAPI.fetchCatImage()

            do {
                factLabel.text = try await fact.fact
            } catch {
                factLabel.text = "Couldn't load a fact: \(error.localizedDescription)"
            }

            do {
                imageView.image = try await image
            } catch {
                imageView.image = UIImage(systemName: "exclamationmark.triangle")
                print("Failed to load cat photo: \(error)")
            }
        }
    }
}

#Preview {
    CatViewController()
}
