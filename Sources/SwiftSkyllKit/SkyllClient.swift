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
    private let decoder: JSONDecoder

    public init(
        configuration: SkyllConfiguration = SkyllConfiguration(),
        transport: any SkyllTransport = URLSessionTransport(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.configuration = configuration
        self.transport = transport
        self.decoder = decoder
    }

    // returns [SkyllSkill]
    public func searchSkills(
        query: String,
        limit: Int = 10,
        includeContent: Bool = true,
        includeReferences: Bool = false
    ) async throws -> [SkyllSkill] {
        let response: SkyllSearchResponse = try await perform(
            .search(
                query: query,
                limit: limit,
                includeContent: includeContent,
                includeReferences: includeReferences
            )
        )
        return response.skills
    }
    
    // returns [SkyllSkill]
    public func searchSkills(query: String, options: SkyllSearchOptions = .init()) async throws -> [SkyllSkill] {
        try await search(query: query, options: options).skills
    }

    // returns SkyllSearchResponse
    public func search(
        query: String,
        limit: Int = 10,
        includeContent: Bool = true,
        includeReferences: Bool = false
    ) async throws -> SkyllSearchResponse {
        try await perform(
            .search(
                query: query,
                limit: limit,
                includeContent: includeContent,
                includeReferences: includeReferences
            )
        )
    }
    
    // returns SkyllSearchResponse
    public func search(query: String, options: SkyllSearchOptions = .init()) async throws -> SkyllSearchResponse {
        try await perform(
            .search(
                query: query,
                limit: options.limit,
                includeContent: options.includeContent,
                includeReferences: options.includeReferences
            )
        )
    }

    public func getSkill(named name: String) async throws -> SkyllSkill {
        try await perform(.skillByName(name))
    }

    public func getSkill(source: String, id: String) async throws -> SkyllSkill {
        try await perform(.skill(source: source, id: id))
    }

    public func health() async throws -> SkyllHealthResponse {
        try await perform(.health)
    }

    private func perform<T: Decodable>(_ endpoint: SkyllEndpoint) async throws -> T {
        let request = try endpoint.makeRequest(configuration: configuration)
        
        let (data, response) = try await transport.send(request)

        let httpResponse = response

        guard 200..<300 ~= httpResponse.statusCode else {
            if let apiError = try? JSONDecoder().decode(SkyllErrorResponse.self, from: data) {
                throw SkyllError.serverError(
                    statusCode: httpResponse.statusCode,
                    response: apiError
                )
            }
            let body = String(data: data, encoding: .utf8)
            throw SkyllError.requestFailed(statusCode: httpResponse.statusCode, body: body)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print(error)
            throw SkyllError.decodingFailed(error)
        }
    }

    // get the SKILL.md content using the SkyllSkill refs raw string
    public func fetchSkillFromRaw(for rawString: String) async throws -> String? {
        guard let rawURL = URL(string: rawString) else {
            throw SkyllError.invalidURL
        }
        
        let (data, httpResponse) = try await transport.send(URLRequest(url: rawURL))
        
        guard 200..<300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8)
            throw SkyllError.requestFailed(statusCode: httpResponse.statusCode, body: body)
        }
        
        return String(data: data, encoding: .utf8)
    }
 
    // get the SKILL.md content using the SkyllSkill refs github string
    public func fetchSkillFromGithub(for githubString: String) async throws -> String? {
        guard let githubURL = URL(string: githubString) else {
            throw SkyllError.invalidURL
        }
        guard let mkURL = githubSkillMarkdownURL(from: githubURL) else {
            throw SkyllError.invalidURL
        }

        let (data, httpResponse) = try await transport.send(URLRequest(url: mkURL))
   
        guard 200..<300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8)
            throw SkyllError.requestFailed(statusCode: httpResponse.statusCode, body: body)
        }
        return String(data: data, encoding: .utf8)
    }

    // private
    private func githubSkillMarkdownURL(from githubURL: URL?) -> URL? {
        guard let githubURL, githubURL.host == "github.com" else { return nil }

        let components = githubURL.pathComponents
        guard components.count >= 6, components[3] == "tree" else { return nil }

        let owner = components[1]
        let repo = components[2]
        let branch = components[4]
        let path = components.dropFirst(5).joined(separator: "/")

        return URL(string: "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/\(path)/SKILL.md")
    }

}
