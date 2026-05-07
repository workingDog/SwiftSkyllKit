//
//  SkyllClientTests.swift
//  SwiftSkyllKit
//
//  Created by Ringo Wathelet on 2026/05/07.
//
import Testing
@testable import SwiftSkyllKit
import Foundation


struct MockTransport: SkyllTransport {
    var handler: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await handler(request)
    }
}

@Test
func searchDecodesSkills() async throws {
    let json = """
    {
      "query": "testing",
      "count": 1,
      "skills": [
        {
          "id": "react-best-practices",
          "title": "React Best Practices",
          "description": "Guidelines",
          "version": null,
          "allowed_tools": null,
          "source": "vercel/ai-skills",
          "refs": {
            "skills_sh": null,
            "github": "https://github.com/example/repo",
            "raw": null
          },
          "install_count": 10,
          "relevance_score": 88.0,
          "content": "# Skill",
          "raw_content": null,
          "metadata": {
            "license": "MIT",
            "metadata": {
              "author": "me",
              "version": "1.0"
            }
          },
          "references": [],
          "fetch_error": null
        }
      ]
    }
    """

    let transport = MockTransport { request in
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data(json.utf8), response)
    }

    let client = SkyllClient(transport: transport)
    let results = try await client.searchSkills(query: "testing")

    #expect(results.count == 1)
    #expect(results[0].title == "React Best Practices")
}

