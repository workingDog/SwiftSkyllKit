//
//  SwiftSkyllKitTests.swift
//  SwiftSkyllKit
//
//  Created by Ringo Wathelet on 2026/05/07.
//
import Testing
@testable import SwiftSkyllKit
import Foundation


private struct MockTransport: SkyllTransport {
    let handler: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await handler(request)
    }
}

private func makeHTTPResponse(
    url: URL,
    statusCode: Int = 200,
    headers: [String: String] = [:]
) -> HTTPURLResponse {
    HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: headers
    )!
}

private let sampleSkillJSON = """
{
  "id": "swiftui-skill",
  "title": "SwiftUI Skill",
  "description": "A SwiftUI helper skill",
  "source": "workingdog/swift-skills",
  "version": "1.0.0",
  "allowed_tools": null,
  "refs": {
    "skills_sh": null,
    "github": "https://github.com/example/repo",
    "raw": "https://raw.githubusercontent.com/example/repo/main/SKILL.md"
  },
  "install_count": 10,
  "relevance_score": 98.5,
  "content": "# SwiftUI Skill",
  "raw_content": null,
  "metadata": {
    "license": "MIT",
    "metadata": {
      "author": "workingdog",
      "version": "1.0.0"
    }
  },
  "references": [],
  "fetch_error": null
}
"""

private let sampleSearchJSON = """
{
  "query": "swiftui",
  "count": 1,
  "skills": [
    \(sampleSkillJSON)
  ]
}
"""

@Test
func searchDecodesFullResponse() async throws {
    let transport = MockTransport { request in
        #expect(request.url?.absoluteString.contains("/search") == true)
        let response = makeHTTPResponse(url: request.url!)
        return (Data(sampleSearchJSON.utf8), response)
    }

    let client = SkyllClient(transport: transport)
    let result = try await client.search(query: "swiftui")

    #expect(result.query == "swiftui")
    #expect(result.count == 1)
    #expect(result.skills.count == 1)
    #expect(result.skills.first?.title == "SwiftUI Skill")
}

@Test
func searchSkillsReturnsOnlySkillsArray() async throws {
    let transport = MockTransport { request in
        let response = makeHTTPResponse(url: request.url!)
        return (Data(sampleSearchJSON.utf8), response)
    }

    let client = SkyllClient(transport: transport)
    let skills = try await client.searchSkills(query: "swiftui")

    #expect(skills.count == 1)
    #expect(skills.first?.id == "swiftui-skill")
}

@Test
func searchOptionsBecomeQueryItems() async throws {
    let transport = MockTransport { request in
        let components = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        func value(_ name: String) -> String? {
            queryItems.first(where: { $0.name == name })?.value
        }

        #expect(value("q") == "swiftdata")
        #expect(value("limit") == "25")
        #expect(value("include_content") == "false")
        #expect(value("include_references") == "true")

        let response = makeHTTPResponse(url: request.url!)
        return (Data(sampleSearchJSON.utf8), response)
    }

    let client = SkyllClient(transport: transport)
    _ = try await client.search(
        query: "swiftdata",
        options: .init(limit: 25, includeContent: false, includeReferences: true)
    )
}

@Test
func getSkillByNameDecodesSkill() async throws {
    let transport = MockTransport { request in
        #expect(request.url?.path.contains("/skill/swiftui-skill") == true)
        let response = makeHTTPResponse(url: request.url!)
        return (Data(sampleSkillJSON.utf8), response)
    }

    let client = SkyllClient(transport: transport)
    let skill = try await client.getSkill(named: "swiftui-skill")

    #expect(skill.title == "SwiftUI Skill")
    #expect(skill.source == "workingdog/swift-skills")
}

@Test
func getSkillBySourceAndIDDecodesSkill() async throws {
    let transport = MockTransport { request in
        #expect(request.url?.path.contains("/skills/workingdog/swift-skills/swiftui-skill") == true)
        let response = makeHTTPResponse(url: request.url!)
        return (Data(sampleSkillJSON.utf8), response)
    }

    let client = SkyllClient(transport: transport)
    let skill = try await client.getSkill(source: "workingdog/swift-skills", id: "swiftui-skill")

    #expect(skill.id == "swiftui-skill")
}

