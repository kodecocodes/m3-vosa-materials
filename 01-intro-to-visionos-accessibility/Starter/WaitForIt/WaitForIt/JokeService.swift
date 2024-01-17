/// Copyright (c) 2024 Kodeco LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

private actor JokeServiceStore {
  private var loadedJoke = Joke(value: "")
  private var url: URL {
    urlComponents.url!
  }

  private var urlComponents: URLComponents {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "api.chucknorris.io"
    components.path = "/jokes/random"
    components.setQueryItems(with: ["category": "dev"])
    return components
  }

  func load() async throws -> Joke {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200
    else { throw DownloadError.statusNotOk }
    guard let decodedResponse = try? JSONDecoder().decode(
      Joke.self, from: data)
    else { throw DownloadError.decoderError }
    loadedJoke = decodedResponse
    // Joke(value: decodedResponse.value)
    return loadedJoke
  }
}

class JokeService: ObservableObject {
  @Published private(set) var joke = "Joke appears here"
  @Published private(set) var isFetching = false
  private let store = JokeServiceStore()

  public init() { }
}

enum DownloadError: Error {
  case statusNotOk
  case decoderError
}

extension JokeService {
  @MainActor
  func fetchJoke() async throws {
    isFetching = true
    defer { isFetching = false }

    let loadedJoke = try await store.load()
    joke = loadedJoke.value
  }
}

struct Joke: Codable {
  let value: String
}

public extension URLComponents {
  /// Maps a dictionary into `[URLQueryItem]` then assigns it to the
  /// `queryItems` property of this `URLComponents` instance.
  /// From [Alfian Losari's blog.](https://www.alfianlosari.com/posts/building-safe-url-in-swift-using-urlcomponents-and-urlqueryitem/)
  /// - Parameter parameters: Dictionary of query parameter names and values
  mutating func setQueryItems(with parameters: [String: String]) {
    self.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
  }
}
