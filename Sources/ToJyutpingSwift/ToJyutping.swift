import Foundation

// MARK: - IPA Conversion Maps

private let onsetToIPA: [String: String] = [
    "b": "p",
    "p": "pʰ",
    "m": "m",
    "f": "f",
    "d": "t",
    "t": "tʰ",
    "n": "n",
    "l": "l",
    "g": "k",
    "k": "kʰ",
    "ng": "ŋ",
    "gw": "kʷ",
    "kw": "kʷʰ",
    "w": "w",
    "h": "h",
    "z": "t͡s",
    "c": "t͡sʰ",
    "s": "s",
    "j": "j"
]

private let nucleusToIPA: [String: String] = [
    "aa": "aː",
    "a": "ɐ",
    "e": "ɛː",
    "i": "iː",
    "o": "ɔː",
    "u": "uː",
    "oe": "œː",
    "eo": "ɵ",
    "yu": "yː"
]

private let rhymeToIPA: [String: String] = [
    "ei": "ei̯",
    "ing": "eŋ",
    "ik": "ek̚",
    "ou": "ou̯",
    "ung": "oŋ",
    "uk": "ok̚",
    "eoi": "ɵy̑",
    "m": "m̩",
    "ng": "ŋ̍"
]

private let codaToIPA: [String: String] = [
    "i": "i̯",
    "u": "u̯",
    "m": "m",
    "n": "n",
    "ng": "ŋ",
    "p": "p̚",
    "t": "t̚",
    "k": "k̚"
]

private let toneToIPA: [String: String] = [
    "1": "˥",
    "2": "˧˥",
    "3": "˧",
    "4": "˨˩",
    "5": "˩˧",
    "6": "˨"
]

/// Regex for parsing Jyutping syllables
private let jyutpingRegex = try! NSRegularExpression(
    pattern: #"^([gk]w?|ng|[bpmfdtnlhwzcsj]?)(?![1-6]?$)((aa?|oe?|eo?|y?u|i?)(ng|[iumnptk]?))([1-6]?)$"#,
    options: .caseInsensitive
)

// MARK: - Jyutping to IPA Conversion

/// Converts a Jyutping romanization string to IPA (International Phonetic Alphabet)
/// - Parameter s: The Jyutping string to convert
/// - Returns: The IPA representation
public func jyutpingToIPA(_ s: String) -> String {
    let lowercased = s.lowercased()
    
    // Split by non-word characters
    let syllables = lowercased.components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }
    
    return syllables.map { syllable -> String in
        let range = NSRange(syllable.startIndex..., in: syllable)
        guard let match = jyutpingRegex.firstMatch(in: syllable, options: [], range: range) else {
            return ""
        }
        
        func extractGroup(_ index: Int) -> String? {
            guard index < match.numberOfRanges else { return nil }
            let nsRange = match.range(at: index)
            guard nsRange.location != NSNotFound,
                  let range = Range(nsRange, in: syllable) else { return nil }
            let result = String(syllable[range])
            return result.isEmpty ? nil : result
        }
        
        let initial = extractGroup(1)
        let final = extractGroup(2)
        let vowel = extractGroup(3)
        let terminal = extractGroup(4)
        let number = extractGroup(5)
        
        var result = ""
        
        // Add onset/initial
        if let initial = initial, let ipa = onsetToIPA[initial] {
            result += ipa
        }
        
        // Add final (rhyme or nucleus + coda)
        if let final = final, let ipa = rhymeToIPA[final] {
            result += ipa
        } else {
            if let vowel = vowel, let ipa = nucleusToIPA[vowel] {
                result += ipa
            }
            if let terminal = terminal, let ipa = codaToIPA[terminal] {
                result += ipa
            }
        }
        
        // Add tone
        if let number = number, let ipa = toneToIPA[number] {
            result += ipa
        }
        
        return result
    }.joined(separator: ".")
}

// MARK: - JyutpingConverter

/// A converter for Chinese text to Jyutping romanization and IPA
public class JyutpingConverter {
    private let trie: Trie
    
    /// Creates a new converter with the given trie
    /// - Parameter trie: The trie to use for lookups
    public init(trie: Trie) {
        self.trie = trie
    }
    
    /// Creates a new converter with the default trie
    public convenience init() {
        self.init(trie: Trie())
    }
    
    // MARK: - Jyutping Methods
    
    /// Gets a list of characters with their Jyutping romanizations
    /// - Parameter s: The Chinese text to convert
    /// - Returns: Array of (character, jyutping or nil) tuples
    public func getJyutpingList(_ s: String) -> [(String, String?)] {
        return trie.get(s)
    }
    
    /// Gets a string with inline Jyutping annotations
    /// - Parameter s: The Chinese text to convert
    /// - Returns: String with each character followed by its Jyutping in parentheses
    public func getJyutping(_ s: String) -> String {
        return trie.get(s)
            .map { (char, jyutping) in
                char + (jyutping.map { "(\($0))" } ?? "")
            }
            .joined()
    }
    
    /// Gets formatted Jyutping text with proper spacing
    /// - Parameter s: The Chinese text to convert
    /// - Returns: Formatted romanization text
    public func getJyutpingText(_ s: String) -> String {
        return formatRomanizationText(s) { [weak self] text in
            self?.getJyutpingList(text) ?? []
        }
    }
    
