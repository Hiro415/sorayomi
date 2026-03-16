# 血液型占いエンジン強化 設計ドキュメント

**日付:** 2026-03-16
**ステータス:** 承認済み

---

## 概要

血液型占いエンジンを、4型×1文の静的ルックアップから、4モード選択＋専用演出画面＋実在占術ベースの複合判定エンジンに強化する。

## アプローチ

**C案（採用）:** モード選択専用画面＋モード別RevealView演出の2段構成。タロットのTarotRevealViewと同等の没入体験を血液型でも実現する。

---

## 1. データモデル & 計算エンジン

### 1-A. BloodTypeMode（新規enum）

```swift
enum BloodTypeMode: String, CaseIterable, Identifiable {
    case dailyFortune    // 今日の運勢
    case compatibility   // 相性診断
    case loveMatch       // 恋愛相性
    case ranking         // 今日のランキング
}
```

### 1-B. BloodTypeCalculator 強化

**現状:** 4型 × { 性格1文, 強み1文, 弱み1文, 相性リスト }
**強化後:**

| データ | 内容 |
|--------|------|
| 詳細プロファイル | 基本性格・恋愛傾向・仕事傾向・金銭感覚・健康傾向（各型5項目） |
| 相性マトリクス | 4×4=16組。総合スコア(1-5)＋解説文 |
| 恋愛相性マトリクス | 16組×4サブスコア（コミュニケーション・価値観・情熱度・長期安定度） |
| 日替わり運勢 | 実在占術の複合判定（後述） |
| 日替わりランキング | 4型のスコア順位 |
| 季節傾向 | 各型×4季節の注意点 |

### 1-C. 相性マトリクス（能見正比古『血液型人間学』準拠）

```
           A型       B型       O型       AB型
A型     ★★★☆☆    ★★☆☆☆    ★★★★☆    ★★★★☆
B型     ★★☆☆☆    ★★★☆☆    ★★★★★    ★★★★☆
O型     ★★★★☆    ★★★★★    ★★★☆☆    ★★☆☆☆
AB型    ★★★★☆    ★★★★☆    ★★☆☆☆    ★★★☆☆
```

各組に個別の解説文（一般相性用＋恋愛相性用の2種）。

### 1-D. 恋愛相性サブスコア（16組×4カテゴリ=64データ）

- コミュニケーション: 会話スタイルの相性
- 価値観の一致: 人生観・生活観の近さ
- 情熱度: 恋愛における熱量の相性
- 長期安定度: 長期交際・結婚の安定性

### 1-E. 日替わり運勢 — 実在占術の複合判定

擬似ランダムではなく、アプリ内の実在占術エンジンを組み合わせる:

```
今日の血液型運勢 = 血液型の性格特性
                 × 六曜（今日の吉凶・時間帯）
                 × 九星日命星（今日のエネルギー・方位）
                 × 二十四節気（季節のフェーズ）
                 × 数秘ユニバーサルデイ（今日の数字の意味）
```

全て `Date()` から実データを取得。明日になれば全値が変わる。

**算出ロジック:**
- 六曜の吉凶スコア(1-5) × 血液型との相性係数
- 九星日命星の五行 × 血液型の性格特性との相生/相剋判定
- 二十四節気のエネルギー × 血液型の季節傾向
- 数秘ユニバーサルデイの意味 × 血液型の特性
- 4カテゴリ（総合・恋愛・仕事・金運）それぞれにスコア(1-5)を算出

**ランキング:** 4型それぞれの総合スコアを比較し順位付け。

---

## 2. UIフロー

### フロー図

```
血液型カードタップ
    ↓
BloodTypeModePickerView（4モード選択: 2×2グリッド）
    ↓ モード選択
┌──────────────────────────────────────────────┐
│ 今日の運勢  → ヒアリング(2回) → RevealView → AI鑑定 │
│ 相性診断    → 相手の型4択 → ヒアリング(1回) → Reveal → AI │
│ 恋愛相性    → 相手の型4択 → ヒアリング(1回) → Reveal → AI │
│ ランキング  → RevealView（即時・ヒアリングなし）→ AI鑑定 │
└──────────────────────────────────────────────┘
```

### ReadingViewModel 変更

```swift
@Published var selectedBloodTypeMode: BloodTypeMode?
@Published var partnerBloodType: BloodType?
@Published var showBloodTypeModePicker: Bool = false
@Published var showBloodTypeReveal: Bool = false
```

### ReadingScreen 表示条件

```swift
if showBloodTypeModePicker {
    BloodTypeModePickerView(...)
} else if showBloodTypeReveal {
    BloodTypeRevealView(...)
} else if showTarotReveal {
    TarotRevealView(...)
} else ...
```

### 相手の型選択UI

相性診断・恋愛相性モードでは、チャット内に4つの血液型ボタンをインラインで表示。テキスト入力ではなくタップで選択。

---

## 3. BloodTypeRevealView — モード別演出

### 共通ビジュアル基盤

