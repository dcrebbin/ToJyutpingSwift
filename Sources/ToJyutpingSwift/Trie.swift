import Foundation

// MARK: - Trie Node

/// A node in the trie structure
public final class TrieNode {
    /// Children nodes keyed by character
    var children: [Character: TrieNode] = [:]
    /// Jyutping values at this node
    var values: [String]?
    /// Custom values per Trie instance (for CustomizableTrie)
    /// Uses object wrapper to support nil as an explicit "no value" marker
    var customValues: NSMapTable<AnyObject, AnyObject>?
    
    init() {}
    
    func getChild(_ char: Character) -> TrieNode? {
        return children[char]
    }
    
    func setChild(_ char: Character, node: TrieNode) {
        children[char] = node
    }
}

// MARK: - Thread-safe Root Storage

/// Thread-safe storage for the trie root
private final class TrieRootStorage: @unchecked Sendable {
    static let shared = TrieRootStorage()
    
    private var root: TrieNode?
    private let lock = NSLock()
    
    func getRoot() -> TrieNode {
        lock.lock()
        defer { lock.unlock() }
        
        if let existing = root {
            return existing
        }
        
        let newRoot = TrieNode()
        loadTrieData(into: newRoot)
        root = newRoot
        return newRoot
    }
}

/// Gets the shared root, loading data if needed
private func getRoot() -> TrieNode {
    return TrieRootStorage.shared.getRoot()
}

// MARK: - Data Loading

/// Loads the trie data from the bundled data file
private func loadTrieData(into root: TrieNode) {
    guard let dataURL = findDataFile(),
          let data = try? String(contentsOf: dataURL, encoding: .utf8) else {
        print("Warning: Could not load trie data file")
        return
    }
    
    let chars = Array(data)
    guard !chars.isEmpty else { return }
    
    var nodeStack: [TrieNode] = [root]
    var depthStack: [Int] = [0]
    var i = 1  // Skip first character (usually '{')
    
    while !nodeStack.isEmpty && i < chars.count {
        var currentNode = nodeStack[nodeStack.count - 1]
        var depth = depthStack[depthStack.count - 1]
        
        // Read characters with codePoint >= 256 (Chinese characters)
        while i < chars.count {
            let codePoint = chars[i].unicodeScalars.first?.value ?? 0
            if codePoint < 256 { break }
            
            let newNode = TrieNode()
            currentNode.setChild(chars[i], node: newNode)
            currentNode = newNode
            depth += 1
            i += 1
        }
        
        // Read jyutping values (characters with codePoint < 123)
        var values: [String] = []
        while i < chars.count {
            let codePoint = chars[i].unicodeScalars.first?.value ?? 0
            if codePoint >= 123 { break }
            
            var pronunciations: [String] = []
            var charCount = 0
            while charCount < depth && i + 1 < chars.count {
                let c1 = Int(chars[i].asciiValue ?? 0) - 33
                let c2 = Int(chars[i + 1].asciiValue ?? 0) - 33
                let encoded = c1 * 90 + c2
                pronunciations.append(decodeJyutping(encoded))
                i += 2
                
                // Check for continuation marker '~'
                if i < chars.count && chars[i] == "~" {
                    i += 1
                } else {
                    charCount += 1
                }
            }
            values.append(pronunciations.joined(separator: " "))
        }
        
        if !values.isEmpty {
            currentNode.values = values
        }
        
        // Handle structure markers
        if i < chars.count && chars[i] == "{" {
            i += 1
            nodeStack.append(currentNode)
            depthStack.append(depth)
        } else if i < chars.count && chars[i] == "}" {
            i += 1
            nodeStack.removeLast()
            depthStack.removeLast()
        }
    }
}

/// Finds the data file URL
private func findDataFile() -> URL? {
    // Fallback: check relative to source file location (for development)
    let fileManager = FileManager.default
    let sourceFile = #file
    let sourceDir = URL(fileURLWithPath: sourceFile).deletingLastPathComponent()
    let dataPath = sourceDir.appendingPathComponent("data.txt")
    
    if fileManager.fileExists(atPath: dataPath.path) {
        return dataPath
    }
    
    // Check main bundle (for iOS/macOS apps)
    if let url = Bundle.main.url(forResource: "data", withExtension: "txt") {
        return url
    }
    
    return nil
}

// MARK: - Trie Class

/// A trie for looking up Jyutping romanizations of Chinese characters
open class Trie {
    private let root: TrieNode
    
    public init() {
        self.root = getRoot()
    }
    
