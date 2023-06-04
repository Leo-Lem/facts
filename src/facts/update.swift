// Created by Leopold Lemmermann on 04.06.23.

import struct Dependencies.Dependency
import Foundation

extension Facts {
  func updateTask() -> Task<Void, Never> {
    Task {
      while true {
        @Dependency(\.continuousClock) var clock

        do {
          try await updateExpired()
          try await initialize()
        } catch { print(error) }

        try? await clock.sleep(for: .seconds(refreshInterval))
      }
    }
  }

  func initialize() async throws {
    for language in Self.supportedLanguages {
      while facts.filter({ $0.language == language }).count < cacheCount {
        if let fact = try await fetch(in: language) {
          facts.append(fact)
        }
      }
    }
  }

  private func updateExpired() async throws {
    @Dependency(\.date.now) var now
    for (index, fact) in facts.enumerated().filter({ $0.element.expiry < now }) {
      if let fact = try await fetch(in: fact.language) {
        facts[index] = fact
      }
    }
  }

  func fetch(in language: Locale.LanguageCode) async throws -> Fact? {
    @Dependency(\.apiClient) var client
    @Dependency(\.date.now) var now

    return try await client.fetchFact(language)
      .flatMap { Fact(content: $0, expiry: now.addingTimeInterval(expiry), language: language) }
  }
}
