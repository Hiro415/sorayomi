import SwiftUI

// MARK: - AdaptiveGrid

/// デバイスサイズに応じて列数を自動調整する `LazyVGrid` ラッパー。
///
/// Usage:
/// ```swift
/// AdaptiveGrid(compactColumns: 2, regularColumns: 3, spacing: Spacing.sm) {
///     ForEach(items) { item in
///         ItemCard(item: item)
///     }
/// }
/// ```
struct AdaptiveGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    let compactColumns: Int
    let regularColumns: Int
    let spacing: CGFloat
    let content: () -> Content

    init(
        compactColumns: Int = 2,
        regularColumns: Int = 3,
        spacing: CGFloat = SorayomiSpacing.sm,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.compactColumns = compactColumns
        self.regularColumns = regularColumns
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: spacing) {
            content()
        }
    }

    private var gridColumns: [GridItem] {
        let count = sizeClass == .regular ? regularColumns : compactColumns
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }
}

// MARK: - Preview

#Preview {
    AdaptiveGrid(compactColumns: 2, regularColumns: 3) {
        ForEach(0..<6) { i in
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.2))
                .frame(height: 100)
                .overlay(Text("\(i)"))
        }
    }
    .padding()
}