    /// Looks up Jyutping for a string, returning the best match for each character/phrase
    /// - Parameter s: The string to look up
    /// - Returns: Array of tuples (character, jyutping or nil)
    open func get(_ s: String) -> [(String, String?)] {
        var result: [(String, String?)] = []
        let chars = Array(s)
        var i = 0
        
        while i < chars.count {
            var currentNode = root
            var matchedJyutping = ""
            var matchEndIndex = i
            
            // Try to find the longest match
            for j in i..<chars.count {
                guard let nextNode = currentNode.getChild(chars[j]) else { break }
                currentNode = nextNode
                
                if let values = getValue(nextNode), !values.isEmpty {
                    matchedJyutping = values[0]
                    matchEndIndex = j
                }
            }
            
            if matchEndIndex == i {
                // No multi-character match, single character
                result.append((String(chars[i]), matchedJyutping.isEmpty ? nil : matchedJyutping))
                i += 1
            } else {
                // Multi-character match
                let jyutpingParts = matchedJyutping.split(separator: " ").map(String.init)
                let startIndex = i
                while i <= matchEndIndex {
                    let partIndex = i - startIndex
                    let jyutping = partIndex < jyutpingParts.count ? jyutpingParts[partIndex] : nil
                    result.append((String(chars[i]), jyutping))
                    i += 1
                }
            }
        }
        
        return result
    }
    
    open func getAll(_ s: String) -> [(String, [String])] {
        let chars = Array(s)
        
        // Initialize result with single-character lookups
        var result: [(Character, [[String]])] = chars.map { char in
            if let node = root.getChild(char),
               let values = getValue(node) {
                return (char, [values])
            }
            return (char, [])
        }
        
        // Find multi-character matches
        for i in 0..<result.count {
            guard var currentNode = root.getChild(result[i].0) else { continue }
            
            for j in (i + 1)..<result.count {
                guard let nextNode = currentNode.getChild(result[j].0) else { break }
                currentNode = nextNode
                
                if let values = getValue(currentNode) {
                    let matchLength = j - i
                    for pronunciation in values {
                        let parts = pronunciation.split(separator: " ").map(String.init)
                        for k in i...j {
                            let partIndex = k - i
                            if partIndex < parts.count {
                                // Ensure we have enough slots
                                while result[k].1.count <= matchLength {
                                    result[k].1.append([])
                                }
                                if !result[k].1[matchLength].contains(parts[partIndex]) {
                                    result[k].1[matchLength].append(parts[partIndex])
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Flatten and deduplicate results
        return result.map { (char, nestedPronunciations) in
            let flattened = nestedPronunciations.reversed().flatMap { $0 }
            let unique = Array(Set(flattened))
            return (String(char), unique)
        }
    }
    
    /// Gets the value for a node (can be overridden for customization)
    open func getValue(_ node: TrieNode) -> [String]? {
        return node.values
    }
}

// MARK: - Customizable Trie

/// Marker for explicit nil value in customization
private final class NilMarker: NSObject, Sendable {}
private let nilMarker = NilMarker()

/// A trie that supports custom overrides for specific entries
public final class CustomizableTrie: Trie {
    private weak var parent: Trie?
    
    /// Creates a customizable trie with a parent trie for fallback lookups
    public init(parent: Trie) {
        self.parent = parent
        super.init()
    }
    
    /// Customizes the jyutping for a specific key
    /// - Parameters:
    ///   - key: The Chinese character(s) to customize
    ///   - values: The custom jyutping values, or nil to clear/disable the entry
    public func customize(_ key: String, values: [String]?) {
        let root = getRoot()
        
        // Navigate/create path to the node
        var currentNode = root
        for char in key {
            if let existing = currentNode.getChild(char) {
                currentNode = existing
            } else {
                let newNode = TrieNode()
                currentNode.setChild(char, node: newNode)
                currentNode = newNode
            }
        }
        
        // Set custom value for this trie instance
        if currentNode.customValues == nil {
            currentNode.customValues = NSMapTable<AnyObject, AnyObject>.weakToStrongObjects()
        }
        
        if let values = values {
            currentNode.customValues?.setObject(values as NSArray, forKey: self)
        } else {
            // Setting nil explicitly means "no value" (different from not set)
            currentNode.customValues?.setObject(nilMarker, forKey: self)
        }
    }
    
    public override func getValue(_ node: TrieNode) -> [String]? {
        // Fast path: no custom values map
        guard let customValues = node.customValues else {
            return node.values
        }
        
        // Check for custom value
        if let customValue = customValues.object(forKey: self) {
            if customValue is NilMarker {
                return nil
            }
            return customValue as? [String]
        }
        
        // Fallback to parent
        return parent?.getValue(node) ?? node.values
    }
}
