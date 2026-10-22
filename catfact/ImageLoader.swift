//
//  ImageLoader.swift
//  catfact
//

import UIKit

enum ImageLoaderError: Error {
    case badStatus(Int)
    case invalidImageData
}

enum ImageLoader {
    private static let cache = NSCache<NSURL, UIImage>()

    static func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    static func image(for url: URL) async throws -> UIImage {
        if let cached = cachedImage(for: url) {
            return cached
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ImageLoaderError.badStatus(http.statusCode)
        }
        guard let image = UIImage(data: data) else {
            throw ImageLoaderError.invalidImageData
        }

        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
