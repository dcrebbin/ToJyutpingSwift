import Foundation

// MARK: - Punctuation Dictionaries

/// Maps Chinese/special punctuation to ASCII equivalents
private let punctDict: [Character: Character] = {
    let from = Array(#"!"'(),-./:;?[]{}~·‐‑‒–—―''""…⋮⋯⸱⸳⸺⸻、。〈〉《》「」『』【】〔〕〖〗〘〙〚〛〜〝〞〟・︐︑︒︓︔︕︖︗︘︙︱︲︵︶︷︸︹︺︻︼︽︾︿﹀﹁﹂﹃﹄﹇﹈﹐﹑﹒﹔﹕﹖﹗﹘﹙﹚﹛﹜﹝﹞﹣！＂＇（），－．／：；？［］｛｝～｟｠｡｢｣､･"#)
    let to = Array(#"!"'(),-./:;?[]{}~·------''""………··--,.''""""''[][][][][]~"""·,,.:;!?[]…--(){}[][]""''""''[],,.;:?!-(){}[]-!"'(),-./:;?[]{}~()."",·"#)
    var dict: [Character: Character] = [:]
    for (f, t) in zip(from, to) {
        dict[f] = t
    }
    return dict
}()

// MARK: - Punctuation Sets

private let leftBracket: Set<Character> = Set("([{'\u{201C}")  // ' and "
private let rightBracket: Set<Character> = Set(")]}\u{2019}\u{201D}")  // ' and "
private let leftBracketToRight: [Character: Character] = [
    "(": ")",
    "[": "]",
    "{": "}",
    "\u{2018}": "\u{2019}",  // ' → '
    "\u{201C}": "\u{201D}"   // " → "
]
private let leftPunct: Set<Character> = Set("([{'\u{201C}")
private let rightPunct: Set<Character> = Set("!,.:;?…)]}\u{2019}\u{201D}")
private let otherPunct: Set<Character> = Set("\"'·-~")
private let leftOrOtherPunct: Set<Character> = Set(" ([{'\u{201C}\"'·-~")
private let rightOrOtherPunct: Set<Character> = Set("!,.:;?…)]}\u{2019}\u{201D}\"'·-~")

private let minusSigns: Set<Character> = Set("-﹣－")
private let decimalSeps: Set<Character> = Set("',.·⸱⸳﹒＇．")
private let digits: Set<Character> = Set("0０𝟎𝟘𝟢𝟬𝟶🯰1１𝟏𝟙𝟣𝟭𝟷🯱2２𝟐𝟚𝟤𝟮𝟸🯲3３𝟑𝟛𝟥𝟯𝟹🯳4４𝟒𝟜𝟦𝟰𝟺🯴5５𝟓𝟝𝟧𝟱𝟻🯵6６𝟔𝟞𝟨𝟲𝟼🯶7７𝟕𝟟𝟩𝟳𝟽🯷8８𝟖𝟠𝟪𝟴𝟾🯸9９𝟗𝟡𝟫𝟵𝟿🯹")
private let unknownOrHyphen: Set<String> = ["", "-"]

// MARK: - Jyutping Decoding

/// Jyutping onset (initial consonant) array
private let onset = ["", "b", "p", "m", "f", "d", "t", "n", "l", "g", "k", "ng", "gw", "kw", "w", "h", "z", "c", "s", "j"]

/// Jyutping nucleus (vowel) array
private let nucleus = ["aa", "a", "e", "i", "o", "u"]

/// Jyutping special rhymes
private let rhyme = ["oe", "oen", "oeng", "oet", "oek", "eoi", "eon", "eot", "yu", "yun", "yut", "m", "ng"]

/// Jyutping coda (final consonant) array
private let coda = ["", "i", "u", "m", "n", "ng", "p", "t", "k"]

/// Decodes an encoded Jyutping ID to its romanization string
/// - Parameter id: The encoded Jyutping ID
/// - Returns: The decoded Jyutping romanization (e.g., "hou2")
public func decodeJyutping(_ id: Int) -> String {
    let finalIndex = (id % 402) / 6
    let onsetIndex = id / 402
    let tone = (id % 6) + 1
    
    let finalPart: String
    if finalIndex >= 54 {
        finalPart = rhyme[finalIndex - 54]
    } else {
        finalPart = nucleus[finalIndex / 9] + coda[finalIndex % 9]
    }
    
    return "\(onset[onsetIndex])\(finalPart)\(tone)"
}

// MARK: - Text Formatting

/// Formats romanization text by adding appropriate spacing around punctuation
/// - Parameters:
///   - s: The input string
///   - conv: A conversion function that returns character-romanization pairs
/// - Returns: The formatted romanization text
public func formatRomanizationText(_ s: String, conv: (String) -> [(String, String?)]) -> String {
    // Match sequences that don't contain control characters
    let pattern = #"[^\x00-\x1f\x80-\x9f]+"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return s
    }
    
    var result = s
    let matches = regex.matches(in: s, options: [], range: NSRange(s.startIndex..., in: s))
    
    // Process matches in reverse order to preserve indices
    for match in matches.reversed() {
        guard let range = Range(match.range, in: s) else { continue }
        let m = String(s[range])
        let formatted = formatRomanizationSegment(m, conv: conv)
        result.replaceSubrange(range, with: formatted)
    }
    
    return result
}

/// Formats a single segment of romanization text
private func formatRomanizationSegment(_ m: String, conv: (String) -> [(String, String?)]) -> String {
    var t: [String?] = [nil]
    var d: [Character?] = [nil]
    
    for (k, v) in conv(m) {
        if let v = v {
            t.append(v)
            d.append(nil)
        } else if !k.trimmingCharacters(in: .whitespaces).isEmpty {
            let char = k.first!
            t.append(punctDict[char].map { String($0) } ?? "")
            d.append(char)
        }
    }
    
    t.append(nil)
    d.append(nil)
    
    var l = ""
    var b = ""
    
    for i in 1..<(d.count - 1) {
        let p = t[i - 1]
        let c = t[i]!
        let n = t[i + 1]
        
        func between() -> Bool {
            var j = i - 1
            while j > 0, let tj = t[j], tj.count == 1, let tjChar = tj.first, rightBracket.contains(tjChar) {
                j -= 1
            }
            let f = j > 0 && t[j] != nil && (t[j]?.count ?? 0) > 1
            
            j = i + 1
            while j < t.count - 1, let tj = t[j], tj.count == 1, let tjChar = tj.first, leftBracket.contains(tjChar) {
                j += 1
            }
            let g = j > 0 && t[j] != nil && (t[j]?.count ?? 0) > 1
            
            return f && g
        }
        
        func lSpace() {
            if !l.isEmpty, let last = l.last, !leftOrOtherPunct.contains(last) {
                l += " "
            }
        }
        
        func rSpace() {
            if let nextD = d[i + 1], minusSigns.contains(nextD) {
                if i < d.count - 2, let nextNextD = d[i + 2], digits.contains(nextNextD) {
                    l += " "
                }
            } else if let nFirst = n?.first, !rightOrOtherPunct.contains(nFirst) {
                l += " "
            } else if n == nil || (n?.isEmpty ?? true) {
                // No space needed
            } else if let nFirst = n?.first, !rightOrOtherPunct.contains(nFirst) {
                l += " "
            }
        }
        
        if c.count > 1 {
            lSpace()
            l += c
            rSpace()
        } else if c.isEmpty || (d[i] != nil && minusSigns.contains(d[i]!) && 
                                d[i + 1] != nil && digits.contains(d[i + 1]!) && 
                                !unknownOrHyphen.contains(p ?? "")) {
            if !l.hasSuffix("[…]") {
                l += "[…]"
            }
        } else if let di = d[i], decimalSeps.contains(di),
                  let diNext = d[i + 1], digits.contains(diNext),
                  let diPrev = d[i - 1], digits.contains(diPrev) {
            continue
        } else if c.count == 1, let cChar = c.first, leftPunct.contains(cChar) {
            lSpace()
            l += c
            if let rightChar = leftBracketToRight[cChar] {
                b.append(rightChar)
            }
        } else if c.count == 1, let cChar = c.first, rightPunct.contains(cChar) {
            l += c
            rSpace()
            if let j = b.lastIndex(of: cChar) {
                b = String(b[..<j])
            }
        } else if c == "-" {
            if p == "-" { continue }
            if n == "-" || between() {
                l += " – "
            } else {
                l += c
            }
        } else if c == "~" {
            if (p == "~" && n != "~") || between() {
                l += "~ "
            } else {
                l += c
            }
        } else if c == "·" {
            l += c
        } else {
            // Handle quotes and other punctuation
            var j = b.count - 1
            var y = false
            while j >= 0 {
                let bChar = b[b.index(b.startIndex, offsetBy: j)]
                if rightBracket.contains(bChar) { break }
                if String(bChar) == c {
                    y = true
                    break
                }
                j -= 1
            }
            
            if y {
                b = String(b.prefix(j))
                l += c
                rSpace()
            } else {
                lSpace()
                l += c
                b += c
            }
        }
    }
    
    return l.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
}

// MARK: - IPA Text Formatting

private let majorBreak: Set<Character> = Set(".!?…")
private let minorBreak: Set<Character> = Set(",/:;-~()[]{}") 

/// Formats IPA text with proper breaks and spacing
/// - Parameters:
///   - s: The input string
///   - conv: A conversion function that returns character-IPA pairs
/// - Returns: The formatted IPA text
public func formatIPAText(_ s: String, conv: (String) -> [(String, String?)]) -> String {
    let pattern = #"[^\x00-\x1f\x80-\x9f]+"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return s
    }
    
    var result = s
    let matches = regex.matches(in: s, options: [], range: NSRange(s.startIndex..., in: s))
    
    for match in matches.reversed() {
        guard let range = Range(match.range, in: s) else { continue }
        let m = String(s[range])
        let formatted = formatIPASegment(m, conv: conv)
        result.replaceSubrange(range, with: formatted)
    }
    
    return result
}

