//
//  SkyllSearchOptions.swift
//  SwiftSkyllKit
//
//  Created by Ringo Wathelet on 2026/05/07.
//
import Foundation


public struct SkyllSearchOptions: Sendable {
    public var limit: Int
    public var includeContent: Bool
    public var includeReferences: Bool
    public var includeRaw: Bool

    public init(limit: Int = 10, includeContent: Bool = true, includeReferences: Bool = false, includeRaw: Bool = false) {
        self.limit = limit
        self.includeContent = includeContent
        self.includeReferences = includeReferences
        self.includeRaw = includeRaw
    }
}

