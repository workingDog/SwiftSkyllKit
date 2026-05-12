//
//  SkyllEndpoint.swift
//  SwiftSkyllKit
//
//  Created by Ringo Wathelet on 2026/05/07.
//
import Foundation


public enum SkyllEndpoint: Sendable {
    case search(
        query: String,
        limit: Int = 10,
        includeContent: Bool = true,
        includeRaw: Bool = false,
        includeReferences: Bool = false
    )
    case skillByName(
        String,
        includeRaw: Bool = false,
        includeReferences: Bool = false
    )
    case skill(
        source: String,
        id: String,
        includeRaw: Bool = false,
        includeReferences: Bool = false
    )
    case health

    func makeRequest(configuration: SkyllConfiguration) throws -> URLRequest {
        let url: URL

        switch self {
        case let .search(query, limit, includeContent, includeRaw, includeReferences):
            guard var components = URLComponents(
                url: configuration.baseURL.appending(path: "/search"),
                resolvingAgainstBaseURL: false
            ) else {
                throw SkyllError.invalidURL
            }

            components.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "include_content", value: includeContent ? "true" : "false"),
                URLQueryItem(name: "include_raw", value: includeRaw ? "true" : "false"),
                URLQueryItem(name: "include_references", value: includeReferences ? "true" : "false")
            ]

            guard let builtURL = components.url else {
                throw SkyllError.invalidURL
            }
            url = builtURL

        case let .skillByName(name, includeRaw, includeReferences):
            guard var components = URLComponents(
                url: configuration.baseURL.appending(path: "/skill/\(name)"),
                resolvingAgainstBaseURL: false
            ) else {
                throw SkyllError.invalidURL
            }

            components.queryItems = [
                URLQueryItem(name: "include_raw", value: includeRaw ? "true" : "false"),
                URLQueryItem(name: "include_references", value: includeReferences ? "true" : "false")
            ]

            guard let builtURL = components.url else {
                throw SkyllError.invalidURL
            }
            url = builtURL

        case let .skill(source, id, includeRaw, includeReferences):
            let encodedSource = source.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? source
            let encodedID = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
            guard var components = URLComponents(
                url: configuration.baseURL.appending(path: "/skills/\(encodedSource)/\(encodedID)"),
                resolvingAgainstBaseURL: false
            ) else {
                throw SkyllError.invalidURL
            }

            components.queryItems = [
                URLQueryItem(name: "include_raw", value: includeRaw ? "true" : "false"),
                URLQueryItem(name: "include_references", value: includeReferences ? "true" : "false")
            ]

            guard let builtURL = components.url else {
                throw SkyllError.invalidURL
            }
            url = builtURL

        case .health:
            url = configuration.baseURL.appending(path: "/health")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        for (key, value) in configuration.additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

