// ToJyutpingSwift - A Swift library for converting Chinese text to Jyutping romanization
// https://github.com/CanCLID/ToJyutping
//
// Ported from the original TypeScript implementation.
//
// Usage:
//
//   import ToJyutpingSwift
//
//   // Simple conversion
//   let result = getJyutping("你好")  // "你(nei5)好(hou2)"
//
//   // Get list of characters with pronunciations
//   let list = getJyutpingList("你好")  // [("你", "nei5"), ("好", "hou2")]
//
//   // Get formatted text
//   let text = getJyutpingText("你好！")  // "nei5 hou2!"
//
//   // Get IPA transcription
//   let ipa = getIPA("你好")  // "你[nei̯˩˧]好[hou̯˧˥]"
//
//   // Custom converter
//   let custom = ToJyutping.customize(["好": "hou3"])
//   let customResult = custom.getJyutping("你好")
