@testable import FilenameMatcher
import XCTest

final class FilenameMatcherTest: XCTestCase {
    func testMatch() {
        assertMatch("abc", "abc")
        assertMatch("abc", "?*?")
        assertMatch("abc", "???*")
        assertMatch("abc", "*???")
        assertMatch("abc", "???")
        assertMatch("abc", "*")
        assertMatch("abc", "ab[cd]")
        assertMatch("abc", "ab[!de]")
        assertMatch("abc", "ab[de]", false)
        assertMatch("a", "??", false)
        assertMatch("a", "b", false)

        // these test that '\' is handled correctly in character sets.
        assertMatch("\\", #"[\]"#)
        assertMatch("a", #"[!\]"#)
        assertMatch("\\", #"[!\]"#, false)

        // test that filenames with newlines in them are handled correctly.
        assertMatch("foo\nbar", "foo*")
        assertMatch("foo\nbar\n", "foo*")
        assertMatch("\nfoo", "foo*", false)
        assertMatch("\n", "*")
    }

    func testMatchCaseSensitivity() {
        assertMatch("abc", "abc", true, true)
        assertMatch("AbC", "abc", false, true)
        assertMatch("abc", "AbC", false, true)
        assertMatch("AbC", "AbC", true, true)

        assertMatch("abc", "abc", true, false)
        assertMatch("AbC", "abc", true, false)
        assertMatch("abc", "AbC", true, false)
        assertMatch("AbC", "AbC", true, false)
    }

    func testSep() {
        assertMatch("usr/bin", "usr/bin", true, true)
        assertMatch("usr\\bin", "usr/bin", false, true)
        assertMatch("usr/bin", "usr\\bin", false, true)
        assertMatch("usr\\bin", "usr\\bin", true, true)
    }

    func testCharSet() {
        let characters = lowercaseCharacters + decimalCharacters + controlCharacters

        for c in characters {
            assertMatch(c, "[az]", "az".contains(c))
            assertMatch(c, "[!az]", !"az".contains(c))
        }

        // Case insensitive.
        for c in characters {
            assertMatch(c, "[AZ]", "az".contains(c), false)
            assertMatch(c, "[!AZ]", !"az".contains(c), false)
        }

        for c in uppercaseCharacters {
            assertMatch(c, "[az]", "AZ".contains(c), false)
            assertMatch(c, "[!az]", !"AZ".contains(c), false)
        }

        // Repeated same character.
        for c in characters {
            assertMatch(c, "[aa]", c == "a")
        }

        // Special cases.
        for c in characters {
            assertMatch(c, "[^az]", "^az".contains(c))
            assertMatch(c, "[[az]", "[az".contains(c))
            assertMatch(c, #"[!]]"#, c != "]")
        }

        assertMatch("[", "[")
        assertMatch("[]", "[]")
        assertMatch("[!", "[!")
        assertMatch("[!]", "[!]")
    }

    func testRange() {
        let characters = lowercaseCharacters + decimalCharacters + controlCharacters

        for c in characters {
            assertMatch(c, "[b-d]", "bcd".contains(c))
            assertMatch(c, "[!b-d]", !"bcd".contains(c))
            assertMatch(c, "[b-dx-z]", "bcdxyz".contains(c))
            assertMatch(c, "[!b-dx-z]", !"bcdxyz".contains(c))
        }

        // Case insensitive.
        for c in characters {
            assertMatch(c, "[B-D]", "bcd".contains(c), false)
            assertMatch(c, "[!B-D]", !"bcd".contains(c), false)
        }

        for c in uppercaseCharacters {
            assertMatch(c, "[b-d]", "BCD".contains(c), false)
            assertMatch(c, "[!b-d]", !"BCD".contains(c), false)
        }

        // Upper bound == lower bound.
        for c in characters {
            assertMatch(c, "[b-b]", c == "b")
        }

        // Special cases.
        for c in characters {
            assertMatch(c, "[!-#]", !"-#".contains(c))
            assertMatch(c, "[!--.]", !"-.".contains(c))
            assertMatch(c, "[^-`]", "^_`".contains(c))

            if c == "/" {
                assertMatch(c, "[[-^]", #"[\]^"#.contains(c))
                assertMatch(c, #"[\-^]"#, #"\]^"#.contains(c))
            }

            assertMatch(c, "[b-]", "-b".contains(c))
            assertMatch(c, "[!b-]", !"-b".contains(c))
            assertMatch(c, "[-b]", "-b".contains(c))
            assertMatch(c, "[!-b]", !"-b".contains(c))
            assertMatch(c, "[-]", "-".contains(c))
            assertMatch(c, "[!-]", !"-".contains(c))
        }

        // Upper bound is less that lower bound: error in RE.
        for c in characters {
            assertMatch(c, "[d-b]", false)
            assertMatch(c, "[!d-b]", true)
            assertMatch(c, "[d-bx-z]", "xyz".contains(c))
            assertMatch(c, "[!d-bx-z]", !"xyz".contains(c))
            assertMatch(c, "[d-b^-`]", "^_`".contains(c))

            if c == "/" {
                assertMatch(c, "[d-b[-^]", #"[\]^"#.contains(c))
            }
        }
    }

    func testStars() {

      assertMatch("A/B/C/f", "A/**/f")
      assertMatch("A/B/f", "A/**/f")
      assertMatch("A/f", "A/**/f")
      assertMatch("AB/f", "A/**/f", false)
      assertMatch("A/af", "A/**/f", false)

      assertMatch("A/B/C/f", "A/**/**/f")
      assertMatch("A/B/f", "A/**/**/f")
      assertMatch("A/f", "A/**/**/f")
      assertMatch("AB/f", "A/**/**/f", false)
      assertMatch("A/af", "A/**/**/f", false)

      assertMatch("A/b/f", "A/**/b/**/f")
      assertMatch("A/c/b/f", "A/**/b/**/f")
      assertMatch("A/b/c/f", "A/**/b/**/f")
      assertMatch("A/c/b/c/f", "A/**/b/**/f")
      assertMatch("A/c/b/c/af", "A/**/b/**/f", false)
      assertMatch("A/f", "A/**/b/**/f", false)
      assertMatch("b/f", "A/**/b/**/f", false)
      assertMatch("A/bc/f", "A/**/b/**/f", false)

      assertMatch("A/B/f", "A/**/**/**/**/f")
      assertMatch("A/f", "A/**/**/**/**/f")
      assertMatch("AB/f", "A/**/**/**/**/f", false)
      assertMatch("A/af", "A/**/**/**/**/f", false)

      assertMatch("A/B/C/f", "**/f")
      assertMatch("A/B/f", "**/f")
      assertMatch("A/f", "**/f")
      assertMatch("AB/f", "**/f")
      assertMatch("AB/fa", "**/f", false)
      assertMatch("A/af", "**/f", false)

      assertMatch("A/b/f", "A/**/b/f")
      assertMatch("A/c/b/f", "A/**/b/f")
      assertMatch("A/b/c/f", "A/**/b/f", false)
      assertMatch("AB/b/f", "A/**/b/f", false)
      assertMatch("A/b/af", "A/**/b/f", false)
      assertMatch("A/a/f", "A/b/**/f", false)
    }

    func testSepInCharSet() {
        assertMatch("/", #"[/]"#)
        assertMatch("\\", #"[\]"#)
        assertMatch("/", #"[\]"#, false)
        assertMatch("\\", #"[/]"#, false)
        assertMatch("[/]", #"[/]"#, false)
        assertMatch(#"[\\]"#, #"[/]"#, false)
        assertMatch("\\", #"[\t]"#)
        assertMatch("/", #"[\t]"#, false)
        assertMatch("t", #"[\t]"#)
        assertMatch("\t", #"[\t]"#, false)
    }

    func testSepInRange() {
        assertMatch("a/b", "a[.-0]b", true)
        assertMatch("a\\b", "a[.-0]b", false)
        assertMatch("a\\b", "a[Z-^]b", true)
        assertMatch("a/b", "a[Z-^]b", false)

        assertMatch("a/b", "a[/-0]b", true)
        assertMatch(#"a\b"#, "a[/-0]b", false)
        assertMatch("a[/-0]b", "a[/-0]b", false)
        assertMatch(#"a[\-0]b"#, "a[/-0]b", false)

        assertMatch("a/b", "a[.-/]b")
        assertMatch(#"a\b"#, "a[.-/]b", false)
        assertMatch("a[.-/]b", "a[.-/]b", false)
        assertMatch(#"a[.-\]b"#, "a[.-/]b", false)

        assertMatch(#"a\b"#, #"a[\-^]b"#)
        assertMatch("a/b", #"a[\-^]b"#, false)
        assertMatch(#"a[\-^]b"#, #"a[\-^]b"#, false)
        assertMatch("a[/-^]b", #"a[\-^]b"#, false)

        assertMatch(#"a\b"#, #"a[Z-\]b"#, true)
        assertMatch("a/b", #"a[Z-\]b"#, false)
        assertMatch(#"a[Z-\]b"#, #"a[Z-\]b"#, false)
        assertMatch("a[Z-/]b", #"a[Z-\]b"#, false)
    }

    func testTranslate() throws {
        XCTAssertEqual(FilenameMatcher.translate("*"), #"(?s:.*)\Z"#)
        XCTAssertEqual(FilenameMatcher.translate("?"), #"(?s:.)\Z"#)
        XCTAssertEqual(FilenameMatcher.translate("a?b*"), #"(?s:a.b.*)\Z"#)
        XCTAssertEqual(FilenameMatcher.translate("[abc]"), #"(?s:[abc])\Z"#)
        XCTAssertEqual(FilenameMatcher.translate("[]]"), #"(?s:[]])\Z"#)
        XCTAssertEqual(FilenameMatcher.translate("[!x]"), #"(?s:[^x])\Z"#)
        XCTAssertEqual(FilenameMatcher.translate("[^x]"), #"(?s:[\^x])\Z"#)
        XCTAssertEqual(FilenameMatcher.translate("[x"), #"(?s:\[x)\Z"#)

        // from the docs
        XCTAssertEqual(FilenameMatcher.translate("*.txt"), #"(?s:.*\.txt)\Z"#)

        // squash consecutive stars
        XCTAssertEqual(FilenameMatcher.translate("*********"), #"(?s:.*)\Z"#)
        XCTAssertEqual(FilenameMatcher.translate("A*********"), #"(?s:A.*)\Z"#)
        XCTAssertEqual(FilenameMatcher.translate("*********A"), #"(?s:.*A)\Z"#)
        XCTAssertEqual(FilenameMatcher.translate("A*********?[?]?"), #"(?s:A.*.[?].)\Z"#)

        // fancy translation to prevent exponential-time match failure
        let t = FilenameMatcher.translate("**a*a****a")
        XCTAssertEqual(t, #"(?s:.*a.*a.*a)\Z"#)

        // and try pasting multiple translate results - it's an undocumented
        // feature that this works
        let r1 = FilenameMatcher.translate("**a**a**a*")
        let r2 = FilenameMatcher.translate("**b**b**b*")
        let r3 = FilenameMatcher.translate("*c*c*c*")
        let fatre = [r1, r2, r3].joined(separator: "|")
        XCTAssertTrue(matches(fatre, "abaccad"))
        XCTAssertTrue(matches(fatre, "abxbcab"))
        XCTAssertTrue(matches(fatre, "cbabcaxc"))
        XCTAssertFalse(matches(fatre, "dabccbad"))
    }

    // MARK: - Private

    private var lowercaseCharacters: [String] {
        (97 ... 122).map { Character(Unicode.Scalar($0)) }.map { String($0) }
    }

    private var uppercaseCharacters: [String] {
        (65 ... 90).map { Character(Unicode.Scalar($0)) }.map { String($0) }
    }

    private var decimalCharacters: [String] {
        (48 ... 57).map { Character(Unicode.Scalar($0)) }.map { String($0) }
    }

    private var controlCharacters: [String] {
        [33 ... 47, 58 ... 64, 92 ... 96, 123 ... 126].flatMap {
            $0.map { Character(Unicode.Scalar($0)) }
        }.map { String($0) }
    }

    private func matches(_ pattern: String, _ str: String) -> Bool {
        let range = NSMakeRange(0, str.count)
        let expr = try! NSRegularExpression(pattern: pattern)
        return expr.numberOfMatches(in: str, range: range) > 0
    }

    private func assertMatch(_ filename: String, _ pattern: String, _ shouldMatch: Bool = true, _ caseSensitive: Bool = false, file: StaticString = #file, line: UInt = #line) {
        let matcher = FilenameMatcher(pattern: pattern, caseSensitive: caseSensitive)
        let result = matcher.match(filename: filename)
        shouldMatch ? XCTAssertTrue(result, "\(filename) should match \(pattern)", file: file, line: line) : XCTAssertFalse(result, "\(filename) should not match \(pattern)", file: file, line: line)
    }
}
