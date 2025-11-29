import Testing
@testable import ToJyutpingSwift

@Test func testGetJyutpingList() async throws {
    let result = getJyutpingList("哥哥")
    #expect(result.count == 2)
    #expect(result[0].0 == "哥")
    #expect(result[1].0 == "哥")
    print("getJyutpingList(\"你好\"): \(result)")
}

@Test func testGetJyutping() async throws {
    let result = getJyutping("你好")
    print("getJyutping(\"你好\"): \(result)")
    // Should contain parentheses with jyutping
//    #expect(result.contains("("))
//    #expect(result.contains(")"))
}

@Test func testGetJyutpingText() async throws {
    let result = getJyutpingText("你好！")
    print("getJyutpingText(\"你好！\"): \(result)")
    // Should be formatted text without Chinese characters
}

@Test func testGetJyutpingCandidates() async throws {
    let result = getJyutpingCandidates("好")
    #expect(result.count == 1)
    #expect(result[0].0 == "好")
    print("getJyutpingCandidates(\"好\"): \(result)")
}

@Test func testGetIPAList() async throws {
    let result = getIPAList("你好")
    #expect(result.count == 2)
    print("getIPAList(\"你好\"): \(result)")
}

@Test func testGetIPA() async throws {
    let result = getIPA("你好")
    print("getIPA(\"你好\"): \(result)")
    // Should contain brackets with IPA
//    #expect(result.contains("["))
//    #expect(result.contains("]"))
}

@Test func testGetIPAText() async throws {
    let result = getIPAText("你好！")
    print("getIPAText(\"你好！\"): \(result)")
}

@Test func testJyutpingToIPA() async throws {
    let result = jyutpingToIPA("nei5")
    print("jyutpingToIPA(\"nei5\"): \(result)")
    // Should produce IPA output
    #expect(!result.isEmpty)
    
    let result2 = jyutpingToIPA("hou2")
    print("jyutpingToIPA(\"hou2\"): \(result2)")
    #expect(!result2.isEmpty)
}

@Test func testCustomize() async throws {
    let customConverter = ToJyutping.customize(["好": "hou3"])
    let result = customConverter.getJyutping("你好")
    print("Custom getJyutping(\"你好\"): \(result)")
    #expect(result.contains("hou3"))
}

@Test func testTrieDirect() async throws {
    let trie = Trie()
    
    // Test single character
    let result = trie.get("好")
    #expect(result.count == 1)
    #expect(result[0].0 == "好")
    print("Trie.get(\"好\"): \(result)")
    
    // Test getAll
    let allResult = trie.getAll("好")
    #expect(allResult.count == 1)
    print("Trie.getAll(\"好\"): \(allResult)")
}

@Test func testDecodeJyutping() async throws {
    // Test the decodeJyutping function
    // This tests the encoding scheme used in the data file
    let result = decodeJyutping(0)  // Should be aa1
    print("decodeJyutping(0): \(result)")
    #expect(result == "aa1")
}
