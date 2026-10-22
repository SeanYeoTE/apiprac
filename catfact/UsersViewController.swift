//
//  UsersViewController.swift
//  catfact
//

import UIKit

class UsersViewController: UIViewController {

    private var users: [SimplifiedUser] = []

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UserCell.self, forCellReuseIdentifier: UserCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Face Book"
        view.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.delegate = self
        setupLayout()
        loadUsers()
    }

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadUsers() {
        spinner.startAnimating()

        Task {
            defer { spinner.stopAnimating() }

            do {
                users = try await UsersAPI.fetchUsers()
                tableView.reloadData()
            } catch DecodingError.keyNotFound(let key, let context) {
                print("❌ Missing key: '\(key.stringValue)' – \(context.debugDescription)")
                showError("Couldn't read the user data.")
            } catch DecodingError.typeMismatch(let type, let context) {
                print("❌ Type mismatch for \(type) – \(context.debugDescription)")
                showError("Couldn't read the user data.")
            } catch {
                print("❌ Error: \(error)")
                showError(error.localizedDescription)
            }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension UsersViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.reuseIdentifier, for: indexPath) as! UserCell
        cell.configure(with: users[indexPath.row])
        return cell
    }
}

extension UsersViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = UserDetailViewController(user: users[indexPath.row])
        navigationController?.pushViewController(detail, animated: true)
    }
}

#Preview {
    UINavigationController(rootViewController: UsersViewController())
}
