//
//  UserCell.swift
//  catfact
//

import UIKit

class UserCell: UITableViewCell {

    static let reuseIdentifier = "UserCell"

    private var imageTask: Task<Void, Never>?

    private let avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.backgroundColor = .secondarySystemBackground
        imageView.tintColor = .tertiaryLabel
        imageView.image = UIImage(systemName: "person.crop.circle")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        let textStack = UIStackView(arrangedSubviews: [nameLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarView)
        contentView.addSubview(textStack)

        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),
            avatarView.topAnchor.constraint(greaterThanOrEqualTo: margins.topAnchor),
            avatarView.bottomAnchor.constraint(lessThanOrEqualTo: margins.bottomAnchor),

            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: margins.topAnchor),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: margins.bottomAnchor),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        avatarView.image = UIImage(systemName: "person.crop.circle")
    }

    func configure(with user: SimplifiedUser) {
        nameLabel.text = user.fullName
        detailLabel.text = "\(user.email)\nAge \(user.age) · \(user.city), \(user.state)"

        if let cached = ImageLoader.cachedImage(for: user.faceURL) {
            avatarView.image = cached
            return
        }

        imageTask = Task {
            do {
                let image = try await ImageLoader.image(for: user.faceURL)
                guard !Task.isCancelled else { return }
                avatarView.image = image
            } catch {
                guard !Task.isCancelled else { return }
                avatarView.image = UIImage(systemName: "exclamationmark.triangle")
                print("Failed to load face for \(user.fullName): \(error)")
            }
        }
    }
}