    /// Gets all possible Jyutping candidates for each character
    /// - Parameter s: The Chinese text to convert
    /// - Returns: Array of (character, array of possible jyutping) tuples
    public func getJyutpingCandidates(_ s: String) -> [(String, [String])] {
        return trie.getAll(s)
    }
    
    // MARK: - IPA Methods
    
    /// Gets a list of characters with their IPA transcriptions
    /// - Parameter s: The Chinese text to convert
    /// - Returns: Array of (character, IPA or nil) tuples
    public func getIPAList(_ s: String) -> [(String, String?)] {
        return trie.get(s).map { (char, jyutping) in
            (char, jyutping.map { jyutpingToIPA($0) })
        }
    }
    
    /// Gets a string with inline IPA annotations
    /// - Parameter s: The Chinese text to convert
    /// - Returns: String with each character followed by its IPA in brackets
    public func getIPA(_ s: String) -> String {
        return trie.get(s)
            .map { (char, jyutping) in
                char + (jyutping.map { "[\(jyutpingToIPA($0))]" } ?? "")
            }
            .joined()
    }
    
    /// Gets formatted IPA text with proper spacing
    /// - Parameter s: The Chinese text to convert
    /// - Returns: Formatted IPA text
    public func getIPAText(_ s: String) -> String {
        return formatIPAText(s) { [weak self] text in
            self?.getIPAList(text) ?? []
        }
    }
    
    /// Gets all possible IPA candidates for each character
    /// - Parameter s: The Chinese text to convert
    /// - Returns: Array of (character, array of possible IPA) tuples
    public func getIPACandidates(_ s: String) -> [(String, [String])] {
        return trie.getAll(s).map { (char, jyutpings) in
            (char, jyutpings.map { jyutpingToIPA($0) })
        }
    }
    
    // MARK: - Customization
    
    /// Creates a new converter with custom entries
    /// - Parameter entries: Dictionary of character(s) to their custom Jyutping values
    /// - Returns: A new customized converter
    public func customize(_ entries: [String: [String]?]) -> JyutpingConverter {
        let customTrie = CustomizableTrie(parent: trie)
        for (key, value) in entries {
            customTrie.customize(key, values: value)
        }
        return JyutpingConverter(trie: customTrie)
    }
    
    /// Creates a new converter with custom entries (string values)
    /// - Parameter entries: Dictionary of character(s) to their custom Jyutping value
    /// - Returns: A new customized converter
    public func customize(_ entries: [String: String?]) -> JyutpingConverter {
        let customTrie = CustomizableTrie(parent: trie)
        for (key, value) in entries {
            customTrie.customize(key, values: value.map { [$0] })
        }
        return JyutpingConverter(trie: customTrie)
    }
}

// MARK: - Default Instance

/// The default ToJyutping converter instance
public nonisolated(unsafe) let ToJyutping = JyutpingConverter()

// MARK: - Convenience Functions

/// Gets a list of characters with their Jyutping romanizations
/// - Parameter s: The Chinese text to convert
/// - Returns: Array of (character, jyutping or nil) tuples
public func getJyutpingList(_ s: String) -> [(String, String?)] {
    return ToJyutping.getJyutpingList(s)
}

/// Gets a string with inline Jyutping annotations
/// - Parameter s: The Chinese text to convert
/// - Returns: String with each character followed by its Jyutping in parentheses
public func getJyutping(_ s: String) -> String {
    return ToJyutping.getJyutping(s)
}

/// Gets formatted Jyutping text with proper spacing
/// - Parameter s: The Chinese text to convert
/// - Returns: Formatted romanization text
public func getJyutpingText(_ s: String) -> String {
    return ToJyutping.getJyutpingText(s)
}

/// Gets all possible Jyutping candidates for each character
/// - Parameter s: The Chinese text to convert
/// - Returns: Array of (character, array of possible jyutping) tuples
public func getJyutpingCandidates(_ s: String) -> [(String, [String])] {
    return ToJyutping.getJyutpingCandidates(s)
}

/// Gets a list of characters with their IPA transcriptions
/// - Parameter s: The Chinese text to convert
/// - Returns: Array of (character, IPA or nil) tuples
public func getIPAList(_ s: String) -> [(String, String?)] {
    return ToJyutping.getIPAList(s)
}

/// Gets a string with inline IPA annotations
/// - Parameter s: The Chinese text to convert
/// - Returns: String with each character followed by its IPA in brackets
public func getIPA(_ s: String) -> String {
    return ToJyutping.getIPA(s)
}

/// Gets formatted IPA text with proper spacing
/// - Parameter s: The Chinese text to convert
/// - Returns: Formatted IPA text
public func getIPAText(_ s: String) -> String {
    return ToJyutping.getIPAText(s)
}

/// Gets all possible IPA candidates for each character
/// - Parameter s: The Chinese text to convert
/// - Returns: Array of (character, array of possible IPA) tuples
public func getIPACandidates(_ s: String) -> [(String, [String])] {
    return ToJyutping.getIPACandidates(s)
}
