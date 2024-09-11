//
//  APIClient.swift
//  avito-unsplash-test
//
//  Created by Марк Кулик on 07.09.2024.
//

import Foundation

class APIClient {
  
    private let apiKey = "MPgnnsFCvXjjjcO0ljAnNTvtF7VZkcRVjL0lQewVk0Q"
    
    func searchPhotos(query: String, sortBy: String, page: Int, completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        let urlString = "https://api.unsplash.com/search/photos?query=\(query)&order_by=\(sortBy)&page=\(page)&per_page=30&client_id=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }

            do {
                let result = try JSONDecoder().decode(SearchResults.self, from: data)
                completion(.success(result.results))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Fetch detailed information for a specific photo
    func fetchPhotoDetails(id: String, completion: @escaping (Result<MediaContent, Error>) -> Void) {
        let urlString = "https://api.unsplash.com/photos/\(id)?client_id=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let content = try JSONDecoder().decode(MediaContent.self, from: data)
                completion(.success(content))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Private struct for decoding search results
    private struct SearchResults: Decodable {
        let results: [SearchResult]
    }
}
