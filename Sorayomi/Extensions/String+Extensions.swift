import Foundation

// MARK: - String Extensions

extension String {

    // MARK: - Whitespace & Emptiness

    /// 前後の空白・改行を除去した文字列
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 空文字列またはホワイトスペースのみかどうか
    var isBlank: Bool {
        trimmed.isEmpty
    }

    // MARK: - Japanese Character Detection

    /// 日本語文字（ひらがな・カタカナ・漢字）を含むかどうか
    var containsJapanese: Bool {
        let japaneseRanges: [ClosedRange<Unicode.Scalar>] = [
            Unicode.Scalar(0x3040)!...Unicode.Scalar(0x309F)!, // ひらがな
            Unicode.Scalar(0x30A0)!...Unicode.Scalar(0x30FF)!, // カタカナ
            Unicode.Scalar(0x4E00)!...Unicode.Scalar(0x9FFF)!, // CJK統合漢字
            Unicode.Scalar(0x3400)!...Unicode.Scalar(0x4DBF)!, // CJK統合漢字拡張A
        ]

        return unicodeScalars.contains { scalar in
            japaneseRanges.contains { range in
                range.contains(scalar)
            }
        }
    }

    /// ひらがなのみで構成されているかどうか
    var isAllHiragana: Bool {
        let hiraganaRange = Unicode.Scalar(0x3040)!...Unicode.Scalar(0x309F)!
        let allowedScalars = unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) }
        guard !allowedScalars.isEmpty else { return false }
        return allowedScalars.allSatisfy { hiraganaRange.contains($0) }
    }

    /// カタカナのみで構成されているかどうか
    var isAllKatakana: Bool {
        let katakanaRange = Unicode.Scalar(0x30A0)!...Unicode.Scalar(0x30FF)!
        let allowedScalars = unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) }
        guard !allowedScalars.isEmpty else { return false }
        return allowedScalars.allSatisfy { katakanaRange.contains($0) }
    }

    // MARK: - Kana Conversion

    /// ひらがなをカタカナに変換
    var hiraganaToKatakana: String {
        let mutableString = NSMutableString(string: self)
        CFStringTransform(mutableString, nil, kCFStringTransformHiraganaKatakana, false)
        return mutableString as String
    }

    /// カタカナをひらがなに変換
    var katakanaToHiragana: String {
        let mutableString = NSMutableString(string: self)
        CFStringTransform(mutableString, nil, kCFStringTransformHiraganaKatakana, true)
        return mutableString as String
    }

    // MARK: - Truncation

    /// 指定文字数で切り詰め（末尾に「...」を付加）
    func truncated(to maxLength: Int, trailing: String = "...") -> String {
        guard count > maxLength else { return self }
        let endIndex = index(startIndex, offsetBy: maxLength)
        return String(self[..<endIndex]) + trailing
    }

    // MARK: - Character Count (Japanese-aware)

    /// 全角文字数を考慮した表示幅（全角=2, 半角=1）
    var displayWidth: Int {
        var width = 0
        for scalar in unicodeScalars {
            // CJK文字、全角カナ、全角記号は幅2
            if (0x3000...0x9FFF).contains(scalar.value) ||
               (0xF900...0xFAFF).contains(scalar.value) ||
               (0xFF01...0xFF60).contains(scalar.value) ||
               (0xFFE0...0xFFE6).contains(scalar.value) {
                width += 2
            } else {
                width += 1
            }
        }
        return width
    }

    // MARK: - Convenience

    /// nilまたは空文字列の場合にデフォルト値を返す
    func ifBlank(_ defaultValue: String) -> String {
        isBlank ? defaultValue : self
    }

    /// 先頭の文字を大文字にする（日本語では何もしない）
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}

// MARK: - Optional String

extension Optional where Wrapped == String {

    /// nil または空文字列の場合 true
    var isNilOrBlank: Bool {
        switch self {
        case .none:
            return true
        case .some(let value):
            return value.isBlank
        }
    }
}