/// Formats a single segment of IPA text
private func formatIPASegment(_ m: String, conv: (String) -> [(String, String?)]) -> String {
    var t: [String] = []
    var d: [Character?] = []
    
    for (k, v) in conv(m) {
        if let v = v {
            t.append(v)
            d.append(nil)
        } else if !k.trimmingCharacters(in: .whitespaces).isEmpty {
            let char = k.first!
            t.append(punctDict[char].map { String($0) } ?? "")
            d.append(char)
        }
    }
    d.append(nil)
    
    var l: [String] = []
    
    for i in 0..<t.count {
        let c = t[i]
        
        if c.count > 1 {
            l.append(c)
        } else if c.isEmpty || (d[i] != nil && minusSigns.contains(d[i]!) &&
                                d[i + 1] != nil && digits.contains(d[i + 1]!) &&
                                (i == 0 || !unknownOrHyphen.contains(t[i - 1]))) {
            if l.isEmpty || l.last != "⸨…⸩" {
                l.append("⸨…⸩")
            }
        } else if !l.isEmpty {
            if let di = d[i], decimalSeps.contains(di),
               i + 1 < d.count, let diNext = d[i + 1], digits.contains(diNext),
               i > 0, let diPrev = d[i - 1], digits.contains(diPrev) {
                continue
            }
            
            if let cChar = c.first, majorBreak.contains(cChar) {
                if let last = l.last, last.count > 1 {
                    l.append("‖")
                } else {
                    l[l.count - 1] = "‖"
                }
            } else if let cChar = c.first, minorBreak.contains(cChar), let last = l.last, last.count > 1 {
                l.append("|")
            }
        }
    }
    
    // Remove trailing single-character element
    if let last = l.last, last.count == 1 {
        l.removeLast()
    }
    
    var result = ""
    for i in 0..<l.count {
        let c = l[i]
        result += c
        
        if i < l.count - 1 {
            let n = l[i + 1]
            if c != "⸨…⸩" && c.count > 1 && n != "⸨…⸩" && n.count > 1 {
                result += "."
            } else {
                result += " "
            }
        }
    }
    
    return result
}
