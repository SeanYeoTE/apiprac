//
//  CatAPI.swift
//  catfact
//

import UIKit

struct CatFact: Codable {
    let fact: String
    let length: Int
}

enum CatAPIError: Error {
    case badStatus(Int)
    case invalidImageData
}

enum CatAPI {
    private static let factURL = URL(string: "https://catfact.ninja/fact")!
    private static let catImageURL = URL(string: "https://cataas.com/cat")!

    static func fetchFact() async throws -> CatFact {
        let (data, response) = try await URLSession.shared.data(from: factURL)
        try validate(response)
        return try JSONDecoder().decode(CatFact.self, from: data)
    }

    static func fetchCatImage() async throws -> UIImage {
        var request = URLRequest(url: catImageURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)

        guard let image = UIImage(data: data) else {
            throw CatAPIError.invalidImageData
        }
        return image
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw CatAPIError.badStatus(http.statusCode)
        }
    }
}