@Test
func healthDecodesResponse() async throws {
    let json = """
    { "status": "ok" }
    """

    let transport = MockTransport { request in
        #expect(request.url?.path.contains("/health") == true)
        let response = makeHTTPResponse(url: request.url!)
        return (Data(json.utf8), response)
    }

    let client = SkyllClient(transport: transport)
    let health = try await client.health()

    #expect(health.status == "ok")
}

@Test
func serverErrorResponseIsDecodedAndThrown() async throws {
    let errorJSON = """
    {
      "error": "BadRequest",
      "message": "Invalid query",
      "detail": "Query parameter q is required"
    }
    """

    let transport = MockTransport { request in
        let response = makeHTTPResponse(url: request.url!, statusCode: 400)
        return (Data(errorJSON.utf8), response)
    }

    let client = SkyllClient(transport: transport)

    await #expect(throws: SkyllError.self) {
        _ = try await client.search(query: "")
    }

    do {
        _ = try await client.search(query: "")
        Issue.record("Expected error was not thrown")
    } catch let error as SkyllError {
        switch error {
        case .serverError(let statusCode, let response):
            #expect(statusCode == 400)
            #expect(response.error == "BadRequest")
            #expect(response.message == "Invalid query")
            #expect(response.detail == "Query parameter q is required")
        default:
            Issue.record("Wrong error type: \(error)")
        }
    }
}

@Test
func nonJSONErrorFallsBackToRequestFailed() async throws {
    let transport = MockTransport { request in
        let response = makeHTTPResponse(url: request.url!, statusCode: 500)
        return (Data("Internal Server Error".utf8), response)
    }

    let client = SkyllClient(transport: transport)

    do {
        _ = try await client.search(query: "swiftui")
        Issue.record("Expected requestFailed was not thrown")
    } catch let error as SkyllError {
        switch error {
        case .requestFailed(let statusCode, let body):
            #expect(statusCode == 500)
            #expect(body == "Internal Server Error")
        default:
            Issue.record("Wrong error type: \(error)")
        }
    }
}

@Test
func malformedSuccessBodyThrowsDecodingFailed() async throws {
    let badJSON = """
    { "query": "swiftui", "count": "not-an-int", "skills": [] }
    """

    let transport = MockTransport { request in
        let response = makeHTTPResponse(url: request.url!, statusCode: 200)
        return (Data(badJSON.utf8), response)
    }

    let client = SkyllClient(transport: transport)

    do {
        _ = try await client.search(query: "swiftui")
        Issue.record("Expected decodingFailed was not thrown")
    } catch let error as SkyllError {
        switch error {
        case .decodingFailed:
            #expect(true)
        default:
            Issue.record("Wrong error type: \(error)")
        }
    }
}

@Test
func optionalAndNullableFieldsDecodeCorrectly() async throws {
    let json = """
    {
      "query": "swiftui",
      "count": 1,
      "skills": [
        {
          "id": "minimal-skill",
          "title": "Minimal Skill",
          "description": null,
          "source": "source/repo",
          "version": null,
          "allowed_tools": null,
          "refs": null,
          "install_count": null,
          "relevance_score": null,
          "content": null,
          "raw_content": null,
          "metadata": null,
          "references": [],
          "fetch_error": null
        }
      ]
    }
    """

    let transport = MockTransport { request in
        let response = makeHTTPResponse(url: request.url!)
        return (Data(json.utf8), response)
    }

    let client = SkyllClient(transport: transport)
    let result = try await client.search(query: "swiftui")

    let skill = try #require(result.skills.first)
    #expect(skill.description == nil)
    #expect(skill.refs == nil)
    #expect(skill.metadata == nil)
    #expect(skill.references.isEmpty)
}

@Test
func pathComponentsAreURLSafeForSourceAndID() async throws {
    let transport = MockTransport { request in
        let url = try #require(request.url)
        #expect(url.absoluteString.contains("skills/") == true)
        let response = makeHTTPResponse(url: url)
        return (Data(sampleSkillJSON.utf8), response)
    }

    let client = SkyllClient(transport: transport)
    _ = try await client.getSkill(source: "owner/repo with spaces", id: "skill name")
}
