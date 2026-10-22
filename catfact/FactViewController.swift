//
//  FactViewController.swift
//  catfact
//

import UIKit

class FactViewController: UIViewController {

    private let factLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap the button for a cat fact 🐱"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title3)
        return label
    }()

    private let fetchButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "New Cat Fact"
        return UIButton(configuration: config)
    }()

    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        fetchButton.addTarget(self, action: #selector(didTapFetch), for: .touchUpInside)
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [factLabel, spinner, fetchButton])
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    @objc private func didTapFetch() {
        spinner.startAnimating()
        fetchButton.isEnabled = false

        Task {
            defer {
                spinner.stopAnimating()
                fetchButton.isEnabled = true
            }

            do {
                let catFact = try await CatAPI.fetchFact()
                factLabel.text = catFact.fact
            } catch {
                factLabel.text = "Couldn't load a fact: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    FactViewController()
}
