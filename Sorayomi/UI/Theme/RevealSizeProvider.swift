import SwiftUI

// MARK: - RevealSizeProvider

/// リビュー画面のサイズをデバイスの利用可能幅から比例計算するユーティリティ。
/// `GeometryReader` で取得した幅を渡すことで、iPhone SE〜iPad Pro 12.9" まで
/// 自然にスケールするサイズを返す。
///
/// Usage:
/// ```swift
/// GeometryReader { geo in
///     let sizes = RevealSizeProvider(availableWidth: geo.size.width)
///     Circle().frame(width: sizes.constellationSize)
/// }
/// ```
struct RevealSizeProvider {
    let availableWidth: CGFloat

    /// iPadなど大画面デバイスかどうか（幅600pt超）
    private var isLargeScreen: Bool { availableWidth > 600 }

    // MARK: - Zodiac

    /// 星座コンステレーションの表示サイズ（iPhone: ~220, iPad: ~400）
    var constellationSize: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.48, 480)
            : min(availableWidth * 0.56, 300)
    }

    /// 星座グロー外周サイズ
    var constellationGlowSize: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.54, 520)
            : min(availableWidth * 0.62, 320)
    }

    // MARK: - Tarot

    /// タロット1枚表示のカードサイズ
    var tarotSingleCard: CGSize {
        let w = isLargeScreen
            ? min(availableWidth * 0.32, 300)
            : min(availableWidth * 0.4, 180)
        return CGSize(width: w, height: w * 1.5)
    }

    /// タロット3枚表示のカード幅
    var tarotThreeCardWidth: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.22, 220)
            : min(availableWidth * 0.24, 120)
    }

    /// タロット5枚表示のカード幅
    var tarotFiveCardWidth: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.16, 170)
            : min(availableWidth * 0.2, 100)
    }

    // MARK: - Tarot Close-Up

    /// タロットクローズアップ表示のカード幅（Phase 1: 個別リビール）
    var tarotCloseUpWidth: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.40, 340)
            : min(availableWidth * 0.62, 260)
    }

    /// タロット詳細オーバーレイのカード幅（タップ拡大時）
    var tarotDetailWidth: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.38, 320)
            : min(availableWidth * 0.58, 240)
    }

    // MARK: - Numerology

    /// 数秘術バックグラウンドグローサイズ
    var numerologyGlow: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.7, 800)
            : min(availableWidth * 0.85, 600)
    }

    /// 数秘術中央リングサイズ
    var numerologyCentralRing: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.38, 340)
            : min(availableWidth * 0.48, 200)
    }

    /// 数秘術外側リングサイズ
    var numerologyOuterRing: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.42, 380)
            : min(availableWidth * 0.52, 220)
    }

    /// 数秘術内側リングサイズ
    var numerologyInnerRing: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.3, 280)
            : min(availableWidth * 0.38, 160)
    }

    // MARK: - Blood Type

    /// 血液型相性サークルサイズ
    var bloodTypeCircle: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.24, 240)
            : min(availableWidth * 0.3, 140)
    }

    // MARK: - Nine Star Ki

    /// 九星気学の星シンボルサイズ
    var nineStarSymbol: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.15, 140)
            : min(availableWidth * 0.2, 90)
    }

    /// 九星気学グリッドセルの高さ
    var nineStarGridCellHeight: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.12, 110)
            : min(availableWidth * 0.16, 72)
    }

    // MARK: - Flower Fortune

    /// 花占いの花のサイズ
    var flowerSize: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.42, 400)
            : min(availableWidth * 0.55, 240)
    }

    /// 花占い花びら一枚のサイズ
    var petalSize: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.12, 110)
            : min(availableWidth * 0.16, 70)
    }

    /// 花占いグローサイズ
    var flowerGlow: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.6, 600)
            : min(availableWidth * 0.75, 400)
    }

    // MARK: - Stone Fortune

    /// ストーン占いの宝石サイズ
    var stoneSize: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.35, 340)
            : min(availableWidth * 0.45, 200)
    }

    /// ストーン光線のサイズ
    var stoneLightBeam: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.5, 480)
            : min(availableWidth * 0.65, 300)
    }

    /// ストーングローサイズ
    var stoneGlow: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.6, 600)
            : min(availableWidth * 0.75, 400)
    }

    // MARK: - Ornamental Background

    /// 背景装飾の大きいサイズ
    var ornamentalLarge: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.5, 440)
            : min(availableWidth * 0.65, 280)
    }

    /// 背景装飾の小さいサイズ
    var ornamentalSmall: CGFloat {
        isLargeScreen
            ? min(availableWidth * 0.3, 300)
            : min(availableWidth * 0.4, 180)
    }
}
