# swift-filename-matcher

A Swift port of Python's `fnmatch` module.

```swift
let matcher = FilenameMatcher(pattern: "**/*.swift")
matcher.match(filename: "path/to/File.swift")
```
