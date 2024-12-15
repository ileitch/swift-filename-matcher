# swift-filename-matcher

A Swift port of Python's `fnmatch` module with optional support for Bash 'globstar' behavior (`**`).

## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/ileitch/swift-filename-matcher.git", from: "0.0.0")
```

```swift
.product(name: "FilenameMatcher", package: "swift-filename-matcher")
```

### Bazel

```python
bazel_dep(name = "swift-filename-matcher", version = "<version>")
```

## Usage

```swift
let matcher = FilenameMatcher(
    pattern: "**/*.swift",
    options: [.globstar]
)
matcher.match(filename: "path/to/File.swift") // true
```

To obtain the regex for a given pattern:

```swift
FilenameMatcher.translate("**/File.swift") // (?s:(.*/)?File\.swift)\Z
```

### Options

See [FilenameMatcherOptions](https://github.com/ileitch/swift-filename-matcher/blob/main/Sources/FilenameMatcher/FilenameMatcherOptions.swift) for the options that can be passed to `FilenameMatcher`. Note that 'globstar' support is enabled by default.
