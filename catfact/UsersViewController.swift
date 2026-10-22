//
//  UsersViewController.swift
//  catfact
//

import UIKit

class UsersViewController: UIViewController {

    private var allUsers: [SimplifiedUser] = []   // what the API returned
    private var users: [SimplifiedUser] = []      // allUsers after the gender filter; what the table shows
    private var searchTask: Task<Void, Never>?
    private var pageTask: Task<Void, Never>?
    private var totalUsers = 0
    private var currentQuery = ""

    private var hasMorePages: Bool { allUsers.count < totalUsers }

    private let genderScopes = ["All", "Female", "Male"]

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.scopeBarActivation = .onSearchActivation
        searchController.searchBar.placeholder = "Search by name"
        searchController.searchBar.scopeButtonTitles = self.genderScopes
        searchController.searchBar.delegate = self
        return searchController
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No users found"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

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

    private let footerSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.frame = CGRect(x: 0, y: 0, width: 0, height: 44)
        return spinner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Face Book"
        view.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = footerSpinner
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
//        definesPresentationContext = true
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

    private func loadUsers(matching query: String = "", debounce: Bool = false) {
        searchTask?.cancel()
        pageTask?.cancel()          // a page from the old search must not be appended to the new one
        pageTask = nil
        currentQuery = query

        searchTask = Task {
            if debounce {
                // Wait for the user to stop typing; a newer keystroke cancels this sleep
                do {
                    try await Task.sleep(for: .milliseconds(400))
                } catch {
                    return
                }
            }

            spinner.startAnimating()
            defer {
                // A cancelled search hands the spinner over to the newer one
                if !Task.isCancelled { spinner.stopAnimating() }
            }

            do {
                let page = try await UsersAPI.fetchUsers(matching: query)
                guard !Task.isCancelled else { return }
                allUsers = page.users     // first page replaces the list
                totalUsers = page.total
                applyGenderFilter()
            } catch DecodingError.keyNotFound(let key, let context) {
                print("❌ Missing key: '\(key.stringValue)' – \(context.debugDescription)")
                showError("Couldn't read the user data.")
            } catch DecodingError.typeMismatch(let type, let context) {
                print("❌ Type mismatch for \(type) – \(context.debugDescription)")
                showError("Couldn't read the user data.")
            } catch {
                guard !Task.isCancelled else { return }
                print("❌ Error: \(error)")
                showError(error.localizedDescription)
            }
        }
    }

    private func loadNextPage() {
        guard pageTask == nil, hasMorePages else { return }

        footerSpinner.startAnimating()

        pageTask = Task {
            defer {
                footerSpinner.stopAnimating()
                pageTask = nil
            }

            do {
                let page = try await UsersAPI.fetchUsers(matching: currentQuery, skip: allUsers.count)
                guard !Task.isCancelled else { return }
                allUsers += page.users    // later pages append
                totalUsers = page.total
                applyGenderFilter()
            } catch {
                guard !Task.isCancelled else { return }
                print("❌ Failed to load more: \(error)")
            }
        }
    }

    private func applyGenderFilter() {
        switch searchController.searchBar.selectedScopeButtonIndex {
        case 1:
            users = allUsers.filter { $0.gender == "female" }
        case 2:
            users = allUsers.filter { $0.gender == "male" }
        default:
            users = allUsers
        }
        tableView.backgroundView = users.isEmpty ? emptyLabel : nil
        tableView.reloadData()
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        // While searching, the search controller is already presented on top of this screen
        (presentedViewController ?? self).present(alert, animated: true)
    }
}

extension UsersViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        loadUsers(matching: query, debounce: !query.isEmpty)
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        applyGenderFilter()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.selectedScopeButtonIndex = 0
        loadUsers()
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !allUsers.isEmpty else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        if offsetY > contentHeight - height * 2 {
            loadNextPage()
        }
    }
}

#Preview {
    UINavigationController(rootViewController: UsersViewController())
}
