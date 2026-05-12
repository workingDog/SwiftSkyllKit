#  SwiftSkyllKit

`SwiftSkyllKit` is a lightweight Swift package for searching and retrieving AI agent skills from the [Skyll](https://www.skyll.app/) REST API.

It gives Swift apps typed access to Skyll’s hosted skill discovery service at [Skyll API](https://api.skyll.app), so your app can:

- search for skills by natural-language query
- retrieve the latest version of a skill
- fetch a specific skill by source and ID
- inspect service health
- integrate remote `SKILL.md` content into local agent workflows

## What Skyll Is

[Skyll](https://www.skyll.app/) is a skill discovery platform for AI agents. It aggregates agent skills from multiple sources, ranks them by relevance, and returns the full skill content so agents or tools can use them on demand.

Skyll is useful when your app needs to:

- discover agent capabilities dynamically
- search public skill registries from Swift
- import `SKILL.md` content into an editor, library, or runtime
- retrieve skill metadata such as source, references, and install counts

## SwiftSkyllKit Features

- Native Swift async/await API
- Typed Codable models for Skyll responses
- Support for:
  - `GET /search`
  - `GET /skill/{name}`
  - `GET /skills/{source}/{skill_id}`
  - `GET /health`
  - `POST /search`
- Small API surface suitable for app integration
- Configurable base URL for hosted or self-hosted Skyll servers

If the `SKILL.md` content is not returned in the search results, but GitHub or raw references are available, retrieval from those sources is also supported.  


## Installation

Add the package to your project in Xcode using the package URL, or add it to `Package.swift`:

     .package(url: "https://github.com/workingDog/SwiftSkyllKit.git", from: "0.3.0")

See also [SkyllViewer](https://github.com/workingDog/SkyllViewer) for a basic use of **SwiftSkyllKit**



## License

MIT License - [LICENSE](LICENSE) file for details.
