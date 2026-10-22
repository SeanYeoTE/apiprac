//
//  UserDetailViewController.swift
//  catfact
//

import UIKit

class UserDetailViewController: UIViewController {

    private let user: SimplifiedUser

    private let avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 100
        imageView.backgroundColor = .secondarySystemBackground
        imageView.tintColor = .tertiaryLabel
        imageView.image = UIImage(systemName: "person.crop.circle")
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    init(user: SimplifiedUser) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = user.fullName
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground

        nameLabel.text = user.fullName
        detailLabel.text = """
        \(user.email)
        Age \(user.age)
        \(user.city), \(user.state)
        """

        setupLayout()
        loadAvatar()
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [avatarView, nameLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.setCustomSpacing(24, after: avatarView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        view.addSubview(spinner)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24),

            avatarView.widthAnchor.constraint(equalToConstant: 200),
            avatarView.heightAnchor.constraint(equalToConstant: 200),

            spinner.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])
    }

    private func loadAvatar() {
        if let cached = ImageLoader.cachedImage(for: user.faceURL) {
            avatarView.image = cached
            return
        }

        spinner.startAnimating()

        Task {
            defer { spinner.stopAnimating() }

            do {
                avatarView.image = try await ImageLoader.image(for: user.faceURL)
            } catch {
                avatarView.image = UIImage(systemName: "exclamationmark.triangle")
                print("Failed to load face for \(user.fullName): \(error)")
            }
        }
    }
}
