public struct FilenameMatcherOptions: OptionSet {
    public var rawValue: UInt

    public init (rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// Enables case sensitive matching.
    public static let caseSensitive = Self(rawValue: 1 << 0)
    /// Enables "globstar" behaviour to match Bash handling of double stars.
    public static let globstar = Self(rawValue: 1 << 1)

    /// The default set of options.
    public static let defaults: Self = [.globstar]
}
