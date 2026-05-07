//
//  URLSessionTransport.swift
//  SwiftSkyllKit
//
//  Created by Ringo Wathelet on 2026/05/07.
//
import Foundation


public struct URLSessionTransport: SkyllTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SkyllError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8)
            throw SkyllError.requestFailed(statusCode: httpResponse.statusCode, body: body)
        }

        return (data, httpResponse)
    }
}

