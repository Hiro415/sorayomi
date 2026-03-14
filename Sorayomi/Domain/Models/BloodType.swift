import Foundation

/// Japanese blood type classification with personality associations.
enum BloodType: String, Codable, CaseIterable, Identifiable {
    case a = "A"
    case b = "B"
    case o = "O"
    case ab = "AB"

    var id: String { rawValue }

    var japaneseName: String {
        return "\(rawValue)型"
    }

    var shortDescription: String {
        switch self {
        case .a:  return "几帳面で誠実"
        case .b:  return "自由奔放でマイペース"
        case .o:  return "おおらかでリーダー気質"
        case .ab: return "理知的で多面的"
        }
    }
}
