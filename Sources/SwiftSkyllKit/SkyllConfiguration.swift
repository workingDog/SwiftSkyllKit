//
//  SkyllConfiguration.swift
//  SwiftSkyllKit
//
//  Created by Ringo Wathelet on 2026/05/07.
//
import Foundation


public struct SkyllConfiguration: Sendable {
    public var baseURL: URL
    public var additionalHeaders: [String: String]

    public init(
        baseURL: URL = URL(string: "https://api.skyll.app")!,
        additionalHeaders: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.additionalHeaders = additionalHeaders
    }
}

