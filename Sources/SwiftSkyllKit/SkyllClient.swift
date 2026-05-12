//
//  SkyllClient.swift
//  SwiftSkyllKit
//
//  Created by Ringo Wathelet on 2026/05/07.
//
import Foundation


public struct SkyllClient: Sendable {
    private let configuration: SkyllConfiguration
    private let transport: any SkyllTransport
    
    private let decoder: JSONDecoder = JSONDecoder()
    private let encoder: JSONEncoder = JSONEncoder()

    public init(
        configuration: SkyllConfiguration = SkyllConfiguration(),
        transport: any SkyllTransport = URLSessionTransport()
    ) {
        self.configuration = configuration
        self.transport = transport
    }

    // MARK: - Search

    public func searchSkills(
        query: String,
        limit: Int = 10,
        includeContent: Bool = true,
        includeRaw: Bool = false,
        includeReferences: Bool = false
    ) async throws -> [SkyllSkill] {
        let response: SkyllSearchResponse = try await perform(
            .search(
                query: query,
                limit: limit,
                includeContent: includeContent,
                includeRaw: includeRaw,
                includeReferences: includeReferences
            )
        )
        return response.skills
    }

    public func searchSkills(
        query: String,
        options: SkyllSearchOptions = .init()
    ) async throws -> [SkyllSkill] {
        try await searchSkills(
            query: query,
            limit: options.limit,
            includeContent: options.includeContent,
            includeRaw: options.includeRaw,
            includeReferences: options.includeReferences
        )
    }

    public func search(
        query: String,
        limit: Int = 10,
        includeContent: Bool = true,
        includeRaw: Bool = false,
        includeReferences: Bool = false
    ) async throws -> SkyllSearchResponse {
        try await perform(
            .search(
                query: query,
                limit: limit,
                includeContent: includeContent,
                includeRaw: includeRaw,
                includeReferences: includeReferences
            )
        )
    }

    public func search(
        query: String,
        options: SkyllSearchOptions = .init()
    ) async throws -> SkyllSearchResponse {
        try await search(
            query: query,
            limit: options.limit,
            includeContent: options.includeContent,
            includeRaw: options.includeRaw,
            includeReferences: options.includeReferences
        )
    }

    public func search(request: SkyllSearchRequest) async throws -> SkyllSearchResponse {
        try await postJSON(body: request, as: SkyllSearchResponse.self)
    }

    public func searchSkills(request: SkyllSearchRequest) async throws -> [SkyllSkill] {
        let response = try await search(request: request)
        return response.skills
    }

    // MARK: - Skill Fetching

    public func getSkill(
        named name: String,
        includeRaw: Bool = false,
        includeReferences: Bool = false
    ) async throws -> SkyllSkill {
        try await perform(
            .skillByName(
                name,
                includeRaw: includeRaw,
                includeReferences: includeReferences
            )
        )
    }

    public func getSkill(
        source: String,
        id: String,
        includeRaw: Bool = false,
        includeReferences: Bool = false
    ) async throws -> SkyllSkill {
        try await perform(
            .skill(
                source: source,
                id: id,
                includeRaw: includeRaw,
                includeReferences: includeReferences
            )
        )
    }

    public func health() async throws -> SkyllHealthResponse {
        try await perform(.health)
    }

    // MARK: - Raw / GitHub Markdown Fetching

    public func fetchSkillFromRaw(for rawString: String) async throws -> String {
        guard let rawURL = URL(string: rawString) else {
            throw SkyllError.invalidURL
        }

        let request = URLRequest(url: rawURL)
        let data = try await performData(request)

        guard let markdown = String(data: data, encoding: .utf8) else {
            throw SkyllError.decodingFailed(URLError(.cannotDecodeContentData))
        }

        return markdown
    }

    public func fetchSkillFromGithub(for githubString: String) async throws -> String {
        guard let githubURL = URL(string: githubString) else {
            throw SkyllError.invalidURL
        }

        guard let markdownURL = githubSkillMarkdownURL(from: githubURL) else {
            throw SkyllError.invalidURL
        }

        let request = URLRequest(url: markdownURL)
        let data = try await performData(request)

        guard let markdown = String(data: data, encoding: .utf8) else {
            throw SkyllError.decodingFailed(URLError(.cannotDecodeContentData))
        }

        return markdown
    }

    // MARK: - POST Helpers

    // Use only when you already have a valid JSON object string.
    public func postSearch(jsonString: String) async throws -> Data {
        var request = URLRequest(url: configuration.baseURL.appending(path: "search"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(jsonString.utf8)

        return try await performData(request)
    }

    /*
     let response: SkyllSearchResponse = try await client.postJSON(
         body: SkyllSearchBody(query: "react performance", limit: 5),
         as: SkyllSearchResponse.self
     )
     */
    public func postJSON<Request: Encodable, Response: Decodable>(
        body: Request,
        as type: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: configuration.baseURL.appending(path: "search"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        return try await perform(request)
    }

    // MARK: - Core Request Helpers

    private func perform<T: Decodable>(_ endpoint: SkyllEndpoint) async throws -> T {
        let request = try endpoint.makeRequest(configuration: configuration)
        return try await perform(request)
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data = try await performData(request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SkyllError.decodingFailed(error)
        }
    }

    private func performData(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await transport.send(request)

        guard 200..<300 ~= response.statusCode else {
            if let apiError = try? decoder.decode(SkyllErrorResponse.self, from: data) {
                throw SkyllError.serverError(
                    statusCode: response.statusCode,
                    response: apiError
                )
            }

            let body = String(data: data, encoding: .utf8)
            throw SkyllError.requestFailed(statusCode: response.statusCode, body: body)
        }

        return data
    }

    private func githubSkillMarkdownURL(from githubURL: URL) -> URL? {
        guard githubURL.host == "github.com" else { return nil }

        let components = githubURL.pathComponents
        guard components.count >= 6, components[3] == "tree" else { return nil }

        let owner = components[1]
        let repo = components[2]
        let branch = components[4]
        let path = components.dropFirst(5).joined(separator: "/")

        return URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/\(path)/SKILL.md")
    }
}
