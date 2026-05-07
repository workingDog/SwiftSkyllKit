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

    public init(name: String? = nil, path: String? = nil, content: String? = nil) {
        self.name = name
        self.path = path
        self.content = content
    }
}

public struct SkyllHealthResponse: Codable, Hashable, Sendable {
    public let status: String
}

