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
    let profileImage: String
    let city: String
    let state: String

    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case email
        case age
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

enum UsersAPI {
    private static let usersURL = URL(string: "https://dummyjson.com/users?limit=10")!

    static func fetchUsers() async throws -> [SimplifiedUser] {
        let (data, response) = try await URLSession.shared.data(from: usersURL)
        try validate(response)

        struct Response: Decodable {
            let users: [SimplifiedUser]
        }
        return try JSONDecoder().decode(Response.self, from: data).users
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw UsersAPIError.badStatus(http.statusCode)
        }
    }
}
