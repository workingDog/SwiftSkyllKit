//
//  SkyllModels.swift
//  SwiftSkyllKit
//
//  Created by Ringo Wathelet on 2026/05/07.
//
import Foundation


public struct SkyllErrorResponse: Codable, Sendable {
    public let error: String
    public let message: String
    public let detail: String?
}

public struct SkyllSearchResponse: Codable, Sendable {
    public let query: String
    public let count: Int
    public let skills: [SkyllSkill]
}

public struct SkyllSearchRequest: Codable, Sendable {
    public let query: String
    public let limit: Int
    public let includeContent: Bool
    public let includeRaw: Bool
    public let includeReferences: Bool

    public init(
        query: String,
        limit: Int = 10,
        includeContent: Bool = true,
        includeRaw: Bool = false,
        includeReferences: Bool = false
    ) {
        self.query = query
        self.limit = limit
        self.includeContent = includeContent
        self.includeRaw = includeRaw
        self.includeReferences = includeReferences
    }

    enum CodingKeys: String, CodingKey {
        case query, limit
        case includeContent = "include_content"
        case includeRaw = "include_raw"
        case includeReferences = "include_references"
    }
}

public struct SkyllSkill: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let source: String
    public let version: String?
    public let allowedTools: [String]?
    public let refs: SkyllRefs?
    public let installCount: Int?
    public let relevanceScore: Double?
    public let content: String?
    public let rawContent: String?
    public let metadata: SkyllSkillMetadata?
    public let references: [SkyllReference]
    public let fetchError: String?

    public enum CodingKeys: String, CodingKey {
        case id, title, description, version, source
        case refs, metadata, references, content
        case allowedTools = "allowed_tools"
        case installCount = "install_count"
        case relevanceScore = "relevance_score"
        case rawContent = "raw_content"
        case fetchError = "fetch_error"
    }
}

public struct SkyllSkillMetadata: Codable, Hashable, Sendable {
    public let license: String?
    public let metadata: SkyllInnerMetadata?
}

public struct SkyllInnerMetadata: Codable, Hashable, Sendable {
    public let author: String?
    public let version: String?
}

public struct SkyllRefs: Codable, Hashable, Sendable {
    public let skillsSh: String?
    public let github: String?
    public let raw: String?

    public enum CodingKeys: String, CodingKey {
        case skillsSh = "skills_sh"
        case github, raw
    }
}

public struct SkyllReference: Codable, Hashable, Sendable {
    public let name: String?
    public let path: String?
    public let content: String?
    public let rawURL: String?

    public init(name: String? = nil, path: String? = nil, content: String? = nil, rawURL: String? = nil) {
        self.name = name
        self.path = path
        self.content = content
        self.rawURL = rawURL
    }
    
    enum CodingKeys: String, CodingKey {
        case name, path, content
        case rawURL = "raw_url"
    }
}

public struct SkyllHealthResponse: Codable, Hashable, Sendable {
    public let status: String
    public let version: String?
    public let cacheStats: [String: Int]?

    public enum CodingKeys: String, CodingKey {
        case status, version
        case cacheStats = "cache_stats"
    }
}

