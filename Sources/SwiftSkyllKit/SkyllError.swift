//
//  SkyllError.swift
//  SwiftSkyllKit
//
//  Created by Ringo Wathelet on 2026/05/07.
//
import Foundation


public enum SkyllError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, response: SkyllErrorResponse)
    case requestFailed(statusCode: Int, body: String?)
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."

        case .invalidResponse:
            return "Invalid HTTP response."

        case let .serverError(statusCode, response):
            if let detail = response.detail, !detail.isEmpty {
                return "Skyll error \(statusCode): \(response.message) (\(detail))"
            } else {
                return "Skyll error \(statusCode): \(response.message)"
            }

        case let .requestFailed(statusCode, body):
            return "Request failed with status \(statusCode). \(body ?? "")"

        case let .decodingFailed(error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
