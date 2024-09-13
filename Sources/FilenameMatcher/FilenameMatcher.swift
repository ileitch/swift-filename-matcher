import Foundation

/// A Unix filename pattern matcher.
public struct FilenameMatcher {
    private let regex: NSRegularExpression

    public init(pattern: String, caseSensitive: Bool = false) {
        // \A is necessary to match the behavior or Python's re.match, which is what fnmatch uses
        // internally.
        regex = try! NSRegularExpression(
            pattern: "\\A\(Self.translate(pattern))",
            options: caseSensitive ? [] : .caseInsensitive
        )
    }

    /// Match the given filename, returns true if the filename matches the pattern.
    public func match(filename: String) -> Bool {
        let range = NSMakeRange(0, filename.count)
        return regex.numberOfMatches(in: filename, range: range) > 0
    }

    /// Translate the given pattern into a regular expression.
    public static func translate(_ pattern: String) -> String {
        var result: [ResultPart] = []
        var patternIndexInt = 0

        while patternIndexInt < pattern.count {
            var patternIndex = pattern.index(pattern.startIndex, offsetBy: patternIndexInt)
            let char = pattern[patternIndex]
            patternIndexInt += 1
            patternIndex = pattern.index(after: patternIndex)

            if char == "*" {
                // compress consecutive `*` into one
                if result.isEmpty || result.last != .star {
                    result.append(.star)
                }
            } else if char == "?" {
                result.append(.fixed("."))
            } else if char == "[" {
                var j = patternIndex

                if j < pattern.endIndex, pattern[j] == "!" {
                    j = pattern.index(after: j)
                }

                if j < pattern.endIndex, pattern[j] == "]" {
                    j = pattern.index(after: j)
                }

                while j < pattern.endIndex, pattern[j] != "]" {
                    j = pattern.index(after: j)
                }

                if j >= pattern.endIndex {
                    result.append(.fixed("\\["))
                } else {
                    var stuff = String(pattern[patternIndex ..< j])

                    if !stuff.contains("-") {
                        stuff = stuff.replacingOccurrences(of: "\\", with: #"\\"#)
                    } else {
                        var chunks: [String] = []
                        var k = pattern[patternIndex] == "!" ? pattern.index(patternIndex, offsetBy: 2) : pattern.index(after: patternIndex)

                        while k <= j, k != pattern.endIndex {
                            guard let hyphenIndex = pattern[k ..< j].firstIndex(of: "-") else { break }

                            chunks.append(String(pattern[patternIndex ..< hyphenIndex]))
                            patternIndex = pattern.index(after: hyphenIndex)
                            patternIndexInt = patternIndex.utf16Offset(in: pattern)
                            k = pattern.index(hyphenIndex, offsetBy: 3, limitedBy: pattern.endIndex) ?? pattern.endIndex
                        }

                        let chunk = pattern[patternIndex ..< j]

                        if !chunk.isEmpty {
                            chunks.append(String(chunk))
                        } else if let last = chunks.popLast() {
                            chunks.append("\(last)-")
                        }

                        // Remove empty ranges -- invalid in RE.
                        for k in stride(from: chunks.count - 1, to: 0, by: -1) {
                            if let nextLast = chunks[k - 1].last,
                               let currentFirst = chunks[k].first,
                               nextLast > currentFirst
                            {
                                let prevChunk = chunks[k - 1]
                                let currentChunk = chunks[k]
                                chunks[k - 1] = String(prevChunk.dropLast(1)) + String(currentChunk.dropFirst())
                                chunks.remove(at: k)
                            }
                        }

                        // Escape backslashes and hyphens for set difference (--).
                        // Hyphens that create ranges shouldn't be escaped.
                        stuff = chunks
                            .map { $0.replacingOccurrences(of: "\\", with: #"\\"#).replacingOccurrences(of: "-", with: #"\-"#) }
                            .joined(separator: "-")
                    }

                    // Escape set operations (&&, ~~ and ||).
                    let expr = try! NSRegularExpression(pattern: #"([&~|])"#)
                    let range = NSMakeRange(0, stuff.count)
                    stuff = expr.stringByReplacingMatches(in: stuff, range: range, withTemplate: #"\\\1"#)
                    patternIndex = pattern.index(after: j)
                    patternIndexInt = patternIndex.utf16Offset(in: pattern)

                    if stuff.isEmpty {
                        // Empty range: never match.
                        result.append(.fixed("(?!)"))
                    } else if stuff == "!" {
                        // Negated empty range: match any character.
                        result.append(.fixed("."))
                    } else {
                        if stuff.first == "!" {
                            stuff = "^" + stuff.dropFirst()
                        } else if stuff.first == "^" || stuff.first == "[" {
                            stuff = "\\" + stuff
                        }
                        result.append(.fixed("[\(stuff)]"))
                    }
                }
            } else {
                result.append(.fixed(NSRegularExpression.escapedPattern(for: String(char))))
            }
        }

        assert(patternIndexInt == pattern.count)

        var resultRegex = result
          .map {
              switch $0 {
                  case .fixed(let value):
                  return value
              case .star:
                  return ".*"
              }
          }
          .joined()

        let duplicatesRemoval: [String] = [
            /// Replace consecutive `/.*/.*` with one `/.*`.
            #"\/.*"#
        ]

        for duplicate in duplicatesRemoval {
            while resultRegex.contains(duplicate + duplicate) {
                resultRegex = resultRegex.replacingOccurrences(of: duplicate + duplicate, with: duplicate)
            }
        }

        let regexReplacements: [(from: String, to: String)] = [
            /// Replace  `/.*/` with optional folder `/(.*/)?` so nested folders become optional.
            (from: #"\/.*\/"#, to: #"\/(.*\/)?"#)
        ]

        for (from, to) in regexReplacements {
            while resultRegex.contains(from) {
                resultRegex = resultRegex.replacingOccurrences(of: from, with: to)
            }
        }

        return #"(?s:\#(resultRegex))\Z"#
    }
}

private enum ResultPart: Equatable {
    case star
    case fixed(String)

    var value: String {
        switch self {
        case .star:
            return "*"
        case let .fixed(value):
            return value
        }
    }
}

public extension Collection<FilenameMatcher> {
    func anyMatch(filename: String) -> Bool {
        contains { $0.match(filename: filename) }
    }
}
