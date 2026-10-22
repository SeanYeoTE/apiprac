//
//  UsersAPI.swift
//  catfact
//

import Foundation

struct SimplifiedUser: Decodable {
    let id: Int
    let fullName: String
    let email: String
    let age: Int
    let gender: String
    let profileImage: String
    let city: String
    let state: String

    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case email
        case age
        case gender
        case profileImage = "image"
        case address
    }

    enum AddressCodingKeys: String, CodingKey {
        case city
        case state
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)

        let firstName = try container.decode(String.self, forKey: .firstName)
        let lastName = try container.decode(String.self, forKey: .lastName)
        self.fullName = "\(firstName) \(lastName)"

        self.email = try container.decode(String.self, forKey: .email)
        self.age = try container.decode(Int.self, forKey: .age)
        self.gender = try container.decode(String.self, forKey: .gender)
        self.profileImage = try container.decode(String.self, forKey: .profileImage)

        let addressContainer = try container.nestedContainer(
            keyedBy: AddressCodingKeys.self,
            forKey: .address
        )
        self.city = try addressContainer.decode(String.self, forKey: .city)
        self.state = try addressContainer.decode(String.self, forKey: .state)
    }

    // 100k-faces hosts 000001.jpg ... 009999.jpg, grouped 1000 per folder: 0/7/007376.jpg
    var faceURL: URL {
        let faceNumber = (id - 1) % 9999 + 1
        let fileName = String(format: "%06d", faceNumber)
        return URL(string: "https://ozgrozer.github.io/100k-faces/0/\(faceNumber / 1000)/\(fileName).jpg")!
    }
}

enum UsersAPIError: Error {
    case badStatus(Int)
}

struct UsersPage {
    let users: [SimplifiedUser]
    let total: Int
}

enum UsersAPI {
    static let pageSize = 10

    static func fetchUsers(matching query: String = "", skip: Int = 0) async throws -> UsersPage {
        let (data, response) = try await URLSession.shared.data(from: usersURL(query: query, skip: skip))
        try validate(response)

        struct Response: Decodable {
            let users: [SimplifiedUser]
            let total: Int
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return UsersPage(users: decoded.users, total: decoded.total)
    }

    private static func usersURL(query: String, skip: Int) -> URL {
        let path = query.isEmpty ? "users" : "users/search"
        var components = URLComponents(string: "https://dummyjson.com/\(path)")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(pageSize)),
            URLQueryItem(name: "skip", value: String(skip))
        ]
        if !query.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "q", value: query))
        }
        return components.url!
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw UsersAPIError.badStatus(http.statusCode)
        }
    }
}