- 背景: Color.black + 紫RadialGradient(hue 0.72-0.75) + パーティクル(15-20粒)
- フォント: SorayomiTheme .fortuneHeading(28pt serif), .fortuneBody
- 色: Fortune Gradient(朱→藍) + Secondary(金)アクセント
- 触覚: .heavy(結果表示), .medium(UI操作)
- アニメーション: .spring(response: 0.7, dampingFraction: 0.65)

### モード① 今日の運勢

1. 0.0s — 背景フェードイン + パーティクル
2. 0.3s — 血液型アイコンが rotation3DEffect Y軸回転で出現
3. 0.8s — タイトルテキスト フェードイン + slideUp
4. 1.2s〜2.4s — 4カテゴリのバーが左→右にアニメーション、★が1つずつ点灯(0.4s間隔)
5. 3.0s — ラッキー情報フェードイン
6. 3.5s — 「鑑定結果を見る」ボタン出現(gold glow + pulse)

### モード② 相性診断

1. 0.0s — 背景 + パーティクル
2. 0.3s — 自分の型が左からスライドイン
3. 0.6s — 相手の型が右からスライドイン
4. 1.0s — 2つが中央に近づく + 光のパーティクル発生
5. 1.5s — 円形相性メーターが出現、リングが0%→実スコアまでアニメーション(Fortune Gradient)
6. 2.2s — ★が1つずつ点灯
7. 2.8s — 一言相性テキスト フェードイン(fortuneBody serif)
8. 3.3s — ボタン出現

### モード③ 恋愛相性

1. 0.0s — ピンク〜紫RadialGradient + ハート型パーティクル浮遊
2. 0.5s — 2つの型が合体 → 中央にハート脈動(scaleEffect + opacity pulsing)
3. 1.0s — タイトルテキスト
4. 1.4s〜2.6s — 4サブカテゴリが上から順にスライドイン(0.3s間隔)
5. 3.2s — ボタン出現

### モード④ ランキング（4位→1位の逆順発表）

1. 0.0s — 背景 + タイトル + トロフィーアイコン
2. 0.8s — 4位がスライドイン（控えめ）
3. 1.5s — 3位がスライドイン（銅glow + 触覚medium）
4. 2.2s — 2位がスライドイン（銀glow + 触覚medium）
5. 3.0s — 1位がスケールバウンスで出現（金glow + 触覚heavy + パーティクル発射）
6. 3.8s — ユーザーの型にハイライト
7. 4.3s — ボタン出現

---

## 4. プロンプト & AI連携

### BloodTypePrompt 強化

```swift
BloodTypePrompt.build(
    profile: UserProfile?,
    category: ReadingCategory,
    mode: BloodTypeMode,
    partnerBloodType: BloodType?,
    dailyContext: BloodTypeDailyContext?  // 六曜・日命星・節気・数秘の複合データ
) -> String
```

### モード別プロンプト出力

各モードで異なるコンテキストブロックをAIに渡す:

- **今日の運勢:** 詳細プロファイル + 今日のバイオリズム(実在占術複合) + 暦データ + 季節傾向
- **相性診断:** 両者のプロファイル + 相性マトリクスデータ + 関係の特徴 + うまくいくコツ
- **恋愛相性:** 上記 + 4サブスコア(コミュニケーション/価値観/情熱度/安定度) + 恋愛特化解説
- **ランキング:** 4型の順位 + ユーザーの型の詳細 + 1位の型との関係

### SystemPromptBuilder モード別指示

- 今日の運勢: バイオリズム数値を裏付けとして織り込み、タイムライン提案
- 相性診断: 違いを「化学反応」として描く、3つの具体的アクション提案
- 恋愛相性: 4サブスコアに順に触れ物語的に語る、次の一歩を明確に
- ランキング: エンタメ感＋深みある助言、順位の理由と運を良くする具体策

### クレジットコスト

全モード1 credit（FortuneSystem.bloodType の既存コスト維持）。

---

## 5. 新規ファイル一覧

| ファイル | 種別 | 内容 |
|---------|------|------|
| `BloodTypeMode.swift` | Model | 4モードenum + 表示名・アイコン |
| `BloodTypeDailyContext.swift` | Model | 複合占術データ構造体 |
| `BloodTypeCompatibility.swift` | Model | 16組相性マトリクス + 恋愛サブスコア |
| `BloodTypeModePickerView.swift` | UI | モード選択画面(2×2グリッド) |
| `BloodTypeRevealView.swift` | UI | モード別演出画面(4パターン) |
| `BloodTypePartnerPickerView.swift` | UI | チャット内の相手型選択ボタン |

### 変更ファイル一覧

| ファイル | 変更内容 |
|---------|---------|
| `BloodTypeCalculator.swift` | 詳細プロファイル・相性マトリクス・日替わり複合判定・ランキング追加 |
| `BloodType.swift` | 詳細プロパティ追加（恋愛傾向・仕事傾向等） |
| `ReadingViewModel.swift` | BloodTypeMode状態管理・モード別フロー分岐 |
| `ReadingScreen.swift` | 表示条件分岐追加（ModePicker・RevealView） |
| `BloodTypePrompt.swift` | モード別プロンプト生成 |
| `SystemPromptBuilder.swift` | 血液型モード別指示追加 |
| `PromptTemplateEngine.swift` | BloodTypeMode パラメータ伝播 |
